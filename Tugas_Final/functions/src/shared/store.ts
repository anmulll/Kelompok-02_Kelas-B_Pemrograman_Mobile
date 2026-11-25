import * as admin from "firebase-admin";
import { Timestamp } from "firebase-admin/firestore";

export type SlotStatus = "available" | "held" | "booked" | "unavailable";
export type BookingStatus =
  | "pending_payment"
  | "confirmed"
  | "payment_failed"
  | "expired"
  | "cancelled"
  | "completed";
export type PaymentStatus =
  | "created"
  | "pending"
  | "paid"
  | "failed"
  | "expired"
  | "cancelled";

export interface UserRecord {
  uid: string;
  role: string;
  isActive: boolean;
  name?: string;
  email?: string;
}

export interface CourtRecord {
  id: string;
  name: string;
  isActive: boolean;
  verificationStatus: string;
  ownerId: string;
}

export interface SlotRecord {
  id: string;
  courtId: string;
  startAtMs: number;
  endAtMs: number;
  price: number;
  currency: string;
  status: SlotStatus;
  bookingId: string | null;
  holdExpiresAtMs: number | null;
  updatedAtMs: number;
}

export interface BookingRecord {
  id: string;
  userId: string;
  courtId: string;
  slotId: string;
  startAtMs: number;
  endAtMs: number;
  amount: number;
  currency: string;
  bookingStatus: BookingStatus;
  paymentId: string | null;
  idempotencyKey: string;
  createdAtMs: number;
  updatedAtMs: number;
  confirmedAtMs: number | null;
  cancelReason?: string | null;
  refundStatus?: string | null;
  reconciliationRequired?: boolean;
  reconciliationReason?: string | null;
}

export interface PaymentRecord {
  id: string;
  bookingId: string;
  userId: string;
  provider: "doku";
  providerOrderId: string;
  amount: number;
  currency: string;
  paymentStatus: PaymentStatus;
  checkoutUrl: string;
  providerTransactionId: string | null;
  createdAtMs: number;
  updatedAtMs: number;
  paidAtMs: number | null;
}

export interface PaymentEventRecord {
  id: string;
  providerOrderId: string;
  bookingId: string;
  status: string;
  outcome: string;
  processedAtMs: number;
}

export interface NotificationRecord {
  userId: string;
  title: string;
  body: string;
  type: string;
  isRead: boolean;
  createdAtMs: number;
  relatedId: string | null;
}

export interface TransactionContext {
  getUser(uid: string): Promise<UserRecord | null>;
  getCourt(courtId: string): Promise<CourtRecord | null>;
  getSlot(slotId: string): Promise<SlotRecord | null>;
  getBooking(bookingId: string): Promise<BookingRecord | null>;
  getPayment(paymentId: string): Promise<PaymentRecord | null>;
  getPaymentEvent(eventId: string): Promise<PaymentEventRecord | null>;

  saveSlot(slot: SlotRecord): void;
  saveBooking(booking: BookingRecord): void;
  savePayment(payment: PaymentRecord): void;
  savePaymentEvent(event: PaymentEventRecord): void;
  createNotification(notification: NotificationRecord): void;
}

export interface BackendStore {
  newId(collectionName: string): string;
  findPaymentIdByOrderId(providerOrderId: string): Promise<string | null>;
  listExpiredHeldSlotIds(nowMs: number, limit: number): Promise<string[]>;
  runTransaction<T>(fn: (tx: TransactionContext) => Promise<T>): Promise<T>;
}

function toMs(val: unknown): number {
  if (val && typeof (val as Timestamp).toMillis === "function") {
    return (val as Timestamp).toMillis();
  }
  if (val instanceof Date) return val.getTime();
  if (typeof val === "number") return val;
  return 0;
}

function toTs(ms: number | null | undefined): Timestamp | null {
  if (ms === null || ms === undefined) return null;
  return Timestamp.fromMillis(ms);
}

export class FirestoreBackendStore implements BackendStore {
  constructor(private readonly db: admin.firestore.Firestore = admin.firestore()) {}

