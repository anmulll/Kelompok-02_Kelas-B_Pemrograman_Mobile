import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

export { createBooking } from "./booking/createBooking";
export { cancelBooking } from "./booking/cancelBooking";
export { createDokuPayment } from "./payment/createDokuPayment";
export { dokuWebhook } from "./doku/dokuWebhook";
export { manageCourt } from "./courts/manageCourt";
export { cleanupExpiredHolds } from "./scheduler/cleanupExpiredHolds";
