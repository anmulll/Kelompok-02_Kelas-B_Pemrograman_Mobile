import { HttpsError, onCall } from "firebase-functions/v2/https";
import { BackendStore, BookingStatus, FirestoreBackendStore } from "../shared/store";

export const DEFAULT_HOLD_DURATION_MS = 10 * 60 * 1000; // Baseline 10 menit (Bab 10)

export interface CreateBookingInput {
  uid: string;
  courtId?: string;
  slotId?: string;
  idempotencyKey?: string;
}

export interface CreateBookingOutput {
  bookingId: string;
  bookingStatus: BookingStatus;
  holdExpiresAt: string | null;
  amount: number;
  currency: string;
  idempotentReplay?: boolean;
}

/**
 * Modul Anmul A-02, A-03, A-08:
 * - Memvalidasi status pengguna, lapangan terverifikasi, dan ketersediaan slot.
 * - Mengabaikan segala input nominal/harga dari klien (AT-04).
 * - Mengunci slot (`held`) secara atomik di dalam transaksi Firestore (AT-01..AT-03).
 */
export async function executeCreateBooking(
  store: BackendStore,
  input: CreateBookingInput,
  nowMs: number = Date.now(),
  holdDurationMs: number = DEFAULT_HOLD_DURATION_MS
): Promise<CreateBookingOutput> {
  const { uid, courtId, slotId, idempotencyKey } = input;

  if (!uid) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }

  const trimmedCourtId = String(courtId ?? "").trim();
  const trimmedSlotId = String(slotId ?? "").trim();
  const trimmedKey = String(idempotencyKey ?? "").trim().replace(/[^a-zA-Z0-9_-]/g, "");

  if (!trimmedCourtId || !trimmedSlotId || !trimmedKey) {
    throw new HttpsError(
      "invalid-argument",
      "Parameter courtId, slotId, dan idempotencyKey wajib diisi dengan format valid."
    );
  }

  const bookingId = `${uid}_${trimmedKey}`;

  return store.runTransaction(async (tx) => {
    const user = await tx.getUser(uid);
    if (user && !user.isActive) {
      throw new HttpsError("permission-denied", "Akun pengguna sedang dinonaktifkan.");
    }

    // A-08: Idempotent request replay
    const existingBooking = await tx.getBooking(bookingId);
    if (existingBooking) {
      const linkedSlot = await tx.getSlot(existingBooking.slotId);
      const holdIso =
        linkedSlot && linkedSlot.bookingId === bookingId && linkedSlot.holdExpiresAtMs
          ? new Date(linkedSlot.holdExpiresAtMs).toISOString()
          : null;
      return {
        bookingId: existingBooking.id,
        bookingStatus: existingBooking.bookingStatus,
        holdExpiresAt: holdIso,
        amount: existingBooking.amount,
        currency: existingBooking.currency,
        idempotentReplay: true,
      };
    }

    const [court, slot] = await Promise.all([
      tx.getCourt(trimmedCourtId),
      tx.getSlot(trimmedSlotId),
    ]);

    if (!court) {
      throw new HttpsError("not-found", "Lapangan tidak ditemukan.");
    }
    if (!court.isActive || court.verificationStatus !== "verified") {
      throw new HttpsError(
        "failed-precondition",
        "Lapangan belum aktif atau belum terverifikasi untuk reservasi."
      );
    }

    if (!slot) {
      throw new HttpsError("not-found", "Slot jadwal tidak ditemukan.");
    }
    if (slot.courtId !== trimmedCourtId) {
      throw new HttpsError("invalid-argument", "Slot tidak terdaftar pada lapangan tersebut.");
    }
    if (slot.endAtMs <= nowMs) {
      throw new HttpsError("failed-precondition", "Slot waktu sudah terlewat.");
    }

    const isExpiredHold =
      slot.status === "held" &&
      slot.holdExpiresAtMs !== null &&
      slot.holdExpiresAtMs <= nowMs;

    const canAcquireHold = slot.status === "available" || isExpiredHold;
    if (!canAcquireHold) {
      throw new HttpsError(
        "already-exists",
        "Slot sedang ditahan pengguna lain atau sudah dipesan."
      );
    }

    // Jika mengambil alih hold yang sudah kedaluwarsa, tandai booking lama sebagai expired
    if (isExpiredHold && slot.bookingId && slot.bookingId !== bookingId) {
      const staleBooking = await tx.getBooking(slot.bookingId);
      if (staleBooking && staleBooking.bookingStatus === "pending_payment") {
        tx.saveBooking({
          ...staleBooking,
          bookingStatus: "expired",
          updatedAtMs: nowMs,
        });
      }
    }

    if (!Number.isInteger(slot.price) || slot.price <= 0) {
      throw new HttpsError("failed-precondition", "Harga slot pada server belum valid.");
    }

    const holdExpiresAtMs = nowMs + holdDurationMs;
    const currency = slot.currency || "IDR";

    tx.saveSlot({
      ...slot,
      status: "held",
      bookingId,
      holdExpiresAtMs,
      updatedAtMs: nowMs,
    });

    tx.saveBooking({
      id: bookingId,
      userId: uid,
      courtId: trimmedCourtId,
      slotId: trimmedSlotId,
      startAtMs: slot.startAtMs,
      endAtMs: slot.endAtMs,
      amount: slot.price,
      currency,
      bookingStatus: "pending_payment",
      paymentId: null,
      idempotencyKey: trimmedKey,
      createdAtMs: nowMs,
      updatedAtMs: nowMs,
      confirmedAtMs: null,
    });

    return {
      bookingId,
      bookingStatus: "pending_payment",
      holdExpiresAt: new Date(holdExpiresAtMs).toISOString(),
      amount: slot.price,
      currency,
    };
  });
}

export const createBooking = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }
  const store = new FirestoreBackendStore();
  return executeCreateBooking(store, {
    uid: request.auth.uid,
    courtId: request.data?.courtId,
    slotId: request.data?.slotId,
    idempotencyKey: request.data?.idempotencyKey,
  });
});
