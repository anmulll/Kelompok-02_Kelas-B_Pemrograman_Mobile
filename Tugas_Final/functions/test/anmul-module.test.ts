import assert from "node:assert/strict";
import * as fs from "node:fs";
import * as path from "node:path";
import { describe, it } from "node:test";
import { executeCancelBooking } from "../src/booking/cancel-booking";
import { executeCreateBooking } from "../src/booking/create-booking";
import { DokuCheckoutGateway, executeCreateDokuPayment } from "../src/doku/create-payment";
import { generateDokuSignature } from "../src/doku/signature";
import { executeDokuWebhook } from "../src/doku/webhook";
import { executeCleanupExpiredHolds } from "../src/scheduler/cleanup-expired-holds";
import { InMemoryBackendStore } from "./in-memory-store";

const NOW_MS = Date.parse("2026-11-25T12:00:00Z");
const TEST_CLIENT_ID = "BRN-0001-SANDBOX";
const TEST_SECRET_KEY = "test-only-ephemeral-hmac-key";

function seedStore(): InMemoryBackendStore {
  const store = new InMemoryBackendStore();
  store.users.set("mhs_1", { uid: "mhs_1", role: "student", isActive: true });
  store.users.set("mhs_2", { uid: "mhs_2", role: "student", isActive: true });
  store.courts.set("court_1", {
    id: "court_1",
    name: "GOR Kampus Arena",
    isActive: true,
    verificationStatus: "verified",
    ownerId: "admin_1",
  });
  store.slots.set("slot_1", {
    id: "slot_1",
    courtId: "court_1",
    startAtMs: NOW_MS + 2 * 60 * 60 * 1000,
    endAtMs: NOW_MS + 3 * 60 * 60 * 1000,
    price: 150_000,
    currency: "IDR",
    status: "available",
    bookingId: null,
    holdExpiresAtMs: null,
    updatedAtMs: NOW_MS,
  });
  return store;
}

const mockDokuGateway: DokuCheckoutGateway = {
  async createCheckoutSession(payload) {
    return {
      paymentUrl: `https://sandbox.doku.com/checkout-link/${payload.providerOrderId}`,
    };
  },
};

function makeSignedWebhookRequest(params: {
  invoiceNumber: string;
  amount: number;
  currency?: string;
  status: string;
  requestId?: string;
  overrideSignature?: string;
}) {
  const requestId = params.requestId ?? "req-webhook-001";
  const requestTimestamp = "2026-11-25T12:02:00Z";
  const requestTarget = "/dokuWebhook";
  const bodyObj = {
    order: {
      invoice_number: params.invoiceNumber,
      amount: params.amount,
      currency: params.currency ?? "IDR",
    },
    transaction: {
      status: params.status,
      original_request_id: requestId,
    },
  };
  const rawBody = JSON.stringify(bodyObj);
  const signature =
    params.overrideSignature ??
    generateDokuSignature({
      clientId: TEST_CLIENT_ID,
      requestId,
      requestTimestamp,
      requestTarget,
      rawBody,
      secretKey: TEST_SECRET_KEY,
    });

  return {
    method: "POST",
    requestTarget,
    headers: {
      clientId: TEST_CLIENT_ID,
      requestId,
      requestTimestamp,
      signature,
    },
    rawBody,
    body: bodyObj,
  };
}

