import * as crypto from "crypto";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { BackendStore, FirestoreBackendStore } from "../shared/store";
import { generateDokuGetSignature } from "./signature";

const dokuClientId = defineSecret("DOKU_CLIENT_ID");
const dokuSecretKey = defineSecret("DOKU_SECRET_KEY");

const DOKU_SANDBOX_BASE_URL = "https://api-sandbox.doku.com";

export interface DokuOrderStatusResult {
  invoiceNumber: string;
  amount?: number;
  orderStatus?: string;
  transactionStatus: string;
  providerTransactionId?: string;
}

export interface DokuStatusGateway {
  checkOrderStatus(invoiceNumber: string): Promise<DokuOrderStatusResult>;
}

export function createHttpDokuStatusGateway(
  clientId: string,
  secretKey: string,
  baseUrl: string = DOKU_SANDBOX_BASE_URL
): DokuStatusGateway {
  return {
    async checkOrderStatus(invoiceNumber) {
      if (!clientId || !secretKey) {
        throw new HttpsError(
          "failed-precondition",
          "Kredensial DOKU Sandbox belum dikonfigurasi pada Secret Manager / .secret.local."
        );
      }

      const requestTarget = `/orders/v1/status/${encodeURIComponent(invoiceNumber)}`;
      const requestId = crypto.randomUUID();
      const requestTimestamp = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
      const signature = generateDokuGetSignature({
        clientId,
        requestId,
        requestTimestamp,
        requestTarget,
        secretKey,
      });

      const response = await fetch(`${baseUrl}${requestTarget}`, {
        method: "GET",
        headers: {
          "Client-Id": clientId,
          "Request-Id": requestId,
          "Request-Timestamp": requestTimestamp,
          "Signature": signature,
        },
      });

      if (response.status === 404) {
        // DOKU mengembalikan 404 jika pengguna belum memilih metode pembayaran di halaman checkout.
        return {
          invoiceNumber,
          orderStatus: "PENDING",
          transactionStatus: "PENDING",
        };
      }

      const responseText = await response.text();
      if (!response.ok) {
        logger.error("DOKU Check Status API gagal", {
          status: response.status,
          invoiceNumber,
          requestId,
          dokuResponse: responseText.slice(0, 500),
        });
        throw new HttpsError(
          "internal",
          `Gagal memeriksa status pembayaran DOKU (HTTP ${response.status}).`
        );
      }

      const json = JSON.parse(responseText) as {
        order?: { amount?: number | string; status?: string };
        transaction?: { status?: string; original_request_id?: string };
        uuid?: string;
      };

      const rawAmount = json.order?.amount;
      const parsedAmount =
        rawAmount !== undefined && rawAmount !== null && Number.isFinite(Number(rawAmount))
          ? Math.round(Number(rawAmount))
          : undefined;

      return {
        invoiceNumber,
        amount: parsedAmount,
        orderStatus: json.order?.status,
        transactionStatus: String(json.transaction?.status ?? "PENDING"),
        providerTransactionId:
          json.transaction?.original_request_id ?? json.uuid ?? requestId,
      };
    },
  };
}

export interface ReconcilePaymentInput {
  uid: string;
  bookingId?: string;
}

export interface ReconcilePaymentOutput {
  bookingId: string;
  bookingStatus: string;
  outcome: string;
}

/**
 * Mengecek status transaksi aktual ke server DOKU (`GET /orders/v1/status/{invoice_number}`).
 * Dipanggil ketika pengguna kembali ke APK atau menekan tombol "Cek Status Pembayaran".
 * Tetap menjaga AT-11 / BR-008: hanya mengonfirmasi bila server DOKU benar-benar mengembalikan `SUCCESS`.
 */
