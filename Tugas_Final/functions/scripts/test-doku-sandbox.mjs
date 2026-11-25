import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const functionsRoot = path.resolve(__dirname, "..");

const { generateDokuSignature } = require(path.join(functionsRoot, "lib/doku/signature.js"));

function loadSecretLocal() {
  const secretPath = path.join(functionsRoot, ".secret.local");
  if (!fs.existsSync(secretPath)) {
    console.error("File functions/.secret.local belum ditemukan.");
    console.error("Buat file functions/.secret.local dengan isi:");
    console.error("DOKU_CLIENT_ID=BRN-XXXX-XXXXXXXXXXXX");
    console.error("DOKU_SECRET_KEY=SK-XXXXXXXXXXXXXXXXXXXX");
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

async function main() {
  const secrets = loadSecretLocal();
  const clientId = secrets.DOKU_CLIENT_ID;
  const secretKey = secrets.DOKU_SECRET_KEY;

  if (!clientId || !secretKey) {
    console.error("DOKU_CLIENT_ID dan DOKU_SECRET_KEY wajib diisi di functions/.secret.local");
    process.exit(1);
  }

  const requestTarget = "/checkout/v1/payment";
  const invoiceNumber = `CM-TEST-${Date.now()}`;
  const requestId = crypto.randomUUID();
  const requestTimestamp = new Date().toISOString().replace(/\.\d{3}Z$/, "Z");

  const rawBody = JSON.stringify({
    order: {
      amount: 120000,
      invoice_number: invoiceNumber,
      currency: "IDR",
      callback_url: "https://courtmate.id/payment-return",
      line_items: [
        {
          name: "Booking Arena Futsal Kampus Merdeka",
          price: 120000,
          quantity: 1,
        },
      ],
    },
    payment: {
      payment_due_date: 10,
    },
    customer: {
      id: "mhs-anmul-test",
      name: "Anmul CourtMate",
      email: "anmul@kampus.ac.id",
    },
  });

  const signature = generateDokuSignature({
    clientId,
    requestId,
    requestTimestamp,
    requestTarget,
    rawBody,
    secretKey,
  });

  console.log(`Mengirim uji DOKU Checkout Sandbox untuk invoice: ${invoiceNumber} ...`);

  const response = await fetch(`https://api-sandbox.doku.com${requestTarget}`, {
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

  const text = await response.text();
  if (!response.ok) {
    console.error(`DOKU Sandbox gagal (HTTP ${response.status}):`);
    console.error(text);
    process.exit(1);
  }

  const json = JSON.parse(text);
  const paymentUrl = json?.response?.payment?.url;
  console.log("\nBERHASIL! Kredensial DOKU Sandbox valid.");
  console.log("Invoice Number :", invoiceNumber);
  console.log("Payment URL    :", paymentUrl);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
