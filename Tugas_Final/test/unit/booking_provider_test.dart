import 'dart:async';
import 'package:courtmate/models/booking_model.dart';
import 'package:courtmate/models/invitation_model.dart';
import 'package:courtmate/models/payment_model.dart';
import 'package:courtmate/models/slot_model.dart';
import 'package:courtmate/providers/booking_provider.dart';
import 'package:courtmate/services/booking_service.dart';
import 'package:courtmate/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCloudBookingService extends BookingService {
  final bookingsCtrl = StreamController<List<BookingModel>>.broadcast();
  final activeBookingCtrl = StreamController<BookingModel?>.broadcast();
  final receivedInvCtrl = StreamController<List<InvitationModel>>.broadcast();
  final sentInvCtrl = StreamController<List<InvitationModel>>.broadcast();
  final notifCtrl = StreamController<List<NotificationModel>>.broadcast();

  @override
  Stream<List<BookingModel>> watchUserBookings(String userId) =>
      bookingsCtrl.stream;

  @override
  Stream<BookingModel?> watchBookingById(String bookingId) =>
      activeBookingCtrl.stream;

  @override
  Stream<List<InvitationModel>> watchReceivedInvitations(String email) =>
      receivedInvCtrl.stream;

  @override
  Stream<List<InvitationModel>> watchSentInvitations(String senderId) =>
      sentInvCtrl.stream;

  @override
  Stream<List<NotificationModel>> watchUserNotifications(String userId) =>
      notifCtrl.stream;

  Future<void> closeAll() async {
    await bookingsCtrl.close();
    await activeBookingCtrl.close();
    await receivedInvCtrl.close();
    await sentInvCtrl.close();
    await notifCtrl.close();
  }
}

class _FakeCloudPaymentService extends PaymentService {
  final paymentCtrl = StreamController<PaymentModel?>.broadcast();

  @override
  Stream<PaymentModel?> watchPaymentById(String paymentId) =>
      paymentCtrl.stream;

  Future<void> closeAll() => paymentCtrl.close();
}