  newId(collectionName: string): string {
    return this.db.collection(collectionName).doc().id;
  }

  async findPaymentIdByOrderId(providerOrderId: string): Promise<string | null> {
    const snap = await this.db
      .collection("payments")
      .where("providerOrderId", "==", providerOrderId)
      .limit(1)
      .get();
    if (snap.empty) return null;
    return snap.docs[0].id;
  }

  async listExpiredHeldSlotIds(nowMs: number, limit: number): Promise<string[]> {
    const snap = await this.db
      .collection("slots")
      .where("status", "==", "held")
      .where("holdExpiresAt", "<=", Timestamp.fromMillis(nowMs))
      .limit(limit)
      .get();
    return snap.docs.map((d) => d.id);
  }

  runTransaction<T>(fn: (tx: TransactionContext) => Promise<T>): Promise<T> {
    return this.db.runTransaction(async (fsTx) => {
      const ctx: TransactionContext = {
        getUser: async (uid) => {
          const snap = await fsTx.get(this.db.collection("users").doc(uid));
          if (!snap.exists) return null;
          const d = snap.data()!;
          return {
            uid,
            role: String(d.role ?? "student"),
            isActive: d.isActive !== false,
            name: d.name ? String(d.name) : undefined,
            email: d.email ? String(d.email) : undefined,
          };
        },
        getCourt: async (courtId) => {
          const snap = await fsTx.get(this.db.collection("courts").doc(courtId));
          if (!snap.exists) return null;
          const d = snap.data()!;
          return {
            id: snap.id,
            name: String(d.name ?? ""),
            isActive: Boolean(d.isActive),
            verificationStatus: String(d.verificationStatus ?? ""),
            ownerId: String(d.ownerId ?? ""),
          };
        },
        getSlot: async (slotId) => {
          const snap = await fsTx.get(this.db.collection("slots").doc(slotId));
          if (!snap.exists) return null;
          const d = snap.data()!;
          return {
            id: snap.id,
            courtId: String(d.courtId ?? ""),
            startAtMs: toMs(d.startAt),
            endAtMs: toMs(d.endAt),
            price: Math.round(Number(d.price ?? 0)),
            currency: String(d.currency ?? "IDR"),
            status: (d.status as SlotStatus) ?? "unavailable",
            bookingId: (d.bookingId as string | null) ?? null,
            holdExpiresAtMs: d.holdExpiresAt ? toMs(d.holdExpiresAt) : null,
            updatedAtMs: toMs(d.updatedAt),
          };
        },
        getBooking: async (bookingId) => {
          const snap = await fsTx.get(this.db.collection("bookings").doc(bookingId));
          if (!snap.exists) return null;
          const d = snap.data()!;
          return {
            id: snap.id,
            userId: String(d.userId ?? ""),
            courtId: String(d.courtId ?? ""),
            slotId: String(d.slotId ?? ""),
            startAtMs: toMs(d.startAt),
            endAtMs: toMs(d.endAt),
            amount: Math.round(Number(d.amount ?? 0)),
            currency: String(d.currency ?? "IDR"),
            bookingStatus: (d.bookingStatus as BookingStatus) ?? "pending_payment",
            paymentId: (d.paymentId as string | null) ?? null,
            idempotencyKey: String(d.idempotencyKey ?? ""),
            createdAtMs: toMs(d.createdAt),
            updatedAtMs: toMs(d.updatedAt),
            confirmedAtMs: d.confirmedAt ? toMs(d.confirmedAt) : null,
            cancelReason: (d.cancelReason as string | null) ?? null,
            refundStatus: (d.refundStatus as string | null) ?? null,
            reconciliationRequired: Boolean(d.reconciliationRequired ?? false),
            reconciliationReason: (d.reconciliationReason as string | null) ?? null,
          };
        },
        getPayment: async (paymentId) => {
          const snap = await fsTx.get(this.db.collection("payments").doc(paymentId));
          if (!snap.exists) return null;
          const d = snap.data()!;
          return {
            id: snap.id,
            bookingId: String(d.bookingId ?? ""),
            userId: String(d.userId ?? ""),
            provider: "doku",
            providerOrderId: String(d.providerOrderId ?? ""),
            amount: Math.round(Number(d.amount ?? 0)),
            currency: String(d.currency ?? "IDR"),
            paymentStatus: (d.paymentStatus as PaymentStatus) ?? "created",
            checkoutUrl: String(d.checkoutUrl ?? ""),
            providerTransactionId: (d.providerTransactionId as string | null) ?? null,
            createdAtMs: toMs(d.createdAt),
            updatedAtMs: toMs(d.updatedAt),
            paidAtMs: d.paidAt ? toMs(d.paidAt) : null,
          };
        },
        getPaymentEvent: async (eventId) => {
          const snap = await fsTx.get(this.db.collection("payment_events").doc(eventId));
          if (!snap.exists) return null;
          const d = snap.data()!;
          return {
            id: snap.id,
            providerOrderId: String(d.providerOrderId ?? ""),
            bookingId: String(d.bookingId ?? ""),
            status: String(d.status ?? ""),
            outcome: String(d.outcome ?? ""),
            processedAtMs: toMs(d.processedAt),
          };
        },
        saveSlot: (slot) => {
          fsTx.set(
            this.db.collection("slots").doc(slot.id),
            {
              courtId: slot.courtId,
              startAt: toTs(slot.startAtMs),
              endAt: toTs(slot.endAtMs),
              price: slot.price,
              currency: slot.currency,
              status: slot.status,
              bookingId: slot.bookingId,
              holdExpiresAt: toTs(slot.holdExpiresAtMs),
              updatedAt: toTs(slot.updatedAtMs),
            },
            { merge: true }
          );
        },
        saveBooking: (booking) => {
          fsTx.set(
            this.db.collection("bookings").doc(booking.id),
            {
              userId: booking.userId,
              courtId: booking.courtId,
              slotId: booking.slotId,
              startAt: toTs(booking.startAtMs),
              endAt: toTs(booking.endAtMs),
              amount: booking.amount,
              currency: booking.currency,
              bookingStatus: booking.bookingStatus,
              paymentId: booking.paymentId,
              idempotencyKey: booking.idempotencyKey,
              createdAt: toTs(booking.createdAtMs),
              updatedAt: toTs(booking.updatedAtMs),
              confirmedAt: toTs(booking.confirmedAtMs),
              cancelReason: booking.cancelReason ?? null,
              refundStatus: booking.refundStatus ?? null,
              reconciliationRequired: booking.reconciliationRequired ?? false,
              reconciliationReason: booking.reconciliationReason ?? null,
            },
            { merge: true }
          );
        },
        savePayment: (payment) => {
          fsTx.set(
            this.db.collection("payments").doc(payment.id),
            {
              bookingId: payment.bookingId,
              userId: payment.userId,
              provider: payment.provider,
              providerOrderId: payment.providerOrderId,
              amount: payment.amount,
              currency: payment.currency,
              paymentStatus: payment.paymentStatus,
              checkoutUrl: payment.checkoutUrl,
              providerTransactionId: payment.providerTransactionId,
              createdAt: toTs(payment.createdAtMs),
              updatedAt: toTs(payment.updatedAtMs),
              paidAt: toTs(payment.paidAtMs),
            },
            { merge: true }
          );
        },
        savePaymentEvent: (event) => {
          fsTx.set(this.db.collection("payment_events").doc(event.id), {
            providerOrderId: event.providerOrderId,
            bookingId: event.bookingId,
            status: event.status,
            outcome: event.outcome,
            processedAt: toTs(event.processedAtMs),
          });
        },
        createNotification: (notification) => {
          const ref = this.db.collection("notifications").doc();
          fsTx.set(ref, {
            userId: notification.userId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            isRead: notification.isRead,
            createdAt: toTs(notification.createdAtMs),
            relatedId: notification.relatedId,
          });
        },
      };

      return fn(ctx);
    });
  }
}
