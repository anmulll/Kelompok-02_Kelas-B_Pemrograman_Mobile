import { HttpsError, onCall } from "firebase-functions/v2/https";
import { BackendStore, FirestoreBackendStore } from "../shared/store";

export interface CancelBookingInput {
  uid: string;
  bookingId?: string;
  reason?: string;
}

export interface CancelBookingOutput {
  bookingId: string;
  bookingStatus: "cancelled";
  refundStatus: string | null;
}

/**
 * Modul Anmul A-09 & A-10:
 * - Pembatalan booking milik pengguna sendiri.
 * - Jika `pending_payment`: batalkan booking & payment pending, lepaskan slot menjadi `available`.
 * - Jika `confirmed` (sebelum jadwal mulai): batalkan booking, lepaskan slot, dan tandai
 *   `manual_review_required` karena refund otomatis berada di luar MVP.
 */
export async function executeCancelBooking(
  store: BackendStore,
  input: CancelBookingInput,
  nowMs: number = Date.now()
): Promise<CancelBookingOutput> {
  if (!input.uid) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }

  const bookingId = String(input.bookingId ?? "").trim();
  if (!bookingId) {
    throw new HttpsError("invalid-argument", "bookingId wajib diisi.");
  }

  const reason = input.reason ? String(input.reason).trim() : null;

  return store.runTransaction(async (tx) => {
    const booking = await tx.getBooking(bookingId);
    if (!booking) {
      throw new HttpsError("not-found", "Data booking tidak ditemukan.");
    }

    if (booking.userId !== input.uid) {
      throw new HttpsError("permission-denied", "Anda tidak berhak membatalkan booking ini.");
    }

    if (
      booking.bookingStatus !== "pending_payment" &&
      booking.bookingStatus !== "confirmed"
    ) {
      throw new HttpsError(
        "failed-precondition",
        `Booking dengan status '${booking.bookingStatus}' tidak dapat dibatalkan.`
      );
    }

    if (booking.bookingStatus === "confirmed" && booking.startAtMs <= nowMs) {
      throw new HttpsError(
        "failed-precondition",
        "Booking yang jadwalnya sudah dimulai atau selesai tidak dapat dibatalkan."
      );
    }

    const slot = await tx.getSlot(booking.slotId);
    const payment = booking.paymentId ? await tx.getPayment(booking.paymentId) : null;

    const refundStatus =
      booking.bookingStatus === "confirmed" ? "manual_review_required" : null;

    tx.saveBooking({
      ...booking,
      bookingStatus: "cancelled",
      cancelReason: reason,
      refundStatus,
      updatedAtMs: nowMs,
    });

    if (payment && (payment.paymentStatus === "pending" || payment.paymentStatus === "created")) {
      tx.savePayment({
        ...payment,
        paymentStatus: "cancelled",
        updatedAtMs: nowMs,
      });
    }

    if (slot && slot.bookingId === bookingId) {
      tx.saveSlot({
        ...slot,
        status: "available",
        bookingId: null,
        holdExpiresAtMs: null,
        updatedAtMs: nowMs,
      });
    }

    tx.createNotification({
      userId: booking.userId,
      title: "Reservasi Dibatalkan",
      body:
        refundStatus === "manual_review_required"
          ? "Reservasi terkonfirmasi Anda telah dibatalkan. Pengembalian dana mengikuti prosedur manual pengelola."
          : "Reservasi Anda telah dibatalkan dan slot telah dilepas.",
      type: "booking_cancelled",
      isRead: false,
      createdAtMs: nowMs,
      relatedId: bookingId,
    });

    return {
      bookingId,
      bookingStatus: "cancelled",
      refundStatus,
    };
  });
}

export const cancelBooking = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }
  const store = new FirestoreBackendStore();
  return executeCancelBooking(store, {
    uid: request.auth.uid,
    bookingId: request.data?.bookingId,
    reason: request.data?.reason,
  });
});
