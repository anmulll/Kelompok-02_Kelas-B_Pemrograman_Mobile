class AppConstants {
  AppConstants._();

  static const String appName = 'CourtMate';
  static const String defaultCurrency = 'IDR';

  /// Usulan baseline masa hold slot (10 menit), diselaraskan dengan expiry DOKU.
  static const int defaultSlotHoldMinutes = 10;

  // Firestore Collections (CM-ARCH-DB-001 Bab 7)
  static const String usersCollection = 'users';
  static const String courtsCollection = 'courts';
  static const String slotsCollection = 'slots';
  static const String bookingsCollection = 'bookings';
  static const String paymentsCollection = 'payments';
  static const String invitationsCollection = 'invitations';
  static const String notificationsCollection = 'notifications';

  // Cloud Functions Callables (CM-ARCH-DB-001 Bab 5)
  static const String fnCreateBooking = 'createBooking';
  static const String fnCreateDokuPayment = 'createDokuPayment';
  static const String fnCancelBooking = 'cancelBooking';
  static const String fnManageCourt = 'manageCourt';
}
