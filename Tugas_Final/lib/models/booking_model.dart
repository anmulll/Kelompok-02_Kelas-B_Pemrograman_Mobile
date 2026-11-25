import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

enum BookingStatus {
  pendingPayment('pending_payment'),
  confirmed('confirmed'),
  paymentFailed('payment_failed'),
  expired('expired'),
  cancelled('cancelled'),
  completed('completed');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String? raw) {
    return BookingStatus.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => BookingStatus.pendingPayment,
    );
  }
}

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    required this.courtId,
    this.courtName,
    required this.slotId,
    required this.startAt,
    required this.endAt,
    required this.amount,
    this.currency = AppConstants.defaultCurrency,
    this.bookingStatus = BookingStatus.pendingPayment,
    this.paymentId,
    required this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.holdExpiresAt,
    this.cancelReason,
    this.refundStatus,
    this.reconciliationRequired = false,
    this.reconciliationReason,
  });

  final String id;
  final String userId;
  final String courtId;
  final String? courtName;
  final String slotId;
  final DateTime startAt;
  final DateTime endAt;
  final int amount;
  final String currency;
  final BookingStatus bookingStatus;
  final String? paymentId;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? holdExpiresAt;
  final String? cancelReason;
  final String? refundStatus;
  final bool reconciliationRequired;
  final String? reconciliationReason;

  bool get canRequestCancel =>
      bookingStatus == BookingStatus.pendingPayment ||
      bookingStatus == BookingStatus.confirmed;

  bool get canInviteFriends =>
      bookingStatus == BookingStatus.confirmed ||
      bookingStatus == BookingStatus.pendingPayment;

  BookingModel copyWith({
    BookingStatus? bookingStatus,
    String? paymentId,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? holdExpiresAt,
    String? cancelReason,
    String? refundStatus,
    bool? reconciliationRequired,
    String? reconciliationReason,
  }) {
    return BookingModel(
      id: id,
      userId: userId,
      courtId: courtId,
      courtName: courtName,
      slotId: slotId,
      startAt: startAt,
      endAt: endAt,
      amount: amount,
      currency: currency,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      paymentId: paymentId ?? this.paymentId,
      idempotencyKey: idempotencyKey,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      holdExpiresAt: holdExpiresAt ?? this.holdExpiresAt,
      cancelReason: cancelReason ?? this.cancelReason,
      refundStatus: refundStatus ?? this.refundStatus,
      reconciliationRequired:
          reconciliationRequired ?? this.reconciliationRequired,
      reconciliationReason: reconciliationReason ?? this.reconciliationReason,
    );
  }

  factory BookingModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return BookingModel(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      courtId: (map['courtId'] as String?) ?? '',
      courtName: map['courtName'] as String?,
      slotId: (map['slotId'] as String?) ?? '',
      startAt: _parseDateTime(map['startAt']),
      endAt: _parseDateTime(map['endAt']),
      amount: ((map['amount'] as num?) ?? 0).round(),
      currency: (map['currency'] as String?) ?? AppConstants.defaultCurrency,
      bookingStatus: BookingStatus.fromString(map['bookingStatus'] as String?),
      paymentId: map['paymentId'] as String?,
      idempotencyKey: (map['idempotencyKey'] as String?) ?? '',
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      confirmedAt: map['confirmedAt'] != null
          ? _parseDateTime(map['confirmedAt'])
          : null,
      holdExpiresAt: map['holdExpiresAt'] != null
          ? _parseDateTime(map['holdExpiresAt'])
          : null,
      cancelReason: map['cancelReason'] as String?,
      refundStatus: map['refundStatus'] as String?,
      reconciliationRequired: (map['reconciliationRequired'] as bool?) ?? false,
      reconciliationReason: map['reconciliationReason'] as String?,
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
