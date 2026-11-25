import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { BackendStore, FirestoreBackendStore } from "../shared/store";
import { generateDokuSignature, timingSafeEqualSignature } from "./signature";

const dokuClientId = defineSecret("DOKU_CLIENT_ID");
const dokuSecretKey = defineSecret("DOKU_SECRET_KEY");

export interface WebhookSecurityConfig {
  expectedClientId: string;
  secretKey: string;
}

export interface IncomingWebhookRequest {
  method: string;
  requestTarget: string;
  headers: {
    clientId: string;
    requestId: string;
    requestTimestamp: string;
    signature: string;
  };
  rawBody: string;
  body: {
    order?: {
      invoice_number?: string;
      amount?: number;
      currency?: string;
    };
    transaction?: {
      status?: string;
      original_request_id?: string;
    };
  };
}

export interface WebhookExecutionResult {
  httpStatus: number;
  body: Record<string, unknown>;
}

/**
 * Modul Anmul A-06, A-07, A-08, A-09, A-11 & Bab 10:
 * - Verifikasi HMAC-SHA256 signature & Client-Id (AT-07).
 * - Pencocokan order ID, nominal, mata uang, dan booking (AT-08).
 * - Deduplikasi event idempoten melalui koleksi `payment_events` (AT-09).
 * - Proteksi pembayaran sukses terlambat (Bab 10): bila slot sudah dipegang/dipesan
 *   booking lain, jangan menimpa slot; tandai untuk rekonsiliasi manual.
 */
