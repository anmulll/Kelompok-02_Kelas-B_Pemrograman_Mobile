import {
  BackendStore,
  BookingRecord,
  CourtRecord,
  NotificationRecord,
  PaymentEventRecord,
  PaymentRecord,
  SlotRecord,
  TransactionContext,
  UserRecord,
} from "../src/shared/store";

/**
 * In-memory store dengan serialisasi transaksi atomik & rollback saat error,
 * menyimulasikan perilaku optimistik/serializable Firestore Transaction untuk unit & concurrency test.
 */
export class InMemoryBackendStore implements BackendStore {
  users = new Map<string, UserRecord>();
  courts = new Map<string, CourtRecord>();
  slots = new Map<string, SlotRecord>();
  bookings = new Map<string, BookingRecord>();
  payments = new Map<string, PaymentRecord>();
  paymentEvents = new Map<string, PaymentEventRecord>();
  notifications: NotificationRecord[] = [];

  private seq = 1;
  private txQueue: Promise<unknown> = Promise.resolve();

  newId(collectionName: string): string {
    return `${collectionName}_${this.seq++}`;
  }

  async findPaymentIdByOrderId(providerOrderId: string): Promise<string | null> {
    for (const p of this.payments.values()) {
      if (p.providerOrderId === providerOrderId) return p.id;
    }
    return null;
  }

  async listExpiredHeldSlotIds(nowMs: number, limit: number): Promise<string[]> {
    const ids: string[] = [];
    for (const s of this.slots.values()) {
      if (s.status === "held" && s.holdExpiresAtMs !== null && s.holdExpiresAtMs <= nowMs) {
        ids.push(s.id);
        if (ids.length >= limit) break;
      }
    }
    return ids;
  }

  runTransaction<T>(fn: (tx: TransactionContext) => Promise<T>): Promise<T> {
    const next = this.txQueue.then(async () => {
      const stagedSlots = new Map<string, SlotRecord>();
      const stagedBookings = new Map<string, BookingRecord>();
      const stagedPayments = new Map<string, PaymentRecord>();
      const stagedEvents = new Map<string, PaymentEventRecord>();
      const stagedNotifications: NotificationRecord[] = [];

      const clone = <V>(v: V | undefined): V | null =>
        v === undefined ? null : structuredClone(v);

      const ctx: TransactionContext = {
        getUser: async (uid) => clone(this.users.get(uid)),
        getCourt: async (courtId) => clone(this.courts.get(courtId)),
        getSlot: async (slotId) =>
          clone(stagedSlots.get(slotId) ?? this.slots.get(slotId)),
        getBooking: async (bookingId) =>
          clone(stagedBookings.get(bookingId) ?? this.bookings.get(bookingId)),
        getPayment: async (paymentId) =>
          clone(stagedPayments.get(paymentId) ?? this.payments.get(paymentId)),
        getPaymentEvent: async (eventId) =>
          clone(stagedEvents.get(eventId) ?? this.paymentEvents.get(eventId)),
        saveSlot: (slot) => stagedSlots.set(slot.id, structuredClone(slot)),
        saveBooking: (booking) =>
          stagedBookings.set(booking.id, structuredClone(booking)),
        savePayment: (payment) =>
          stagedPayments.set(payment.id, structuredClone(payment)),
        savePaymentEvent: (event) =>
          stagedEvents.set(event.id, structuredClone(event)),
        createNotification: (notification) =>
          stagedNotifications.push(structuredClone(notification)),
      };

      const result = await fn(ctx);

      // Commit secara atomik hanya jika tidak terjadi exception
      for (const [k, v] of stagedSlots) this.slots.set(k, v);
      for (const [k, v] of stagedBookings) this.bookings.set(k, v);
      for (const [k, v] of stagedPayments) this.payments.set(k, v);
      for (const [k, v] of stagedEvents) this.paymentEvents.set(k, v);
      this.notifications.push(...stagedNotifications);

      return result;
    });

    this.txQueue = next.catch(() => undefined);
    return next;
  }
}