export async function executeReconcilePayment(
  store: BackendStore,
  statusGateway: DokuStatusGateway,
  input: ReconcilePaymentInput,
  nowMs: number = Date.now()
): Promise<ReconcilePaymentOutput> {
  if (!input.uid) {
    throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
  }

  const bookingId = String(input.bookingId ?? "").trim();
  if (!bookingId) {
    throw new HttpsError("invalid-argument", "bookingId wajib diisi.");
  }

  // Tahap 1: Validasi kepemilikan dan ambil providerOrderId
  const initial = await store.runTransaction(async (tx) => {
    const booking = await tx.getBooking(bookingId);
    if (!booking) {
      throw new HttpsError("not-found", "Data booking tidak ditemukan.");
    }
    if (booking.userId !== input.uid) {
      throw new HttpsError("permission-denied", "Booking ini bukan milik Anda.");
    }
    if (booking.bookingStatus === "confirmed") {
      return {
        earlyResult: {
          bookingId,
          bookingStatus: "confirmed",
          outcome: "already_confirmed",
        },
        providerOrderId: null as string | null,
      };
    }
    if (booking.bookingStatus !== "pending_payment" || !booking.paymentId) {
      return {
        earlyResult: {
          bookingId,
          bookingStatus: booking.bookingStatus,
          outcome: "not_pending",
        },
        providerOrderId: null as string | null,
      };
    }

    const payment = await tx.getPayment(booking.paymentId);
    if (!payment || !payment.providerOrderId) {
      return {
        earlyResult: {
          bookingId,
          bookingStatus: booking.bookingStatus,
          outcome: "not_pending",
        },
        providerOrderId: null as string | null,
      };
    }

    return {
      earlyResult: null as ReconcilePaymentOutput | null,
      providerOrderId: payment.providerOrderId,
    };
  });

  if (initial.earlyResult || !initial.providerOrderId) {
    return (
      initial.earlyResult ?? {
        bookingId,
        bookingStatus: "pending_payment",
        outcome: "not_pending",
      }
    );
  }

  // Tahap 2: Query langsung ke DOKU Check Status API (server-to-server)
  const statusResult = await statusGateway.checkOrderStatus(initial.providerOrderId);
  const txStatus = (statusResult.transactionStatus || "").trim().toUpperCase();
  const orderStatus = (statusResult.orderStatus || "").trim().toUpperCase();

  // Tahap 3: Terapkan hasil status secara atomik & idempoten
  return store.runTransaction(async (tx) => {
    const booking = await tx.getBooking(bookingId);
    if (!booking) {
      throw new HttpsError("not-found", "Data booking tidak ditemukan.");
    }
    if (booking.bookingStatus === "confirmed") {
      return {
        bookingId,
        bookingStatus: "confirmed",
        outcome: "already_confirmed",
      };
    }

    const payment = booking.paymentId ? await tx.getPayment(booking.paymentId) : null;
    if (!payment) {
      return {
        bookingId,
        bookingStatus: booking.bookingStatus,
        outcome: "not_pending",
      };
    }
    if (payment.paymentStatus === "paid") {
      return {
        bookingId,
        bookingStatus: booking.bookingStatus,
        outcome: "already_paid",
      };
    }

    if (txStatus === "SUCCESS") {
      if (
        statusResult.amount !== undefined &&
        Math.round(statusResult.amount) !== booking.amount
      ) {
        logger.error("reconcilePayment: Mismatch nominal dari DOKU", {
          bookingId,
          expectedAmount: booking.amount,
          dokuAmount: statusResult.amount,
        });
        tx.savePaymentEvent({
          id: `reconcile_${payment.providerOrderId}_MISMATCH`,
          providerOrderId: payment.providerOrderId,
          bookingId,
          status: txStatus,
          outcome: "rejected_mismatch",
          processedAtMs: nowMs,
        });
        return {
          bookingId,
          bookingStatus: booking.bookingStatus,
          outcome: "rejected_mismatch",
        };
      }

      const eventId = `reconcile_${payment.providerOrderId}_SUCCESS`;
      const existingEvent = await tx.getPaymentEvent(eventId);
      if (existingEvent) {
        return {
          bookingId,
          bookingStatus: booking.bookingStatus,
          outcome: existingEvent.outcome,
        };
      }

      const slot = await tx.getSlot(booking.slotId);
      if (!slot) {
        throw new HttpsError("not-found", "Data slot tidak ditemukan.");
      }

      const slotTakenByAnotherBooking =
        (slot.status === "held" || slot.status === "booked") &&
        slot.bookingId !== null &&
        slot.bookingId !== booking.id;

      if (slotTakenByAnotherBooking) {
        tx.savePayment({
          ...payment,
          paymentStatus: "paid",
          providerTransactionId: statusResult.providerTransactionId ?? payment.providerTransactionId,
          paidAtMs: nowMs,
          updatedAtMs: nowMs,
        });
        tx.saveBooking({
          ...booking,
          reconciliationRequired: true,
          reconciliationReason: "late_payment_slot_conflict",
          refundStatus: "manual_review_required",
          updatedAtMs: nowMs,
        });
        tx.createNotification({
          userId: booking.userId,
          title: "Pembayaran Diterima — Menunggu Rekonsiliasi",
          body:
            "Pembayaran Anda diterima setelah masa hold berakhir dan jadwal telah terisi. Tim pengelola akan memproses penyesuaian/pengembalian dana manual.",
          type: "payment_reconciliation",
          isRead: false,
          createdAtMs: nowMs,
          relatedId: booking.id,
        });
        tx.savePaymentEvent({
          id: eventId,
          providerOrderId: payment.providerOrderId,
          bookingId,
          status: txStatus,
          outcome: "reconciliation_required",
          processedAtMs: nowMs,
        });
        return {
          bookingId,
          bookingStatus: booking.bookingStatus,
          outcome: "reconciliation_required",
        };
      }

      tx.savePayment({
        ...payment,
        paymentStatus: "paid",
        providerTransactionId:
          statusResult.providerTransactionId ?? payment.providerTransactionId,
        paidAtMs: nowMs,
        updatedAtMs: nowMs,
      });
      tx.saveBooking({
        ...booking,
        bookingStatus: "confirmed",
        confirmedAtMs: booking.confirmedAtMs ?? nowMs,
        updatedAtMs: nowMs,
      });
      tx.saveSlot({
        ...slot,
        status: "booked",
        bookingId: booking.id,
        holdExpiresAtMs: null,
        updatedAtMs: nowMs,
      });
      tx.createNotification({
        userId: booking.userId,
        title: "Booking Terkonfirmasi",
        body: "Pembayaran DOKU Anda telah terverifikasi. Jadwal lapangan berhasil dikonfirmasi!",
        type: "booking_confirmed",
        isRead: false,
        createdAtMs: nowMs,
        relatedId: booking.id,
      });
      tx.savePaymentEvent({
        id: eventId,
        providerOrderId: payment.providerOrderId,
        bookingId,
        status: txStatus,
        outcome: "confirmed_via_reconcile",
        processedAtMs: nowMs,
      });

      return {
        bookingId,
        bookingStatus: "confirmed",
        outcome: "confirmed",
      };
    }

    if (
      txStatus === "FAILED" ||
      txStatus === "EXPIRED" ||
      orderStatus === "ORDER_EXPIRED"
    ) {
      const isExpired = txStatus === "EXPIRED" || orderStatus === "ORDER_EXPIRED";
      const nextPaymentStatus = isExpired ? "expired" : "failed";
      const nextBookingStatus = isExpired ? "expired" : "payment_failed";

      if (booking.bookingStatus === "pending_payment") {
        const slot = await tx.getSlot(booking.slotId);
        tx.savePayment({
          ...payment,
          paymentStatus: nextPaymentStatus,
          providerTransactionId:
            statusResult.providerTransactionId ?? payment.providerTransactionId,
          updatedAtMs: nowMs,
        });
        tx.saveBooking({
          ...booking,
          bookingStatus: nextBookingStatus,
          updatedAtMs: nowMs,
        });
        if (slot && slot.status === "held" && slot.bookingId === booking.id) {
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
          title: isExpired ? "Waktu Pembayaran Berakhir" : "Pembayaran Gagal",
          body: "Slot yang ditahan telah dilepas kembali. Silakan buat reservasi baru.",
          type: "payment_failed_or_expired",
          isRead: false,
          createdAtMs: nowMs,
          relatedId: booking.id,
        });
      }

      tx.savePaymentEvent({
        id: `reconcile_${payment.providerOrderId}_${nextBookingStatus.toUpperCase()}`,
        providerOrderId: payment.providerOrderId,
        bookingId,
        status: txStatus || orderStatus,
        outcome: nextBookingStatus,
        processedAtMs: nowMs,
      });

      return {
        bookingId,
        bookingStatus: nextBookingStatus,
        outcome: nextBookingStatus,
      };
    }

    // Masih PENDING / ORDER_GENERATED -> jangan konfirmasi (AT-11)
    return {
      bookingId,
      bookingStatus: booking.bookingStatus,
      outcome: "still_pending",
    };
  });
}

export const reconcilePayment = onCall(
  { secrets: [dokuClientId, dokuSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Pengguna wajib login terlebih dahulu.");
    }
    const store = new FirestoreBackendStore();
    const statusGateway = createHttpDokuStatusGateway(
      dokuClientId.value(),
      dokuSecretKey.value()
    );
    return executeReconcilePayment(store, statusGateway, {
      uid: request.auth.uid,
      bookingId: request.data?.bookingId,
    });
  }
);