export async function executeDokuWebhook(
  store: BackendStore,
  config: WebhookSecurityConfig,
  req: IncomingWebhookRequest,
  nowMs: number = Date.now()
): Promise<WebhookExecutionResult> {
  if (req.method !== "POST") {
    return { httpStatus: 405, body: { message: "Method Not Allowed" } };
  }

  const { clientId, requestId, requestTimestamp, signature } = req.headers;
  if (
    !config.expectedClientId ||
    !config.secretKey ||
    !clientId ||
    !requestId ||
    !requestTimestamp ||
    !signature ||
    clientId !== config.expectedClientId
  ) {
    logger.warn("dokuWebhook: Header otorisasi tidak lengkap atau Client-Id tidak cocok", {
      requestId,
    });
    return { httpStatus: 401, body: { message: "Unauthorized" } };
  }

  const cleanRequestTarget = (req.requestTarget || "/dokuWebhook").split("?")[0] || "/";
  const candidateTargets = Array.from(
    new Set([cleanRequestTarget, "/dokuWebhook", "/"])
  );

  const signatureValid = candidateTargets.some((targetPath) => {
    const expectedSignature = generateDokuSignature({
      clientId,
      requestId,
      requestTimestamp,
      requestTarget: targetPath,
      rawBody: req.rawBody,
      secretKey: config.secretKey,
    });
    return timingSafeEqualSignature(expectedSignature, signature);
  });

  if (!signatureValid) {
    logger.warn("dokuWebhook: Signature tidak valid", { requestId });
    return { httpStatus: 401, body: { message: "Invalid signature" } };
  }

  const invoiceNumber = String(req.body?.order?.invoice_number ?? "").trim();
  const notifiedAmount = Math.round(Number(req.body?.order?.amount ?? NaN));
  const notifiedCurrency = String(req.body?.order?.currency ?? "IDR").trim();
  const txStatus = String(req.body?.transaction?.status ?? "").trim().toUpperCase();
  const providerTxId = String(
    req.body?.transaction?.original_request_id ?? requestId
  ).trim();

  if (!invoiceNumber || !Number.isFinite(notifiedAmount) || !txStatus) {
    return { httpStatus: 400, body: { message: "Payload notifikasi tidak lengkap" } };
  }

  const paymentId = await store.findPaymentIdByOrderId(invoiceNumber);
  if (!paymentId) {
    logger.warn("dokuWebhook: Order tidak ditemukan", { invoiceNumber, requestId });
    return { httpStatus: 404, body: { message: "Order not found" } };
  }

  const sanitizedEventId = `${invoiceNumber}_${txStatus}_${providerTxId}`.replace(
    /[^a-zA-Z0-9_-]/g,
    "_"
  );

  return store.runTransaction(async (tx) => {
    // A-08 / AT-09: Deduplikasi idempoten
    const existingEvent = await tx.getPaymentEvent(sanitizedEventId);
    if (existingEvent) {
      return {
        httpStatus: 200,
        body: { received: true, duplicate: true, outcome: existingEvent.outcome },
      };
    }

    const payment = await tx.getPayment(paymentId);
    if (!payment) {
      return { httpStatus: 404, body: { message: "Payment document missing" } };
    }

    const booking = await tx.getBooking(payment.bookingId);
    if (!booking) {
      return { httpStatus: 404, body: { message: "Booking document missing" } };
    }

    // A-07 / AT-08: Rekonsiliasi nominal & mata uang terhadap payment dan booking
    const amountMatches =
      payment.amount === notifiedAmount && booking.amount === notifiedAmount;
    const currencyMatches =
      payment.currency === notifiedCurrency && booking.currency === notifiedCurrency;

    if (!amountMatches || !currencyMatches) {
      logger.error("dokuWebhook: Mismatch nominal atau mata uang", {
        invoiceNumber,
        bookingId: booking.id,
        expectedAmount: booking.amount,
        notifiedAmount,
        expectedCurrency: booking.currency,
        notifiedCurrency,
      });

      tx.savePaymentEvent({
        id: sanitizedEventId,
        providerOrderId: invoiceNumber,
        bookingId: booking.id,
        status: txStatus,
        outcome: "rejected_mismatch",
        processedAtMs: nowMs,
      });

      return {
        httpStatus: 400,
        body: { message: "Transaction amount or currency mismatch" },
      };
    }

    const slot = await tx.getSlot(booking.slotId);
    if (!slot) {
      return { httpStatus: 404, body: { message: "Slot document missing" } };
    }

    if (txStatus === "SUCCESS") {
      // Bab 10: Cek apakah slot sudah dilepas dan diambil oleh booking lain
      const slotTakenByAnotherBooking =
        (slot.status === "held" || slot.status === "booked") &&
        slot.bookingId !== null &&
        slot.bookingId !== booking.id;

      if (slotTakenByAnotherBooking) {
        logger.warn("dokuWebhook: Pembayaran sukses terlambat, slot sudah dipegang user lain", {
          invoiceNumber,
          bookingId: booking.id,
          conflictingBookingId: slot.bookingId,
        });

        tx.savePayment({
          ...payment,
          paymentStatus: "paid",
          providerTransactionId: providerTxId,
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
          id: sanitizedEventId,
          providerOrderId: invoiceNumber,
          bookingId: booking.id,
          status: txStatus,
          outcome: "reconciliation_required",
          processedAtMs: nowMs,
        });

        return {
          httpStatus: 200,
          body: { received: true, outcome: "reconciliation_required" },
        };
      }

      // AT-06: Konfirmasi normal yang valid dan konsisten
      tx.savePayment({
        ...payment,
        paymentStatus: "paid",
        providerTransactionId: providerTxId,
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
        id: sanitizedEventId,
        providerOrderId: invoiceNumber,
        bookingId: booking.id,
        status: txStatus,
        outcome: "confirmed",
        processedAtMs: nowMs,
      });

      return { httpStatus: 200, body: { received: true, outcome: "confirmed" } };
    }

    if (txStatus === "FAILED" || txStatus === "EXPIRED") {
      // AT-10: Jangan menimpa jika sudah telanjur paid/confirmed
      if (payment.paymentStatus !== "paid" && booking.bookingStatus !== "confirmed") {
        const nextPaymentStatus = txStatus === "EXPIRED" ? "expired" : "failed";
        const nextBookingStatus = txStatus === "EXPIRED" ? "expired" : "payment_failed";

        tx.savePayment({
          ...payment,
          paymentStatus: nextPaymentStatus,
          providerTransactionId: providerTxId,
          updatedAtMs: nowMs,
        });

        tx.saveBooking({
          ...booking,
          bookingStatus: nextBookingStatus,
          updatedAtMs: nowMs,
        });

        if (slot.status === "held" && slot.bookingId === booking.id) {
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
          title:
            txStatus === "EXPIRED" ? "Waktu Pembayaran Berakhir" : "Pembayaran Gagal",
          body: "Slot yang ditahan telah dilepas kembali. Silakan buat reservasi baru.",
          type: "payment_failed_or_expired",
          isRead: false,
          createdAtMs: nowMs,
          relatedId: booking.id,
        });
      }

      tx.savePaymentEvent({
        id: sanitizedEventId,
        providerOrderId: invoiceNumber,
        bookingId: booking.id,
        status: txStatus,
        outcome: txStatus === "EXPIRED" ? "expired" : "failed",
        processedAtMs: nowMs,
      });

      return { httpStatus: 200, body: { received: true, outcome: txStatus.toLowerCase() } };
    }

    // Status transisi lain (mis. PENDING) dicatat untuk audit tanpa mengubah konfirmasi
    tx.savePaymentEvent({
      id: sanitizedEventId,
      providerOrderId: invoiceNumber,
      bookingId: booking.id,
      status: txStatus,
      outcome: "ignored_intermediate_status",
      processedAtMs: nowMs,
    });

    return { httpStatus: 200, body: { received: true, outcome: "ignored" } };
  });
}

export const dokuWebhook = onRequest(
  { secrets: [dokuClientId, dokuSecretKey] },
  async (req, res) => {
    const rawBody = req.rawBody
      ? req.rawBody.toString("utf8")
      : JSON.stringify(req.body ?? {});

    const store = new FirestoreBackendStore();
    const result = await executeDokuWebhook(
      store,
      {
        expectedClientId: dokuClientId.value(),
        secretKey: dokuSecretKey.value(),
      },
      {
        method: req.method,
        requestTarget: req.originalUrl || "/dokuWebhook",
        headers: {
          clientId: String(req.header("Client-Id") ?? ""),
          requestId: String(req.header("Request-Id") ?? ""),
          requestTimestamp: String(req.header("Request-Timestamp") ?? ""),
          signature: String(req.header("Signature") ?? ""),
        },
        rawBody,
        body: req.body ?? {},
      }
    );

    res.status(result.httpStatus).json(result.body);
  }
);
