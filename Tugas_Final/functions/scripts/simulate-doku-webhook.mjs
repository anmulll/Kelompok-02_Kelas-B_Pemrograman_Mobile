import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const functionsRoot = path.resolve(__dirname, "..");

const admin = require("firebase-admin");
const { generateDokuSignature } = require(path.join(functionsRoot, "lib/doku/signature.js"));

process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "courtmate-40007";

function loadSecretLocal() {
  const secretPath = path.join(functionsRoot, ".secret.local");
  if (!fs.existsSync(secretPath)) {
    console.error("File functions/.secret.local belum ditemukan.");
    process.exit(1);
  }
  const env = {};
  for (const line of fs.readFileSync(secretPath, "utf8").split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const eq = trimmed.indexOf("=");
    if (eq === -1) continue;
    env[trimmed.slice(0, eq).trim()] = trimmed.slice(eq + 1).trim();
  }
  return env;
}

async function resolveLatestPendingPayment() {
  if (!admin.apps.length) {
    admin.initializeApp({ projectId: PROJECT_ID });
  }
  const db = admin.firestore();
  const snap = await db
    .collection("payments")
    .where("paymentStatus", "==", "pending")
    .get();

  if (snap.empty) {
    return null;
  }

  let latestDoc = snap.docs[0].data();
  let latestMs = latestDoc.createdAt?.toMillis?.() ?? 0;

  for (const docSnap of snap.docs) {
    const data = docSnap.data();
    const ms = data.createdAt?.toMillis?.() ?? 0;
    if (ms >= latestMs) {
      latestMs = ms;
      latestDoc = data;
    }
  }

  return {
    providerOrderId: String(latestDoc.providerOrderId),
    amount: Number(latestDoc.amount),
    currency: String(latestDoc.currency ?? "IDR"),
  };
}

/**
 * Mengirim simulasi webhook DOKU bertanda tangan HMAC-SHA256 ke Firebase Functions Emulator.
 * Penggunaan:
 *   npm --prefix functions run test:webhook-emulator
 *   npm --prefix functions run test:webhook-emulator -- SUCCESS
 *   npm --prefix functions run test:webhook-emulator -- EXPIRED
 *   npm --prefix functions run test:webhook-emulator -- INVALID_SIG
 *   npm --prefix functions run test:webhook-emulator -- MISMATCH
 */
async function main() {
  const mode = (process.argv[2] || "SUCCESS").toUpperCase();
  const secrets = loadSecretLocal();
  const clientId = secrets.DOKU_CLIENT_ID;
  const secretKey = secrets.DOKU_SECRET_KEY;

  if (!clientId || !secretKey) {
    console.error("DOKU_CLIENT_ID dan DOKU_SECRET_KEY wajib diisi di functions/.secret.local");
    process.exit(1);
  }

  const latest = await resolveLatestPendingPayment();
  if (!latest) {
    console.error("Tidak ditemukan dokumen `payments` berstatus `pending` di Firestore Emulator.");
    console.error("Buat booking dulu lewat aplikasi di Emulator Android sampai masuk layar Status Pembayaran.");
    process.exit(1);
  }

  const txStatus = mode === "EXPIRED" || mode === "FAILED" ? mode : "SUCCESS";
  const amount = mode === "MISMATCH" ? latest.amount - 5000 : latest.amount;
  const requestId = `sim-webhook-${Date.now()}`;
  const requestTimestamp = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
  const requestTarget = "/dokuWebhook";

  const rawBody = JSON.stringify({
    order: {
      invoice_number: latest.providerOrderId,
      amount,
      currency: latest.currency,
    },
    transaction: {
      status: txStatus,
      original_request_id: requestId,
    },
  });

  const signature =
    mode === "INVALID_SIG"
      ? "HMACSHA256=invalid_forged_signature_test"
      : generateDokuSignature({
          clientId,
          requestId,
          requestTimestamp,
          requestTarget,
          rawBody,
          secretKey,
        });

  const emulatorUrl = `http://127.0.0.1:5001/${PROJECT_ID}/us-central1/dokuWebhook`;
  console.log(`Mengirim webhook (${mode}) untuk order ${latest.providerOrderId} (${amount} ${latest.currency})...`);

  const response = await fetch(emulatorUrl, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Client-Id": clientId,
      "Request-Id": requestId,
      "Request-Timestamp": requestTimestamp,
      "Signature": signature,
    },
    body: rawBody,
  });

  const responseText = await response.text();
  console.log(`HTTP ${response.status} -> ${responseText}`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
