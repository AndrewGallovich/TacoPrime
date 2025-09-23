import * as functions from "firebase-functions/v2";
import * as admin from "firebase-admin";

admin.initializeApp();
const rtdb = admin.database();

type Order = {
  address?: string;
  createdAt?: admin.firestore.Timestamp;
  status?: string;
};

const ELIGIBLE = new Set(["pending", "prepping", "ready"]);
const TERMINAL = new Set(["delivered", "canceled"]);

function buildQueueItem(restaurantId: string, orderId: string, data: Order) {
  const createdAtMs = data.createdAt?.toMillis() ?? Date.now();
  return {
    restaurantId,
    orderId,
    address: data.address ?? "",
    createdAtMs,
    priority: createdAtMs,
    status: data.status ?? "pending",
  };
}

// Trigger when a new order is created
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

// Trigger when an order is updated
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
