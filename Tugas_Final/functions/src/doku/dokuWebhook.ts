import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { onRequest } from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import { generateDokuSignature, timingSafeEqualSignature } from "./signature";

const dokuClientId = defineSecret("DOKU_CLIENT_ID");
const dokuSecretKey = defineSecret("DOKU_SECRET_KEY");

/**
 * CM-ARCH-DB-001 Bab 6.3: Webhook notifikasi DOKU yang terverifikasi & idempotent.
 */
export const dokuWebhook = onRequest(
  { secrets: [dokuClientId, dokuSecretKey] },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ message: "Method Not Allowed" });
      return;
    }

    const clientIdHeader = String(req.header("Client-Id") ?? "");
    const requestIdHeader = String(req.header("Request-Id") ?? "");
    const timestampHeader = String(req.header("Request-Timestamp") ?? "");
    const signatureHeader = String(req.header("Signature") ?? "");
    const rawBody = req.rawBody ? req.rawBody.toString("utf8") : JSON.stringify(req.body ?? {});

    const expectedClientId = dokuClientId.value();
    const secretKey = dokuSecretKey.value();

    if (!expectedClientId || !secretKey || clientIdHeader !== expectedClientId) {
      logger.warn("dokuWebhook: Client-Id tidak cocok atau secret belum diset", { requestIdHeader });
      res.status(401).json({ message: "Unauthorized" });
      return;
    }

    const expectedSignature = generateDokuSignature({
      clientId: clientIdHeader,
      requestId: requestIdHeader,
      requestTimestamp: timestampHeader,
      requestTarget: req.originalUrl || "/dokuWebhook",
      rawBody,
      secretKey,
    });

    if (!timingSafeEqualSignature(expectedSignature, signatureHeader)) {
      logger.warn("dokuWebhook: Signature tidak valid", { requestIdHeader });
      res.status(401).json({ message: "Invalid signature" });
      return;
    }

    const invoiceNumber = String(req.body?.order?.invoice_number ?? "");
    const notifiedAmount = Number(req.body?.order?.amount ?? 0);
    const txStatus = String(req.body?.transaction?.status ?? "").toUpperCase();
    const providerTxId = String(req.body?.transaction?.original_request_id ?? requestIdHeader);

    if (!invoiceNumber) {
      res.status(400).json({ message: "Missing invoice_number" });
      return;
    }

    const db = admin.firestore();
    const paymentsQuery = await db
      .collection("payments")
      .where("providerOrderId", "==", invoiceNumber)
      .limit(1)
      .get();

    if (paymentsQuery.empty) {
      logger.warn("dokuWebhook: Payment tidak ditemukan", { invoiceNumber });
      res.status(404).json({ message: "Order not found" });
      return;
    }

    const paymentDoc = paymentsQuery.docs[0];
    const eventDocId = `${invoiceNumber}_${txStatus}_${providerTxId}`;
    const eventRef = db.collection("payment_events").doc(eventDocId);

    await db.runTransaction(async (tx) => {
      const existingEvent = await tx.get(eventRef);
      if (existingEvent.exists) {
        return; // Idempotent: notifikasi sudah pernah diproses (BR-009)
      }

      const freshPayment = await tx.get(paymentDoc.ref);
      const payment = freshPayment.data()!;
      if (Number(payment.amount) !== notifiedAmount) {
        throw new Error("Nominal notifikasi tidak cocok dengan data tersimpan.");
      }

      const bookingRef = db.collection("bookings").doc(String(payment.bookingId));
      const bookingSnap = await tx.get(bookingRef);
      if (!bookingSnap.exists) return;

      const booking = bookingSnap.data()!;
      const slotRef = db.collection("slots").doc(String(booking.slotId));
      const nowTs = admin.firestore.Timestamp.now();

      if (txStatus === "SUCCESS") {
        tx.update(paymentDoc.ref, {
          paymentStatus: "paid",
          providerTransactionId: providerTxId,
          paidAt: nowTs,
          updatedAt: nowTs,
        });
        tx.update(bookingRef, {
          bookingStatus: "confirmed",
          confirmedAt: nowTs,
          updatedAt: nowTs,
        });
        tx.update(slotRef, {
          status: "booked",
          bookingId: bookingRef.id,
          holdExpiresAt: null,
          updatedAt: nowTs,
        });
      } else if (txStatus === "FAILED" || txStatus === "EXPIRED") {
        if (payment.paymentStatus !== "paid") {
          const mappedPaymentStatus = txStatus === "EXPIRED" ? "expired" : "failed";
          const mappedBookingStatus = txStatus === "EXPIRED" ? "expired" : "payment_failed";
          tx.update(paymentDoc.ref, {
            paymentStatus: mappedPaymentStatus,
            updatedAt: nowTs,
          });
          tx.update(bookingRef, {
            bookingStatus: mappedBookingStatus,
            updatedAt: nowTs,
          });
          tx.update(slotRef, {
            status: "available",
            bookingId: null,
            holdExpiresAt: null,
            updatedAt: nowTs,
          });
        }
      }

      tx.set(eventRef, {
        providerOrderId: invoiceNumber,
        bookingId: payment.bookingId,
        status: txStatus,
        processedAt: nowTs,
      });
    });

    res.status(200).json({ received: true });
  }
);
