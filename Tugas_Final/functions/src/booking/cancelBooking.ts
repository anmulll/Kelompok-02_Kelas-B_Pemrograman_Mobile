import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

interface CancelBookingRequest {
  bookingId?: string;
  reason?: string;
}

/**
 * CM-ARCH-DB-001 Bab 5 & FR-019: Pembatalan booking sesuai kepemilikan dan status.
 */
export const cancelBooking = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }

  const uid = request.auth.uid;
  const { bookingId, reason } = (request.data ?? {}) as CancelBookingRequest;
  if (!bookingId) {
    throw new HttpsError("invalid-argument", "bookingId wajib diisi.");
  }

  const db = admin.firestore();
  const bookingRef = db.collection("bookings").doc(bookingId);

  return db.runTransaction(async (tx) => {
    const bookingSnap = await tx.get(bookingRef);
    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Data booking tidak ditemukan.");
    }

    const booking = bookingSnap.data()!;
    if (booking.userId !== uid) {
      throw new HttpsError("permission-denied", "Anda tidak berhak membatalkan booking ini.");
    }

    if (booking.bookingStatus !== "pending_payment") {
      throw new HttpsError(
        "failed-precondition",
        "Hanya booking berstatus menunggu pembayaran yang dapat dibatalkan langsung di MVP."
      );
    }

    const slotRef = db.collection("slots").doc(String(booking.slotId));
    const slotSnap = await tx.get(slotRef);
    const nowTs = admin.firestore.Timestamp.now();

    tx.update(bookingRef, {
      bookingStatus: "cancelled",
      cancelReason: reason ?? null,
      updatedAt: nowTs,
    });

    if (slotSnap.exists && slotSnap.data()?.bookingId === bookingId) {
      tx.update(slotRef, {
        status: "available",
        bookingId: null,
        holdExpiresAt: null,
        updatedAt: nowTs,
      });
    }

    return { bookingId, bookingStatus: "cancelled" };
  });
});
