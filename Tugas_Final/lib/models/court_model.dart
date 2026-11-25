import 'package:cloud_firestore/cloud_firestore.dart';

enum CourtVerificationStatus {
  pendingVerification('pending_verification'),
  verified('verified'),
  rejected('rejected');

  const CourtVerificationStatus(this.value);
  final String value;

  static CourtVerificationStatus fromString(String? raw) {
    return CourtVerificationStatus.values.firstWhere(
      (item) => item.value == raw,
      orElse: () => CourtVerificationStatus.pendingVerification,
    );
  }
}

class CourtModel {
  const CourtModel({
    required this.id,
    required this.name,
    this.placeId,
    required this.sportTypes,
    required this.addressDisplay,
    required this.latitude,
    required this.longitude,
    this.priceRules = const {},
    this.facilities = const [],
    this.openingHours = const {},
    required this.ownerId,
    this.verificationStatus = CourtVerificationStatus.pendingVerification,
    this.isActive = true,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? placeId;
  final List<String> sportTypes;
  final String addressDisplay;
  final double latitude;
  final double longitude;
  final Map<String, dynamic> priceRules;
  final List<String> facilities;
  final Map<String, dynamic> openingHours;
  final String ownerId;
  final CourtVerificationStatus verificationStatus;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// BR-003: Hanya lapangan aktif dan terverifikasi yang dapat dipesan.
  bool get canBeBooked =>
      isActive && verificationStatus == CourtVerificationStatus.verified;

  /// FR-006: Menandai hasil penemuan Google Places yang belum terdaftar di CourtMate.
  bool get isGooglePlaceOnly => !canBeBooked;

  /// Mengambil harga terendah per jam dari `priceRules` pengelola (jika tersedia).
  int? get startingHourlyPrice {
    if (priceRules.isEmpty) return null;
    int? minPrice;
    for (final value in priceRules.values) {
      if (value is num && value > 0) {
        final candidate = value.round();
        if (minPrice == null || candidate < minPrice) {
          minPrice = candidate;
        }
      }
    }
    return minPrice;
  }

  /// Menampilkan jam operasional dari `openingHours` pengelola.
  String get openingHoursLabel {
    final display = openingHours['display'] as String?;
    if (display != null && display.trim().isNotEmpty) return display.trim();

    final open = openingHours['open'] as String?;
    final close = openingHours['close'] as String?;
    if (open != null && close != null && open.isNotEmpty && close.isNotEmpty) {
      return '$open – $close WIB';
    }
    return 'Sesuai jadwal pengelola';
  }

  /// Menampilkan hari buka dari `openingHours` pengelola.
  String get openDaysLabel {
    final days = openingHours['days'];
    if (days is String && days.trim().isNotEmpty) return days.trim();
    if (days is List && days.isNotEmpty) return days.join(', ');
    return 'Senin – Minggu';
  }

  factory CourtModel.fromMap(Map<String, dynamic> map, {required String id}) {
    return CourtModel(
      id: id,
      name: (map['name'] as String?) ?? '',
      placeId: map['placeId'] as String?,
      sportTypes: List<String>.from((map['sportTypes'] as List?) ?? const []),
      addressDisplay: (map['addressDisplay'] as String?) ?? '',
      latitude: ((map['latitude'] as num?) ?? 0).toDouble(),
      longitude: ((map['longitude'] as num?) ?? 0).toDouble(),
      priceRules: Map<String, dynamic>.from(
        (map['priceRules'] as Map?) ?? const {},
      ),
      facilities: List<String>.from((map['facilities'] as List?) ?? const []),
      openingHours: Map<String, dynamic>.from(
        (map['openingHours'] as Map?) ?? const {},
      ),
      ownerId: (map['ownerId'] as String?) ?? '',
      verificationStatus: CourtVerificationStatus.fromString(
        map['verificationStatus'] as String?,
      ),
      isActive: (map['isActive'] as bool?) ?? false,
      imageUrl: map['imageUrl'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
