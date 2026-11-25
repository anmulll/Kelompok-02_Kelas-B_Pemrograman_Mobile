import * as crypto from "crypto";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { generateDokuSignature } from "../doku/signature";

const dokuClientId = defineSecret("DOKU_CLIENT_ID");
const dokuSecretKey = defineSecret("DOKU_SECRET_KEY");

const DOKU_SANDBOX_BASE_URL = "https://api-sandbox.doku.com";
const DOKU_CHECKOUT_PATH = "/checkout/v1/payment";

/**
 * CM-ARCH-DB-001 Bab 6.2 & Bab 12:
 * Pembuatan sesi pembayaran DOKU Checkout menggunakan Secret Manager.
 */
export const createDokuPayment = onCall(
  { secrets: [dokuClientId, dokuSecretKey] },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Pengguna wajib login.");
    }

    const uid = request.auth.uid;
    const bookingId = String(request.data?.bookingId ?? "");
    if (!bookingId) {
      throw new HttpsError("invalid-argument", "bookingId wajib diisi.");
    }

    const db = admin.firestore();
    const bookingRef = db.collection("bookings").doc(bookingId);
    const bookingSnap = await bookingRef.get();

    if (!bookingSnap.exists) {
      throw new HttpsError("not-found", "Data booking tidak ditemukan.");
    }

    const booking = bookingSnap.data()!;
    if (booking.userId !== uid) {
      throw new HttpsError("permission-denied", "Booking bukan milik Anda.");
    }
    if (booking.bookingStatus !== "pending_payment") {
      throw new HttpsError("failed-precondition", "Booking tidak dalam status menunggu pembayaran.");
    }

    const slotSnap = await db.collection("slots").doc(String(booking.slotId)).get();
    const holdExpiresAtMs = slotSnap.data()?.holdExpiresAt?.toMillis?.() ?? 0;
    if (holdExpiresAtMs <= Date.now()) {
      throw new HttpsError("deadline-exceeded", "Masa hold slot telah berakhir.");
    }

    const providerOrderId = `CM-${bookingId.slice(0, 12)}-${Date.now()}`;
    const paymentRef = db.collection("payments").doc();
    const amount = Number(booking.amount);

    const requestBody = JSON.stringify({
      order: {
        amount,
        invoice_number: providerOrderId,
        currency: booking.currency ?? "IDR",
      },
      payment: {
        payment_due_date: 10,
      },
    });

    const clientId = dokuClientId.value();
    const secretKey = dokuSecretKey.value();
    let checkoutUrl = `${DOKU_SANDBOX_BASE_URL}/mock-checkout/${providerOrderId}`;

    // Jika kredensial Sandbox sudah diisi di Secret Manager, panggil endpoint DOKU Sandbox:
    if (clientId && secretKey) {
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

      const response = await fetch(`${DOKU_SANDBOX_BASE_URL}${DOKU_CHECKOUT_PATH}`, {
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

      if (!response.ok) {
        throw new HttpsError("internal", `Gagal membuat invoice DOKU (${response.status}).`);
      }

      const json = (await response.json()) as {
        response?: { payment?: { url?: string } };
      };
      checkoutUrl = json.response?.payment?.url ?? checkoutUrl;
    }

    const nowTs = admin.firestore.Timestamp.now();
    const batch = db.batch();
    batch.set(paymentRef, {
      bookingId,
      userId: uid,
      provider: "doku",
      providerOrderId,
      amount,
      currency: booking.currency ?? "IDR",
      paymentStatus: "pending",
      checkoutUrl,
      providerTransactionId: null,
      createdAt: nowTs,
      updatedAt: nowTs,
      paidAt: null,
    });
    batch.update(bookingRef, {
      paymentId: paymentRef.id,
      updatedAt: nowTs,
    });
    await batch.commit();

    return {
      paymentId: paymentRef.id,
      providerOrderId,
      checkoutUrl,
    };
  }
);