describe("Modul Anmul — Booking, DOKU Checkout & Backend (AT-01 s.d. AT-12)", () => {
  it("AT-01 & AT-04: Slot available dipesan -> pending_payment, slot held, dan manipulasi harga klien diabaikan", async () => {
    const store = seedStore();
    const payloadFromClient = {
      uid: "mhs_1",
      courtId: "court_1",
      slotId: "slot_1",
      idempotencyKey: "idem-001",
      amount: 1_000, // Manipulasi nominal dari klien
      price: 1_000,
    };

    const res = await executeCreateBooking(store, payloadFromClient, NOW_MS);
    assert.equal(res.bookingStatus, "pending_payment");
    assert.equal(res.amount, 150_000); // Tetap memakai harga server!
    assert.equal(res.currency, "IDR");
    assert.ok(res.holdExpiresAt);

    const slot = store.slots.get("slot_1")!;
    assert.equal(slot.status, "held");
    assert.equal(slot.bookingId, res.bookingId);
  });

  it("AT-02: Slot yang sedang held atau booked menolak pemesanan kedua", async () => {
    const store = seedStore();
    await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "idem-a" },
      NOW_MS
    );

    await assert.rejects(
      () =>
        executeCreateBooking(
          store,
          { uid: "mhs_2", courtId: "court_1", slotId: "slot_1", idempotencyKey: "idem-b" },
          NOW_MS + 30_000
        ),
      (err: { code?: string }) => err.code === "already-exists"
    );
  });

  it("AT-03: Dua request simultan pada slot yang sama hanya menghasilkan satu hold berhasil", async () => {
    const store = seedStore();

    const results = await Promise.allSettled([
      executeCreateBooking(
        store,
        { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "race-1" },
        NOW_MS
      ),
      executeCreateBooking(
        store,
        { uid: "mhs_2", courtId: "court_1", slotId: "slot_1", idempotencyKey: "race-2" },
        NOW_MS
      ),
    ]);

    const fulfilled = results.filter((r) => r.status === "fulfilled");
    const rejected = results.filter((r) => r.status === "rejected");

    assert.equal(fulfilled.length, 1);
    assert.equal(rejected.length, 1);
    assert.equal(store.bookings.size, 1);
  });

  it("AT-05 & AT-06: Create DOKU payment Sandbox & Webhook valid mengonfirmasi booking menjadi confirmed", async () => {
    const store = seedStore();
    const booking = await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "idem-pay" },
      NOW_MS
    );

    const payment = await executeCreateDokuPayment(
      store,
      mockDokuGateway,
      { uid: "mhs_1", bookingId: booking.bookingId },
      NOW_MS + 10_000
    );

    assert.ok(payment.paymentUrl.startsWith("https://sandbox.doku.com/"));

    // AT-11: Sebelum webhook masuk, status tetap pending_payment meskipun paymentUrl sudah dibuat
    assert.equal(store.bookings.get(booking.bookingId)!.bookingStatus, "pending_payment");

    const webhookRes = await executeDokuWebhook(
      store,
      { expectedClientId: TEST_CLIENT_ID, secretKey: TEST_SECRET_KEY },
      makeSignedWebhookRequest({
        invoiceNumber: payment.providerOrderId,
        amount: 150_000,
        status: "SUCCESS",
      }),
      NOW_MS + 60_000
    );

    assert.equal(webhookRes.httpStatus, 200);
    assert.equal(store.bookings.get(booking.bookingId)!.bookingStatus, "confirmed");
    assert.equal(store.payments.get(payment.paymentId)!.paymentStatus, "paid");
    assert.equal(store.slots.get("slot_1")!.status, "booked");
    assert.equal(store.notifications.length, 1);
  });

  it("AT-07: Signature tidak valid ditolak (401) dan tidak mengubah status booking", async () => {
    const store = seedStore();
    const booking = await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "idem-sig" },
      NOW_MS
    );
    const payment = await executeCreateDokuPayment(
      store,
      mockDokuGateway,
      { uid: "mhs_1", bookingId: booking.bookingId },
      NOW_MS + 5_000
    );

    const webhookRes = await executeDokuWebhook(
      store,
      { expectedClientId: TEST_CLIENT_ID, secretKey: TEST_SECRET_KEY },
      makeSignedWebhookRequest({
        invoiceNumber: payment.providerOrderId,
        amount: 150_000,
        status: "SUCCESS",
        overrideSignature: "HMACSHA256=invalid_forged_signature",
      }),
      NOW_MS + 20_000
    );

    assert.equal(webhookRes.httpStatus, 401);
    assert.equal(store.bookings.get(booking.bookingId)!.bookingStatus, "pending_payment");
    assert.equal(store.slots.get("slot_1")!.status, "held");
  });

  it("AT-08: Amount mismatch ditolak (400) dan dicatat pada payment_events tanpa konfirmasi", async () => {
    const store = seedStore();
    const booking = await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "idem-mismatch" },
      NOW_MS
    );
    const payment = await executeCreateDokuPayment(
      store,
      mockDokuGateway,
      { uid: "mhs_1", bookingId: booking.bookingId },
      NOW_MS + 5_000
    );

    const webhookRes = await executeDokuWebhook(
      store,
      { expectedClientId: TEST_CLIENT_ID, secretKey: TEST_SECRET_KEY },
      makeSignedWebhookRequest({
        invoiceNumber: payment.providerOrderId,
        amount: 50_000, // Mismatch dari 150_000!
        status: "SUCCESS",
      }),
      NOW_MS + 20_000
    );

    assert.equal(webhookRes.httpStatus, 400);
    assert.equal(store.bookings.get(booking.bookingId)!.bookingStatus, "pending_payment");
    assert.equal(store.paymentEvents.size, 1);
  });

  it("AT-09: Webhook duplikat bersifat idempoten dan hanya diproses satu kali", async () => {
    const store = seedStore();
    const booking = await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "idem-dup" },
      NOW_MS
    );
    const payment = await executeCreateDokuPayment(
      store,
      mockDokuGateway,
      { uid: "mhs_1", bookingId: booking.bookingId },
      NOW_MS + 5_000
    );

    const req = makeSignedWebhookRequest({
      invoiceNumber: payment.providerOrderId,
      amount: 150_000,
      status: "SUCCESS",
      requestId: "dup-event-99",
    });

    const first = await executeDokuWebhook(
      store,
      { expectedClientId: TEST_CLIENT_ID, secretKey: TEST_SECRET_KEY },
      req,
      NOW_MS + 30_000
    );
    const second = await executeDokuWebhook(
      store,
      { expectedClientId: TEST_CLIENT_ID, secretKey: TEST_SECRET_KEY },
      req,
      NOW_MS + 45_000
    );

    assert.equal(first.httpStatus, 200);
    assert.equal(second.httpStatus, 200);
    assert.equal(second.body.duplicate, true);
    assert.equal(store.notifications.length, 1); // Tidak membuat notifikasi ganda
  });

  it("AT-10 & A-12: Cleanup hold expired melepaskan slot kembali ke available dan menandai booking expired", async () => {
    const store = seedStore();
    const booking = await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "idem-exp" },
      NOW_MS
    );

    // 11 menit kemudian (lewat dari masa hold 10 menit)
    const afterExpiryMs = NOW_MS + 11 * 60 * 1000;
    const summary = await executeCleanupExpiredHolds(store, afterExpiryMs);

    assert.equal(summary.releasedCount, 1);
    assert.equal(store.slots.get("slot_1")!.status, "available");
    assert.equal(store.bookings.get(booking.bookingId)!.bookingStatus, "expired");
  });

  it("Bab 10 Rekonsiliasi: Pembayaran sukses terlambat saat slot sudah dipesan user lain tidak menimpa slot", async () => {
    const store = seedStore();
    const firstBooking = await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "late-1" },
      NOW_MS
    );
    const firstPayment = await executeCreateDokuPayment(
      store,
      mockDokuGateway,
      { uid: "mhs_1", bookingId: firstBooking.bookingId },
      NOW_MS + 5_000
    );

    // Hold mhs_1 habis pada menit ke-11, lalu mhs_2 memesan slot yang sama
    const t11m = NOW_MS + 11 * 60 * 1000;
    await executeCleanupExpiredHolds(store, t11m);
    const secondBooking = await executeCreateBooking(
      store,
      { uid: "mhs_2", courtId: "court_1", slotId: "slot_1", idempotencyKey: "new-holder" },
      t11m + 1_000
    );

    // Tiba-tiba webhook SUCCESS terlambat untuk firstPayment masuk pada menit ke-12
    const lateRes = await executeDokuWebhook(
      store,
      { expectedClientId: TEST_CLIENT_ID, secretKey: TEST_SECRET_KEY },
      makeSignedWebhookRequest({
        invoiceNumber: firstPayment.providerOrderId,
        amount: 150_000,
        status: "SUCCESS",
        requestId: "late-tx-01",
      }),
      t11m + 60_000
    );

    assert.equal(lateRes.httpStatus, 200);
    assert.equal(lateRes.body.outcome, "reconciliation_required");
    // Slot tetap milik mhs_2 (tidak tertimpa!)
    assert.equal(store.slots.get("slot_1")!.bookingId, secondBooking.bookingId);
    // Booking pertama tetap tidak confirmed dan ditandai butuh rekonsiliasi manual
    const updatedFirst = store.bookings.get(firstBooking.bookingId)!;
    assert.notEqual(updatedFirst.bookingStatus, "confirmed");
    assert.equal(updatedFirst.reconciliationRequired, true);
  });

  it("A-10: Pembatalan booking pending_payment melepas slot secara langsung", async () => {
    const store = seedStore();
    const booking = await executeCreateBooking(
      store,
      { uid: "mhs_1", courtId: "court_1", slotId: "slot_1", idempotencyKey: "cancel-1" },
      NOW_MS
    );

    const cancelRes = await executeCancelBooking(
      store,
      { uid: "mhs_1", bookingId: booking.bookingId, reason: "Jadwal kuliah bentrok" },
      NOW_MS + 30_000
    );

    assert.equal(cancelRes.bookingStatus, "cancelled");
    assert.equal(store.slots.get("slot_1")!.status, "available");
  });

  it("AT-12: Secret scan pada kode aplikasi Flutter (lib/) tidak mengandung DOKU_SECRET_KEY", () => {
    const libDir = path.resolve(__dirname, "../../../lib");
    const files: string[] = [];

    function walk(dir: string) {
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) walk(full);
        else if (entry.name.endsWith(".dart")) files.push(full);
      }
    }

    walk(libDir);
    assert.ok(files.length > 0);
    for (const file of files) {
      const content = fs.readFileSync(file, "utf8");
      assert.equal(
        content.includes("DOKU_SECRET_KEY"),
        false,
        `File klien ${file} tidak boleh mereferensikan DOKU_SECRET_KEY`
      );
    }
  });
});
