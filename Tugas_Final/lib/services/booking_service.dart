import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../models/invitation_model.dart';
import '../models/slot_model.dart';

class CreateBookingResult {
  const CreateBookingResult({
    required this.bookingId,
    required this.bookingStatus,
    required this.amount,
    required this.currency,
    this.holdExpiresAt,
    this.idempotentReplay = false,
  });

  final String bookingId;
  final BookingStatus bookingStatus;
  final int amount;
  final String currency;
  final DateTime? holdExpiresAt;
  final bool idempotentReplay;

  factory CreateBookingResult.fromMap(Map<String, dynamic> map) {
    final holdRaw = map['holdExpiresAt'] as String?;
    return CreateBookingResult(
      bookingId: (map['bookingId'] as String?) ?? '',
      bookingStatus: BookingStatus.fromString(map['bookingStatus'] as String?),
      amount: ((map['amount'] as num?) ?? 0).round(),
      currency: (map['currency'] as String?) ?? AppConstants.defaultCurrency,
      holdExpiresAt: holdRaw != null ? DateTime.tryParse(holdRaw) : null,
      idempotentReplay: (map['idempotentReplay'] as bool?) ?? false,
    );
  }
}

class CancelBookingResult {
  const CancelBookingResult({
    required this.bookingId,
    required this.bookingStatus,
    this.refundStatus,
  });

  final String bookingId;
  final BookingStatus bookingStatus;
  final String? refundStatus;

  factory CancelBookingResult.fromMap(Map<String, dynamic> map) {
    return CancelBookingResult(
      bookingId: (map['bookingId'] as String?) ?? '',
      bookingStatus: BookingStatus.fromString(map['bookingStatus'] as String?),
      refundStatus: map['refundStatus'] as String?,
    );
  }
}

/// Modul Anmul Bab 5 & Bab 14 (`lib/services/booking_service.dart`):
/// Menyediakan antarmuka query slot (untuk koordinasi dengan modul Caca),
/// aksi callable `createBooking` & `cancelBooking`, serta stream riwayat,
/// undangan teman, dan notifikasi terkait booking.
class BookingService {
  BookingService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) {
    _firestore = firestore;
    _functions = functions;
  }

  late final FirebaseFirestore? _firestore;
  late final FirebaseFunctions? _functions;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;
  FirebaseFunctions get _fn => _functions ?? FirebaseFunctions.instance;

  /// Interface query slot berdasarkan `courtId` dan tanggal (Bab 14 koordinasi Caca).
  Stream<List<SlotModel>> watchSlotsForCourtAndDate({
    required String courtId,
    required DateTime date,
  }) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection(AppConstants.slotsCollection)
        .where('courtId', isEqualTo: courtId)
        .where(
          'startAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('startAt', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('startAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SlotModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Pembuatan hold & booking melalui Cloud Function `createBooking` (A-02, A-03).
  Future<CreateBookingResult> createBooking({
    required String courtId,
    required String slotId,
    required String idempotencyKey,
  }) async {
    final callable = _fn.httpsCallable(AppConstants.fnCreateBooking);
    final response = await callable.call<Map<dynamic, dynamic>>({
      'courtId': courtId,
      'slotId': slotId,
      'idempotencyKey': idempotencyKey,
    });
    return CreateBookingResult.fromMap(Map<String, dynamic>.from(response.data));
  }

  /// Pembatalan booking melalui Cloud Function `cancelBooking` (A-10).
  Future<CancelBookingResult> cancelBooking({
    required String bookingId,
    String? reason,
  }) async {
    final callable = _fn.httpsCallable(AppConstants.fnCancelBooking);
    final response = await callable.call<Map<dynamic, dynamic>>({
      'bookingId': bookingId,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    });
    return CancelBookingResult.fromMap(Map<String, dynamic>.from(response.data));
  }

  Stream<BookingModel?> watchBookingById(String bookingId) {
    return _db
        .collection(AppConstants.bookingsCollection)
        .doc(bookingId)
        .snapshots()
        .map((snap) {
          final data = snap.data();
          if (data == null) return null;
          return BookingModel.fromMap(data, id: snap.id);
        });
  }

  Stream<List<BookingModel>> watchUserBookings(String userId) {
    return _db
        .collection(AppConstants.bookingsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => BookingModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  /// Mengirim undangan teman bermain yang terhubung ke booking (A-11).
  Future<void> sendInvitation({
    required String bookingId,
    required String senderId,
    required String recipientEmail,
    String? senderName,
    String? courtName,
    String? scheduleLabel,
  }) async {
    await _db.collection(AppConstants.invitationsCollection).add({
      'bookingId': bookingId,
      'senderId': senderId,
      'senderName': senderName,
      'recipientIdentifier': recipientEmail.trim().toLowerCase(),
      'courtName': courtName,
      'scheduleLabel': scheduleLabel,
      'status': InvitationStatus.pending.value,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateInvitationStatus({
    required String invitationId,
    required InvitationStatus status,
  }) async {
    await _db
        .collection(AppConstants.invitationsCollection)
        .doc(invitationId)
        .update({'status': status.value});
  }

  Stream<List<InvitationModel>> watchReceivedInvitations(String email) {
    return _db
        .collection(AppConstants.invitationsCollection)
        .where('recipientIdentifier', isEqualTo: email.trim().toLowerCase())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<InvitationModel>> watchSentInvitations(String senderId) {
    return _db
        .collection(AppConstants.invitationsCollection)
        .where('senderId', isEqualTo: senderId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => InvitationModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return _db
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), id: doc.id))
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .update({'isRead': true});
  }
}
