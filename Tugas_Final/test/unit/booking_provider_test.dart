import 'package:courtmate/models/booking_model.dart';
import 'package:courtmate/models/invitation_model.dart';
import 'package:courtmate/models/payment_model.dart';
import 'package:courtmate/models/slot_model.dart';
import 'package:courtmate/providers/booking_provider.dart';
import 'package:courtmate/services/payment_service.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
