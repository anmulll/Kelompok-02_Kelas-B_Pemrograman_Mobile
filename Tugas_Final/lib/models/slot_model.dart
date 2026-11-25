import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

enum SlotStatus {
  available('available'),
  held('held'),
  booked('booked'),
  unavailable('unavailable');

  const SlotStatus(this.value);
  final String value;

  static SlotStatus fromString(String? raw) {
    return SlotStatus.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => SlotStatus.unavailable,
    );
  }
}

class SlotModel {
  const SlotModel({
    required this.id,
    required this.courtId,
    required this.startAt,
    required this.endAt,
    required this.price,
    this.currency = AppConstants.defaultCurrency,
    this.status = SlotStatus.available,
    this.bookingId,
    this.holdExpiresAt,
    required this.updatedAt,
  });

  final String id;
  final String courtId;
  final DateTime startAt;
  final DateTime endAt;
  final int price;
  final String currency;
  final SlotStatus status;
  final String? bookingId;
  final DateTime? holdExpiresAt;
  final DateTime updatedAt;

  /// Cek tampilan UI; validasi otoritatif tetap dilakukan di Cloud Functions (FR-009).
  bool isSelectableAt(DateTime now) {
    if (!endAt.isAfter(now)) return false;
    if (status == SlotStatus.available) return true;
    if (status == SlotStatus.held && holdExpiresAt != null) {
      return now.isAfter(holdExpiresAt!);
    }
    return false;
  }

  factory SlotModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return SlotModel(
      id: id,
      courtId: (map['courtId'] as String?) ?? '',
      startAt: _parseDateTime(map['startAt']),
      endAt: _parseDateTime(map['endAt']),
      price: ((map['price'] as num?) ?? 0).round(),
      currency: (map['currency'] as String?) ?? AppConstants.defaultCurrency,
      status: SlotStatus.fromString(map['status'] as String?),
      bookingId: map['bookingId'] as String?,
      holdExpiresAt: map['holdExpiresAt'] != null
          ? _parseDateTime(map['holdExpiresAt'])
          : null,
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
