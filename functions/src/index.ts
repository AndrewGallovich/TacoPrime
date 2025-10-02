import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const rtdb = admin.database();

type Order = {
  address?: string;
  createdAt?: admin.firestore.Timestamp;
  status?: string;
  lat?: number;   // <-- add coordinates on order docs
  lng?: number;
};

const ELIGIBLE = new Set(["pending", "prepping", "ready"]);
const TERMINAL = new Set(["delivered", "canceled"]);

// ---- Heuristics for distance-aware priority ----
const AVG_SPEED_M_PER_MIN = 200; // ~12 km/h campus robot; tune as needed

function haversineMeters(a: { lat: number; lng: number }, b: { lat: number; lng: number }) {
  const R = 6371000; // meters
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const la1 = toRad(a.lat);
  const la2 = toRad(b.lat);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(la1) * Math.cos(la2) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

/**
 * Compute a score (LOWER = higher priority) blending wait time and travel time.
 * wt: weight on waiting minutes; wd: weight on travel minutes.
 */
function scoreOrder(params: {
  createdAtMs: number;
  orderLat: number;
  orderLng: number;
  robotLat: number;
  robotLng: number;
  wt?: number;
  wd?: number;
}) {
  const wt = params.wt ?? 1.0;
  const wd = params.wd ?? 2.0;
  const now = Date.now();
  const waitingMin = Math.max(0, (now - params.createdAtMs) / 60000);
  const distM = haversineMeters(
    { lat: params.robotLat, lng: params.robotLng },
    { lat: params.orderLat, lng: params.orderLng }
  );
  const travelMin = distM / AVG_SPEED_M_PER_MIN;
  return wt * waitingMin + wd * travelMin;
}

// Build the queue representation of an order.
// Priority defaults to FIFO-by-time; distance-aware scoring is applied by onRobotMove.
function buildQueueItem(restaurantId: string, orderId: string, data: Order) {
  const createdAtMs = data.createdAt?.toMillis() ?? Date.now();
  return {
    restaurantId,
    orderId,
    address: data.address ?? "",
    createdAtMs,
    // default FIFO priority; onRobotMove will recompute using robot location
    priority: createdAtMs,
    status: data.status ?? "pending",
    lat: data.lat ?? null,
    lng: data.lng ?? null,
  };
}

// ----------------- Firestore triggers: keep /queue in sync -----------------

// When a new order is created: add/update in the RTDB queue if eligible.
export const onOrderCreate = functions.firestore.onDocumentCreated(
  "restaurants/{restaurantId}/orders/{orderId}",
  async (event) => {
    const data = event.data?.data() as Order;
    if (!data) return;

    const { restaurantId, orderId } = event.params;
    if (!ELIGIBLE.has(data.status ?? "pending")) return;

    await rtdb.ref(`/queue/${orderId}`).set(buildQueueItem(restaurantId, orderId, data));
  }
);

// When an order changes: remove from queue on terminal, update on eligible, else remove.
export const onOrderUpdate = functions.firestore.onDocumentWritten(
  "restaurants/{restaurantId}/orders/{orderId}",
  async (event) => {
    const after = event.data?.after.data() as Order | undefined;
    if (!after) return;

    const { restaurantId, orderId } = event.params;

    if (TERMINAL.has(after.status ?? "")) {
      await rtdb.ref().update({
        [`/queue/${orderId}`]: null,
        [`/active/${orderId}`]: null,
      });
      return;
    }

    if (ELIGIBLE.has(after.status ?? "pending")) {
      await rtdb.ref(`/queue/${orderId}`).update(buildQueueItem(restaurantId, orderId, after));
    } else {
      await rtdb.ref(`/queue/${orderId}`).remove();
    }
  }
);

// -------- RTDB trigger: recompute priorities when a robot moves --------

/**
 * Robot client should push its location to:
 *   /robot/{robotId}/location = { lat, lng, updatedAt }
 * Every time that changes, we recompute `priority` for all items in /queue that have lat/lng.
 * If an item lacks lat/lng, we leave its FIFO priority as-is.
 */
export const onRobotMove = functions.database.onValueWritten(
  "/robot/{robotId}/location",
  async (event) => {
    const pos = event.data?.after.val();
    if (!pos || pos.lat == null || pos.lng == null) return;

    const robotLat = Number(pos.lat);
    const robotLng = Number(pos.lng);

    // read all queue entries
    const snap = await rtdb.ref("/queue").get();
    if (!snap.exists()) return;

    const updates: Record<string, any> = {};
    snap.forEach((child) => {
      const item = child.val() as {
        createdAtMs?: number;
        lat?: number | null;
        lng?: number | null;
      };
      if (
        item?.createdAtMs == null ||
        item?.lat == null ||
        item?.lng == null
      ) {
        // missing data; keep FIFO priority
        return;
      }

      const priority = scoreOrder({
        createdAtMs: Number(item.createdAtMs),
        orderLat: Number(item.lat),
        orderLng: Number(item.lng),
        robotLat,
        robotLng,
        // tweak weights here if needed
        wt: 1.0,
        wd: 2.0,
      });

      updates[`/queue/${child.key}/priority`] = priority;
    });

    if (Object.keys(updates).length) {
      await rtdb.ref().update(updates);
    }
  }
);
