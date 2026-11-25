import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

enum PaymentStatus {
  created('created'),
  pending('pending'),
  paid('paid'),
  failed('failed'),
  expired('expired'),
  cancelled('cancelled');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String? raw) {
    return PaymentStatus.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => PaymentStatus.created,
    );
  }
}

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.bookingId,
    required this.userId,
    this.provider = 'doku',
    required this.providerOrderId,
    required this.amount,
    this.currency = AppConstants.defaultCurrency,
    this.paymentStatus = PaymentStatus.created,
    required this.checkoutUrl,
    this.providerTransactionId,
    required this.createdAt,
    required this.updatedAt,
    this.paidAt,
  });

  final String id;
  final String bookingId;
  final String userId;
  final String provider;
  final String providerOrderId;
  final int amount;
  final String currency;
  final PaymentStatus paymentStatus;
  final String checkoutUrl;
  final String? providerTransactionId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? paidAt;

  factory PaymentModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return PaymentModel(
      id: id,
      bookingId: (map['bookingId'] as String?) ?? '',
      userId: (map['userId'] as String?) ?? '',
      provider: (map['provider'] as String?) ?? 'doku',
      providerOrderId: (map['providerOrderId'] as String?) ?? '',
      amount: ((map['amount'] as num?) ?? 0).round(),
      currency: (map['currency'] as String?) ?? AppConstants.defaultCurrency,
      paymentStatus: PaymentStatus.fromString(map['paymentStatus'] as String?),
      checkoutUrl: (map['checkoutUrl'] as String?) ?? '',
      providerTransactionId: map['providerTransactionId'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      paidAt: map['paidAt'] != null ? _parseDateTime(map['paidAt']) : null,
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
