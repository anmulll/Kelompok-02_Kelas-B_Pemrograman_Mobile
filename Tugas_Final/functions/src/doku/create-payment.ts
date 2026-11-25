import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { BackendStore, FirestoreBackendStore } from "../shared/store";
import { generateDokuSignature } from "./signature";

const dokuClientId = defineSecret("DOKU_CLIENT_ID");
const dokuSecretKey = defineSecret("DOKU_SECRET_KEY");

export const DOKU_SANDBOX_BASE_URL = "https://api-sandbox.doku.com";
export const DOKU_CHECKOUT_PATH = "/checkout/v1/payment";

export interface DokuCheckoutRequestPayload {
  providerOrderId: string;
  amount: number;
  currency: string;
  paymentDueMinutes: number;
  customerId?: string;
  customerName?: string;
  customerEmail?: string;
  itemName?: string;
  callbackUrl?: string;
}

export interface DokuCheckoutGateway {
  createCheckoutSession(payload: DokuCheckoutRequestPayload): Promise<{ paymentUrl: string }>;
}

export function createHttpDokuGateway(
  clientId: string,
  secretKey: string,
  baseUrl: string = DOKU_SANDBOX_BASE_URL
): DokuCheckoutGateway {
  return {
    async createCheckoutSession(payload) {
      if (!clientId || !secretKey) {
        throw new HttpsError(
          "failed-precondition",
          "Kredensial DOKU Sandbox belum dikonfigurasi pada Secret Manager / .secret.local."
        );
      }

      const requestBody = JSON.stringify({
        order: {
          amount: payload.amount,
          invoice_number: payload.providerOrderId,
          currency: payload.currency,
          callback_url: payload.callbackUrl ?? "https://courtmate.id/payment-return",
          line_items: [
            {
              name: payload.itemName ?? "Reservasi Lapangan CourtMate",
              price: payload.amount,
              quantity: 1,
            },
          ],
        },
        payment: {
          payment_due_date: payload.paymentDueMinutes,
        },
        customer: {
          id: payload.customerId ?? "courtmate-user",
          name: payload.customerName ?? "Mahasiswa CourtMate",
          email: payload.customerEmail ?? "mahasiswa@courtmate.id",
        },
      });

      const requestId = crypto.randomUUID();
      const requestTimestamp = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
      const signature = generateDokuSignature({
        clientId,
        requestId,
        requestTimestamp,
        requestTarget: DOKU_CHECKOUT_PATH,
        rawBody: requestBody,
        secretKey,
      });

      const response = await fetch(`${baseUrl}${DOKU_CHECKOUT_PATH}`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Client-Id": clientId,
          "Request-Id": requestId,
          "Request-Timestamp": requestTimestamp,
          "Signature": signature,
        },
        body: requestBody,
      });

      const responseText = await response.text();
      if (!response.ok) {
        logger.error("DOKU Checkout API menolak permintaan", {
          status: response.status,
          providerOrderId: payload.providerOrderId,
          requestId,
          dokuResponse: responseText.slice(0, 500),
        });
        throw new HttpsError(
          "internal",
          `Gagal membuat sesi pembayaran DOKU Sandbox (HTTP ${response.status}).`
        );
      }

      const json = JSON.parse(responseText) as {
        response?: { payment?: { url?: string } };
      };
      const paymentUrl = json.response?.payment?.url;
      if (!paymentUrl) {
        throw new HttpsError("internal", "Respons DOKU tidak menyertakan payment URL.");
      }

      return { paymentUrl };
    },
  };
}

export interface CreateDokuPaymentInput {
  uid: string;
  bookingId?: string;
}

export interface CreateDokuPaymentOutput {
  paymentId: string;
  providerOrderId: string;
  paymentUrl: string;
  checkoutUrl: string;
  expiresAt: string;
}

/**
 * Modul Anmul A-04, A-05 & Bab 8:
 * - Memastikan booking milik pemanggil, berstatus `pending_payment`, dan hold slot masih aktif.
 * - Menyelaraskan masa berlaku invoice DOKU dengan sisa `holdExpiresAt` (Bab 10).
 * - Mengembalikan `paymentUrl` (dan `checkoutUrl`) tanpa pernah mengekspos Secret Key.
 */
