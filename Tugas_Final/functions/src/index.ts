import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export { createBooking } from "./booking/create-booking";
export { cancelBooking } from "./booking/cancel-booking";
export { createDokuPayment } from "./doku/create-payment";
export { dokuWebhook } from "./doku/webhook";
export { reconcilePayment } from "./doku/reconcile-payment";
export { manageCourt } from "./courts/manageCourt";
export { cleanupExpiredHolds } from "./scheduler/cleanup-expired-holds";
