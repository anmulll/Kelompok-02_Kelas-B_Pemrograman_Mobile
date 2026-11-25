import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { BackendStore, FirestoreBackendStore } from "../shared/store";

/**
 * Modul Anmul A-12 (`cleanup-expired-holds.ts`):
 * Melepaskan slot `held` yang sudah lewat `holdExpiresAt` secara aman
 * hanya jika belum ada pembayaran `paid` atau booking `confirmed`.
 */
export async function executeCleanupExpiredHolds(
  store: BackendStore,
  nowMs: number = Date.now(),
  batchLimit: number = 100
): Promise<{ releasedCount: number; promotedCount: number }> {
  const expiredSlotIds = await store.listExpiredHeldSlotIds(nowMs, batchLimit);
  let releasedCount = 0;
  let promotedCount = 0;

  for (const slotId of expiredSlotIds) {
    await store.runTransaction(async (tx) => {
      const slot = await tx.getSlot(slotId);
      if (!slot || slot.status !== "held") return;
      if (slot.holdExpiresAtMs === null || slot.holdExpiresAtMs > nowMs) return;

      if (slot.bookingId) {
        const booking = await tx.getBooking(slot.bookingId);
        const payment =
          booking && booking.paymentId
            ? await tx.getPayment(booking.paymentId)
            : null;

        // Pengaman: jangan melepas slot apabila pembayaran sudah lunas / confirmed
        if (
          booking?.bookingStatus === "confirmed" ||
          payment?.paymentStatus === "paid"
        ) {
          tx.saveSlot({
            ...slot,
            status: "booked",
            holdExpiresAtMs: null,
            updatedAtMs: nowMs,
          });
          if (booking && booking.bookingStatus !== "confirmed") {
            tx.saveBooking({
              ...booking,
              bookingStatus: "confirmed",
              confirmedAtMs: nowMs,
              updatedAtMs: nowMs,
            });
          }
          promotedCount += 1;
          return;
        }

        if (booking && booking.bookingStatus === "pending_payment") {
          tx.saveBooking({
            ...booking,
            bookingStatus: "expired",
            updatedAtMs: nowMs,
          });
        }

        if (
          payment &&
          (payment.paymentStatus === "pending" || payment.paymentStatus === "created")
        ) {
          tx.savePayment({
            ...payment,
            paymentStatus: "expired",
            updatedAtMs: nowMs,
          });
        }
      }

      tx.saveSlot({
        ...slot,
        status: "available",
        bookingId: null,
        holdExpiresAtMs: null,
        updatedAtMs: nowMs,
      });
      releasedCount += 1;
    });
  }

  return { releasedCount, promotedCount };
}

export const cleanupExpiredHolds = onSchedule("every 5 minutes", async () => {
  const store = new FirestoreBackendStore();
  const summary = await executeCleanupExpiredHolds(store);
  logger.info("cleanupExpiredHolds selesai dijalankan", summary);
});
