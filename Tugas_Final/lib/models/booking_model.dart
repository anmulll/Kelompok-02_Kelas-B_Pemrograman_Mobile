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
  });

  final String id;
  final String userId;
  final String courtId;
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

  bool get canRequestCancel =>
      bookingStatus == BookingStatus.pendingPayment ||
      bookingStatus == BookingStatus.confirmed;

  factory BookingModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return BookingModel(
      id: id,
      userId: (map['userId'] as String?) ?? '',
      courtId: (map['courtId'] as String?) ?? '',
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
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