void main() {
  group('BookingProvider — Modul Anmul (Booking, Payment AT-11, Cancel, Invitation)', () {
    late Uri? lastLaunchedUri;
    late BookingProvider provider;

    setUp(() {
      lastLaunchedUri = null;
      final paymentService = PaymentService(
        urlLauncher: (uri) async {
          lastLaunchedUri = uri;
          return true;
        },
      );
      provider = BookingProvider(
        paymentService: paymentService,
        useLocalSandbox: true,
      );
      // Pilih besok agar seluruh slot pagi s.d. malam berada di masa depan
      provider.selectDate(DateTime.now().add(const Duration(days: 1)));
    });

    tearDown(() {
      provider.dispose();
    });

    test('AT-01, AT-05 & AT-11: Hold slot membuat paymentUrl dan redirect browser tidak auto-confirm', () async {
      final availableSlot = provider.slots.firstWhere(
        (s) => s.status == SlotStatus.available,
      );
      provider.selectSlot(availableSlot);
      expect(provider.selectedSlotId, availableSlot.id);

      final session = await provider.createHoldAndPayment(userId: 'mhs_anmul');
      expect(session, isNotNull);
      expect(session!.paymentUrl, startsWith('https://sandbox.doku.com/'));
      expect(provider.activeBooking?.bookingStatus, BookingStatus.pendingPayment);

      // Pengguna membuka browser checkout DOKU lalu kembali ke aplikasi (AT-11)
      final opened = await provider.openActiveCheckoutUrl();
      expect(opened, isTrue);
      expect(lastLaunchedUri.toString(), session.paymentUrl);
      expect(provider.hasOpenedCheckoutBrowser, isTrue);
      // AT-11: Status booking WAJIB tetap pendingPayment sebelum webhook server masuk!
      expect(provider.activeBooking?.bookingStatus, BookingStatus.pendingPayment);

      // Setelah webhook server SUCCESS masuk, barulah status menjadi confirmed (AT-06)
      provider.simulateServerWebhookInSandbox(
        bookingId: provider.activeBooking!.id,
        webhookPaymentStatus: PaymentStatus.paid,
      );
      expect(provider.activeBooking?.bookingStatus, BookingStatus.confirmed);
    });

    test('AT-02: Memilih slot yang sudah booked atau held ditolak', () {
      final bookedSlot = provider.slots.firstWhere(
        (s) => s.status == SlotStatus.booked,
      );
      provider.selectSlot(bookedSlot);
      expect(provider.selectedSlotId, isNull);
      expect(provider.errorMessage, isNotNull);
    });

    test('A-10: Pembatalan booking confirmed menandai manual_review_required tanpa auto-refund', () async {
      final confirmedBooking = provider.bookings.firstWhere(
        (b) => b.bookingStatus == BookingStatus.confirmed,
      );

      final ok = await provider.cancelBooking(
        bookingId: confirmedBooking.id,
        reason: 'Hujan deras / jadwal ujian',
      );
      expect(ok, isTrue);

      final updated = provider.bookings.firstWhere(
        (b) => b.id == confirmedBooking.id,
      );
      expect(updated.bookingStatus, BookingStatus.cancelled);
      expect(updated.refundStatus, 'manual_review_required');
    });

    test('A-11: Pengiriman undangan teman, respon undangan masuk, dan baca notifikasi', () async {
      final activeBooking = provider.invitableBookings.first;

      final sent = await provider.sendInvitation(
        bookingId: activeBooking.id,
        recipientEmail: 'yusuf@kampus.ac.id',
      );
      expect(sent, isTrue);
      expect(provider.sentInvitations.length, 1);
      expect(provider.sentInvitations.first.recipientIdentifier, 'yusuf@kampus.ac.id');

      final incomingId = provider.receivedInvitations.first.id;
      await provider.respondToInvitation(
        invitationId: incomingId,
        decision: InvitationStatus.accepted,
      );
      expect(
        provider.receivedInvitations.first.status,
        InvitationStatus.accepted,
      );

      final unreadBefore = provider.unreadNotificationCount;
      expect(unreadBefore, greaterThan(0));
      await provider.markNotificationRead(provider.notifications.first.id);
      expect(provider.unreadNotificationCount, unreadBefore - 1);
    });
  });

  test(
    'Live Cloud Mode: bindUserStreams & setActiveBooking menerima pembaruan real-time Firestore',
    () async {
      final fakeBookingSvc = _FakeCloudBookingService();
      final fakePaymentSvc = _FakeCloudPaymentService();
      final liveProvider = BookingProvider(
        bookingService: fakeBookingSvc,
        paymentService: fakePaymentSvc,
        useLocalSandbox: false,
      );

      final now = DateTime(2026, 11, 25, 19);
      liveProvider.bindUserStreams('uid_anmul', email: 'anmul@kampus.ac.id');
      liveProvider.setActiveBooking('bk_live_1');

      fakeBookingSvc.receivedInvCtrl.add([
        InvitationModel(
          id: 'inv_live_1',
          bookingId: 'bk_caca',
          senderId: 'uid_caca',
          recipientIdentifier: 'anmul@kampus.ac.id',
          createdAt: now,
        ),
      ]);
      fakeBookingSvc.notifCtrl.add([
        NotificationModel(
          id: 'notif_live_1',
          userId: 'uid_anmul',
          title: 'Booking Terkonfirmasi',
          body: 'Webhook DOKU sukses.',
          type: 'booking_confirmed',
          createdAt: now,
        ),
      ]);
      fakeBookingSvc.activeBookingCtrl.add(
        BookingModel(
          id: 'bk_live_1',
          userId: 'uid_anmul',
          courtId: 'court_1',
          slotId: 'slot_1',
          startAt: now,
          endAt: now.add(const Duration(hours: 1)),
          amount: 150000,
          bookingStatus: BookingStatus.confirmed,
          paymentId: 'pay_live_1',
          idempotencyKey: 'idem_live',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      fakePaymentSvc.paymentCtrl.add(
        PaymentModel(
          id: 'pay_live_1',
          bookingId: 'bk_live_1',
          userId: 'uid_anmul',
          providerOrderId: 'CM-LIVE-001',
          amount: 150000,
          paymentStatus: PaymentStatus.paid,
          checkoutUrl: 'https://sandbox.doku.com/checkout/CM-LIVE-001',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(liveProvider.receivedInvitations.length, 1);
      expect(liveProvider.unreadNotificationCount, 1);
      expect(liveProvider.activeBooking?.bookingStatus, BookingStatus.confirmed);
      expect(liveProvider.activePayment?.paymentStatus, PaymentStatus.paid);

      liveProvider.unbindUserStreams();
      liveProvider.dispose();
      await fakeBookingSvc.closeAll();
      await fakePaymentSvc.closeAll();
    },
  );
}
