import * as crypto from "crypto";

export interface DokuSignatureInput {
  clientId: string;
  requestId: string;
  requestTimestamp: string;
  requestTarget: string;
  rawBody: string;
  secretKey: string;
}

export function computeBodyDigest(rawBody: string): string {
  return crypto.createHash("sha256").update(rawBody, "utf8").digest("base64");
}

/**
 * Pembentukan komponen Digest & HMAC-SHA256 sesuai spesifikasi resmi DOKU Checkout API.
 */
export function generateDokuSignature(input: DokuSignatureInput): string {
  const digest = computeBodyDigest(input.rawBody);

  const componentSignature = [
    `Client-Id:${input.clientId}`,
    `Request-Id:${input.requestId}`,
    `Request-Timestamp:${input.requestTimestamp}`,
    `Request-Target:${input.requestTarget}`,
    `Digest:${digest}`,
  ].join("\n");

  const hmac = crypto
    .createHmac("sha256", input.secretKey)
    .update(componentSignature, "utf8")
    .digest("base64");

  return `HMACSHA256=${hmac}`;
}

export function timingSafeEqualSignature(expected: string, received: string): boolean {
  const a = Buffer.from(expected, "utf8");
  const b = Buffer.from(received, "utf8");
  if (a.length !== b.length) return false;
  return crypto.timingSafeEqual(a, b);
}
