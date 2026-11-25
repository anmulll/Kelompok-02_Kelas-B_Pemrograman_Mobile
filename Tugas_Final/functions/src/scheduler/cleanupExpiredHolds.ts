import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";

/**
 * CM-ARCH-DB-001 Bab 5 (`cleanupExpiredHolds`) & FR-017:
 * Melepaskan slot `held` yang sudah kedaluwarsa apabila belum ada pembayaran sukses.
 */
export const cleanupExpiredHolds = onSchedule("every 5 minutes", async () => {
  const db = admin.firestore();
  const nowTs = admin.firestore.Timestamp.now();

  const expiredSlots = await db
    .collection("slots")
    .where("status", "==", "held")
    .where("holdExpiresAt", "<=", nowTs)
    .limit(100)
    .get();

  if (expiredSlots.empty) return;

  let releasedCount = 0;

  for (const slotDoc of expiredSlots.docs) {
    await db.runTransaction(async (tx) => {
      const freshSlot = await tx.get(slotDoc.ref);
      const slot = freshSlot.data();
      if (!slot || slot.status !== "held") return;

      const holdExpiresAtMs = slot.holdExpiresAt?.toMillis?.() ?? 0;
      if (holdExpiresAtMs > Date.now()) return;

      const bookingId = slot.bookingId as string | null;
      if (bookingId) {
        const bookingRef = db.collection("bookings").doc(bookingId);
        const bookingSnap = await tx.get(bookingRef);
        if (bookingSnap.exists && bookingSnap.data()?.bookingStatus === "confirmed") {
          tx.update(slotDoc.ref, { status: "booked", holdExpiresAt: null, updatedAt: nowTs });
          return;
        }
        if (bookingSnap.exists && bookingSnap.data()?.bookingStatus === "pending_payment") {
          tx.update(bookingRef, { bookingStatus: "expired", updatedAt: nowTs });
        }
      }

      tx.update(slotDoc.ref, {
        status: "available",
        bookingId: null,
        holdExpiresAt: null,
        updatedAt: nowTs,
      });
      releasedCount += 1;
    });
  }

  logger.info("cleanupExpiredHolds selesai", { releasedCount });
});