export async function executeCreateDokuPayment(
  store: BackendStore,
  gateway: DokuCheckoutGateway,
  input: CreateDokuPaymentInput,
  nowMs: number = Date.now()
): Promise<CreateDokuPaymentOutput> {
  if (!input.uid) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }

  const bookingId = String(input.bookingId ?? "").trim();
  if (!bookingId) {
    throw new HttpsError("invalid-argument", "bookingId wajib diisi.");
  }

  // Tahap 1: Validasi kepemilikan, status booking, hold aktif, & reuse payment bila sudah dibuat
  const precheck = await store.runTransaction(async (tx) => {
    const user = await tx.getUser(input.uid);
    if (user && !user.isActive) {
      throw new HttpsError("permission-denied", "Akun pengguna tidak aktif.");
    }

    const booking = await tx.getBooking(bookingId);
    if (!booking) {
      throw new HttpsError("not-found", "Data booking tidak ditemukan.");
    }
    if (booking.userId !== input.uid) {
      throw new HttpsError("permission-denied", "Booking ini bukan milik Anda.");
    }
    if (booking.bookingStatus !== "pending_payment") {
      throw new HttpsError(
        "failed-precondition",
        "Booking tidak dalam status menunggu pembayaran."
      );
    }

    const [slot, court] = await Promise.all([
      tx.getSlot(booking.slotId),
      tx.getCourt(booking.courtId),
    ]);
    const holdExpiresAtMs = slot?.holdExpiresAtMs ?? 0;
    if (!slot || slot.bookingId !== bookingId || holdExpiresAtMs <= nowMs) {
      throw new HttpsError("deadline-exceeded", "Masa hold slot telah berakhir.");
    }

    if (booking.paymentId) {
      const existingPayment = await tx.getPayment(booking.paymentId);
      if (
        existingPayment &&
        existingPayment.paymentStatus === "pending" &&
        existingPayment.checkoutUrl
      ) {
        return {
          existing: {
            paymentId: existingPayment.id,
            providerOrderId: existingPayment.providerOrderId,
            paymentUrl: existingPayment.checkoutUrl,
            checkoutUrl: existingPayment.checkoutUrl,
            expiresAt: new Date(holdExpiresAtMs).toISOString(),
          },
          booking,
          user,
          courtName: court?.name ?? "Lapangan CourtMate",
          holdExpiresAtMs,
        };
      }
    }

    return {
      existing: null,
      booking,
      user,
      courtName: court?.name ?? "Lapangan CourtMate",
      holdExpiresAtMs,
    };
  });

  if (precheck.existing) {
    return precheck.existing;
  }

  const remainingHoldMinutes = Math.max(
    1,
    Math.ceil((precheck.holdExpiresAtMs - nowMs) / 60_000)
  );
  const sanitizedPrefix = bookingId.replace(/[^a-zA-Z0-9]/g, "").slice(0, 12);
  const providerOrderId = `CM-${sanitizedPrefix}-${nowMs}`;

  // Tahap 2: Panggil DOKU Checkout API menggunakan Secret Manager / .secret.local
  const { paymentUrl } = await gateway.createCheckoutSession({
    providerOrderId,
    amount: precheck.booking.amount,
    currency: precheck.booking.currency,
    paymentDueMinutes: remainingHoldMinutes,
    customerId: input.uid,
    customerName: precheck.user?.name,
    customerEmail: precheck.user?.email,
    itemName: `Booking ${precheck.courtName}`,
  });

  const paymentId = store.newId("payments");

  // Tahap 3: Simpan record `payments` dan tautkan ke `bookings` secara atomik
  return store.runTransaction(async (tx) => {
    const freshBooking = await tx.getBooking(bookingId);
    const freshSlot = freshBooking ? await tx.getSlot(freshBooking.slotId) : null;
    if (
      !freshBooking ||
      freshBooking.bookingStatus !== "pending_payment" ||
      !freshSlot ||
      freshSlot.bookingId !== bookingId ||
      (freshSlot.holdExpiresAtMs ?? 0) <= nowMs
    ) {
      throw new HttpsError(
        "deadline-exceeded",
        "Masa hold slot berakhir saat membuat sesi pembayaran."
      );
    }

    tx.savePayment({
      id: paymentId,
      bookingId,
      userId: input.uid,
      provider: "doku",
      providerOrderId,
      amount: freshBooking.amount,
      currency: freshBooking.currency,
      paymentStatus: "pending",
      checkoutUrl: paymentUrl,
      providerTransactionId: null,
      createdAtMs: nowMs,
      updatedAtMs: nowMs,
      paidAtMs: null,
    });

    tx.saveBooking({
      ...freshBooking,
      paymentId,
      updatedAtMs: nowMs,
    });

    return {
      paymentId,
      providerOrderId,
      paymentUrl,
      checkoutUrl: paymentUrl,
      expiresAt: new Date(freshSlot.holdExpiresAtMs!).toISOString(),
    };
  });
}

export const createDokuPayment = onCall(
  { secrets: [dokuClientId, dokuSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
    }
    const store = new FirestoreBackendStore();
    const gateway = createHttpDokuGateway(
      dokuClientId.value(),
      dokuSecretKey.value()
    );
    return executeCreateDokuPayment(store, gateway, {
      uid: request.auth.uid,
      bookingId: request.data?.bookingId,
    });
  }
);
