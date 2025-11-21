import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const rtdb = admin.database();
const db = admin.firestore();

// ------------ Types ------------
const USER_COLLECTION = "users"; // adjust if your profiles live elsewhere

type NullableNumber = number | null;

export interface Order {
  userId?: string;
  address?: string;
  createdAt?: admin.firestore.Timestamp;
  timestamp?: admin.firestore.Timestamp;  // Added for compatibility with Flutter app
  status?: string;
  lat?: NullableNumber;
  lng?: NullableNumber;
}

export interface UserProfile {
  address?: string;
  lat?: NullableNumber;
  lng?: NullableNumber;
}

export interface QueueItem {
  restaurantId: string;
  orderId: string;
  address: string;
  createdAtMs: number;
  priority: number;            // lower = higher priority
  status: string;
  lat: NullableNumber;
  lng: NullableNumber;
}

export interface RobotLocation {
  lat: number;
  lng: number;
  updatedAt?: number;
}

const ELIGIBLE = new Set(["pending", "completed", "ready", "en route"]);
const TERMINAL = new Set(["delivered", "canceled"]);

// ---- Heuristics for distance-aware priority ----
const AVG_SPEED_M_PER_MIN = 200; // ~12 km/h, tune to your robot

function haversineMeters(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number }
): number {
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
}): number {
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

// Build the queue representation of an order (for initial insert).
function buildQueueItem(
  restaurantId: string,
  orderId: string,
  data: Order
): QueueItem {
  // Support both 'timestamp' (from Flutter) and 'createdAt' (legacy)
  const createdAtMs = (data.timestamp?.toMillis() ?? data.createdAt?.toMillis()) ?? Date.now();
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

/** Only the mutable fields we want to keep updating on order changes */
function buildQueueUpdateFromOrder(after: Order): Partial<QueueItem> {
  // Support both 'timestamp' (from Flutter) and 'createdAt' (legacy)
  const createdAtMs = after.timestamp?.toMillis() ?? after.createdAt?.toMillis();
  const partial: Partial<QueueItem> = {
    status: after.status ?? "pending",
  };
  if (typeof createdAtMs === "number") {
    partial.createdAtMs = createdAtMs;
  }
  // Intentionally DO NOT touch address/lat/lng here to avoid retroactive rewrites
  return partial;
}

async function fetchUserProfile(userId: string): Promise<UserProfile | null> {
  try {
    const snap = await db.collection(USER_COLLECTION).doc(userId).get();
    if (!snap.exists) return null;
    const data = snap.data() as UserProfile;
    return {
      address: data?.address ?? "",
      lat: data?.lat ?? null,
      lng: data?.lng ?? null,
    };
  } catch {
    return null;
  }
}

// ----------------- Firestore triggers: keep /queue in sync -----------------

// When a new order is created: read CURRENT user profile address and stamp it.
export const onOrderCreate = functions.firestore.onDocumentCreated(
  "restaurants/{restaurantId}/orders/{orderId}",
  async (event) => {
    if (!event.data) return; // avoid non-null assertion
    const snapshot = event.data;
    const data = snapshot.data() as Order | undefined;
    if (!data) return;

    const { restaurantId, orderId } = event.params;

    // Skip if not in an eligible state
    const status = data.status ?? "pending";
    if (!ELIGIBLE.has(status)) return;

    // Load the user's CURRENT profile address at order time
    const stamped: Order = { ...data };
    if (data.userId) {
      const profile = await fetchUserProfile(data.userId);
      if (profile) {
        stamped.address = profile.address ?? "";
        stamped.lat = profile.lat ?? null;
        stamped.lng = profile.lng ?? null;
      }
    }

    // 1) Persist the stamped address onto the order document (server-truth for this order)
    // 2) Write to the RTDB queue from the stamped values
    const orderRef = snapshot.ref;
    await db.runTransaction(async (tx) => {
      tx.update(orderRef, {
        address: stamped.address ?? "",
        lat: stamped.lat ?? null,
        lng: stamped.lng ?? null,
      });
    });

    await rtdb.ref(`/queue/${orderId}`).set(buildQueueItem(restaurantId, orderId, stamped));
  }
);

// When an order changes: remove from queue on terminal, update limited fields on eligible, else remove.
export const onOrderUpdate = functions.firestore.onDocumentWritten(
  "restaurants/{restaurantId}/orders/{orderId}",
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap?.exists) return;

    const after = afterSnap.data() as Order | undefined;
    if (!after) return;

    const { orderId } = event.params;

    if (TERMINAL.has(after.status ?? "")) {
      const deletes: Record<string, null> = {
        [`/queue/${orderId}`]: null,
        [`/active/${orderId}`]: null,
      };
      await rtdb.ref().update(deletes);
      return;
    }

    if (ELIGIBLE.has(after.status ?? "pending")) {
      // Only update mutable queue fields; do NOT rewrite address/lat/lng here
      const update = buildQueueUpdateFromOrder(after);
      await rtdb.ref(`/queue/${orderId}`).update(update);
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
    const pos = event.data?.after.val() as RobotLocation | null;
    if (!pos || pos.lat == null || pos.lng == null) return;

    const robotLat = Number(pos.lat);
    const robotLng = Number(pos.lng);

    // read all queue entries
    const snap = await rtdb.ref("/queue").get();
    if (!snap.exists()) return;

    // RTDB multi-path update where each value is a number
    const updates: Record<string, number> = {};

    snap.forEach((child) => {
      type ChildItem = {
        createdAtMs?: number;
        lat?: number | null;
        lng?: number | null;
      };

      const item = child.val() as ChildItem;
      const createdAtMs = typeof item?.createdAtMs === "number" ? item.createdAtMs : undefined;
      const latOk = typeof item?.lat === "number";
      const lngOk = typeof item?.lng === "number";

      if (createdAtMs == null || !latOk || !lngOk) {
        // missing data; keep FIFO priority
        return;
      }

      const priority = scoreOrder({
        createdAtMs,
        orderLat: item.lat as number,
        orderLng: item.lng as number,
        robotLat,
        robotLng,
        wt: 1.0,
        wd: 2.0,
      });

      if (child.key) {
        updates[`/queue/${child.key}/priority`] = priority;
      }
    });

    const hasUpdates = Object.keys(updates).length > 0;
    if (hasUpdates) {
      await rtdb.ref().update(updates);
    }
  }
);

// -------- RTDB to Firestore sync triggers --------

/**
 * Syncs status changes from RTDB queue back to Firestore orders.
 * When status changes in /queue/{orderId}, update the corresponding Firestore order document.
 */
export const onQueueStatusChange = functions.database.onValueWritten(
  "/queue/{orderId}",
  async (event) => {
    const orderId = event.params.orderId;
    const afterData = event.data?.after.val() as QueueItem | null;
    
    // If the queue item was deleted, don't update Firestore
    // (the onOrderUpdate function already handles terminal states)
    if (!afterData) {
      return;
    }

    const newStatus = afterData.status;
    const restaurantId = afterData.restaurantId;

    if (!newStatus || !restaurantId) {
      console.warn(`Missing status or restaurantId for order ${orderId}`);
      return;
    }

    try {
      // Update the Firestore order document with the new status
      const orderRef = db
        .collection("restaurants")
        .doc(restaurantId)
        .collection("orders")
        .doc(orderId);

      const orderDoc = await orderRef.get();
      
      // Only update if the document exists and status is different
      if (orderDoc.exists) {
        const currentData = orderDoc.data() as Order;
        if (currentData.status !== newStatus) {
          await orderRef.update({
            status: newStatus,
          });
          console.log(`Updated order ${orderId} status to ${newStatus}`);
        }
      }
    } catch (error) {
      console.error(`Error updating Firestore for order ${orderId}:`, error);
    }
  }
);

/**
 * Syncs status changes from RTDB /active path back to Firestore.
 * This handles cases where the robot updates status in /active.
 */
export const onActiveStatusChange = functions.database.onValueWritten(
  "/active/{orderId}",
  async (event) => {
    const orderId = event.params.orderId;
    const afterData = event.data?.after.val() as QueueItem | null;
    
    // If the active item was deleted, don't update Firestore
    if (!afterData) {
      return;
    }

    const newStatus = afterData.status;
    const restaurantId = afterData.restaurantId;

    if (!newStatus || !restaurantId) {
      console.warn(`Missing status or restaurantId for active order ${orderId}`);
      return;
    }

    try {
      // Update the Firestore order document with the new status
      const orderRef = db
        .collection("restaurants")
        .doc(restaurantId)
        .collection("orders")
        .doc(orderId);

      const orderDoc = await orderRef.get();
      
      // Only update if the document exists and status is different
      if (orderDoc.exists) {
        const currentData = orderDoc.data() as Order;
        if (currentData.status !== newStatus) {
          await orderRef.update({
            status: newStatus,
          });
          console.log(`Updated active order ${orderId} status to ${newStatus}`);
        }
      }
    } catch (error) {
      console.error(`Error updating Firestore for active order ${orderId}:`, error);
    }
  }
);