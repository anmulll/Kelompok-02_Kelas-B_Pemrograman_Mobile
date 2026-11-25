import * as admin from "firebase-admin";
import { HttpsError, onCall } from "firebase-functions/v2/https";

const HOLD_DURATION_MS = 10 * 60 * 1000; // Baseline 10 menit (BR-005)

interface CreateBookingRequest {
  courtId?: string;
  slotId?: string;
  idempotencyKey?: string;
}

/**
 * CM-ARCH-DB-001 Bab 6.1: Pembuatan hold dan booking secara atomik.
 * - Harga diambil murni dari dokumen `slots`, bukan dari payload klien (BR-006).
 * - Mencegah pemesanan ganda melalui Firestore Transaction (FR-010, AC-04).
 */
export const createBooking = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }

  const uid = request.auth.uid;
  const { courtId, slotId, idempotencyKey } = (request.data ?? {}) as CreateBookingRequest;

  if (!courtId || !slotId || !idempotencyKey) {
    throw new HttpsError(
      "invalid-argument",
      "Parameter courtId, slotId, dan idempotencyKey wajib diisi."
    );
  }

  const db = admin.firestore();
  const courtRef = db.collection("courts").doc(courtId);
  const slotRef = db.collection("slots").doc(slotId);
  const bookingId = `${uid}_${idempotencyKey}`;
  const bookingRef = db.collection("bookings").doc(bookingId);

  return db.runTransaction(async (tx) => {
    const existingBooking = await tx.get(bookingRef);
    if (existingBooking.exists) {
      return {
        bookingId: existingBooking.id,
        status: existingBooking.data()?.bookingStatus ?? "pending_payment",
        idempotentReplay: true,
      };
    }

    const [courtSnap, slotSnap] = await Promise.all([
      tx.get(courtRef),
      tx.get(slotRef),
    ]);

    if (!courtSnap.exists) {
      throw new HttpsError("not-found", "Lapangan tidak ditemukan.");
    }
    const court = courtSnap.data()!;
    if (!court.isActive || court.verificationStatus !== "verified") {
      throw new HttpsError("failed-precondition", "Lapangan belum aktif untuk reservasi.");
    }

    if (!slotSnap.exists) {
      throw new HttpsError("not-found", "Slot jadwal tidak ditemukan.");
    }
    const slot = slotSnap.data()!;
    if (slot.courtId !== courtId) {
      throw new HttpsError("invalid-argument", "Slot tidak sesuai dengan lapangan.");
    }

    const nowMs = Date.now();
    const holdExpiresAtMs = slot.holdExpiresAt?.toMillis?.() ?? 0;
    const isAvailable =
      slot.status === "available" ||
      (slot.status === "held" && holdExpiresAtMs > 0 && holdExpiresAtMs < nowMs);

    if (!isAvailable) {
      throw new HttpsError("already-exists", "Slot sedang ditahan atau sudah dipesan.");
    }

    const nowTs = admin.firestore.Timestamp.fromMillis(nowMs);
    const newHoldExpiresAt = admin.firestore.Timestamp.fromMillis(nowMs + HOLD_DURATION_MS);
    const amount = Number(slot.price);
    const currency = String(slot.currency ?? "IDR");

    tx.update(slotRef, {
      status: "held",
      bookingId: bookingRef.id,
      holdExpiresAt: newHoldExpiresAt,
      updatedAt: nowTs,
    });

    tx.set(bookingRef, {
      userId: uid,
      courtId,
      slotId,
      startAt: slot.startAt,
      endAt: slot.endAt,
      amount,
      currency,
      bookingStatus: "pending_payment",
      paymentId: null,
      idempotencyKey,
      createdAt: nowTs,
      updatedAt: nowTs,
      confirmedAt: null,
    });

    return {
      bookingId: bookingRef.id,
      amount,
      currency,
      holdExpiresAt: newHoldExpiresAt.toDate().toISOString(),
    };
  });
});
