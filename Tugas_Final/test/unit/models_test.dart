import 'package:courtmate/models/booking_model.dart';
import 'package:courtmate/models/court_model.dart';
import 'package:courtmate/models/slot_model.dart';
import 'package:courtmate/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Aturan Bisnis Model CourtMate', () {
    test('BR-002: role tidak dikenal default menjadi student', () {
      final user = UserModel.fromMap({
        'uid': 'u1',
        'name': 'Budi',
        'email': 'budi@kampus.ac.id',
        'role': 'unknown_role',
      });

      expect(user.role, UserRole.student);
      expect(user.isAdmin, isFalse);
    });

    test('BR-003: hanya lapangan aktif dan terverifikasi yang dapat dipesan', () {
      final now = DateTime(2026, 11, 25, 10);
      final verifiedCourt = CourtModel(
        id: 'c1',
        name: 'GOR Kampus',
        sportTypes: const ['Futsal'],
        addressDisplay: 'Jl. Kampus No. 1',
        latitude: -5.13,
        longitude: 119.48,
        ownerId: 'admin1',
        verificationStatus: CourtVerificationStatus.verified,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      final unverifiedCourt = CourtModel(
        id: 'c2',
        name: 'Lapangan Umum Maps',
        sportTypes: const ['Futsal'],
        addressDisplay: 'Jl. Umum No. 2',
        latitude: -5.14,
        longitude: 119.49,
        ownerId: 'admin1',
        verificationStatus: CourtVerificationStatus.pendingVerification,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(verifiedCourt.canBeBooked, isTrue);
      expect(unverifiedCourt.canBeBooked, isFalse);
    });

    test('FR-010: slot held tidak bisa dipilih sebelum holdExpiresAt lewat', () {
      final now = DateTime(2026, 11, 25, 12, 0);
      final activeHoldSlot = SlotModel(
        id: 's1',
        courtId: 'c1',
        startAt: DateTime(2026, 11, 25, 15, 0),
        endAt: DateTime(2026, 11, 25, 16, 0),
        price: 120000,
        status: SlotStatus.held,
        holdExpiresAt: DateTime(2026, 11, 25, 12, 10),
        updatedAt: now,
      );

      final expiredHoldSlot = SlotModel(
        id: 's2',
        courtId: 'c1',
        startAt: DateTime(2026, 11, 25, 16, 0),
        endAt: DateTime(2026, 11, 25, 17, 0),
        price: 120000,
        status: SlotStatus.held,
        holdExpiresAt: DateTime(2026, 11, 25, 11, 55),
        updatedAt: now,
      );

      expect(activeHoldSlot.isSelectableAt(now), isFalse);
      expect(expiredHoldSlot.isSelectableAt(now), isTrue);
    });

    test('BookingStatus parsing sesuai skema Firestore', () {
      final booking = BookingModel.fromMap({
        'userId': 'u1',
        'courtId': 'c1',
        'slotId': 's1',
        'amount': 150000,
        'bookingStatus': 'pending_payment',
        'idempotencyKey': 'idem-123',
      }, id: 'b1');

      expect(booking.bookingStatus, BookingStatus.pendingPayment);
      expect(booking.canRequestCancel, isTrue);
    });
  });
}
