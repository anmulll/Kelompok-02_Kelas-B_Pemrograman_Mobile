import '../models/court_model.dart';
import '../models/slot_model.dart';
import 'firebase_bootstrap.dart';
import 'firestore_service.dart';
import 'places_service.dart';

class CourtRepository {
  CourtRepository({
    FirestoreService? firestoreService,
    PlacesService? placesService,
    bool? useDemoFallbackWhenOffline,
  }) : _firestoreService = firestoreService ?? FirestoreService(),
       _placesService = placesService ?? PlacesService(),
       _useDemoFallbackWhenOffline =
           useDemoFallbackWhenOffline ?? !FirebaseBootstrap.isInitialized;

  final FirestoreService _firestoreService;
  final PlacesService _placesService;
  final bool _useDemoFallbackWhenOffline;

  bool get _shouldUseDemoData => _useDemoFallbackWhenOffline;

  /// Mengamati daftar lapangan aktif & terverifikasi dari Cloud Firestore (C-07).
  Stream<List<CourtModel>> watchVerifiedCourts({String? sportType}) {
    if (_shouldUseDemoData) {
      final list = demoCourts.where((court) {
        if (!court.canBeBooked) return false;
        if (sportType != null && sportType.isNotEmpty) {
          return court.sportTypes.any(
            (s) => s.toLowerCase() == sportType.toLowerCase(),
          );
        }
        return true;
      }).toList();
      return Stream.value(list);
    }
    return _firestoreService.watchVerifiedCourts(sportType: sportType);
  }

  /// Mengamati daftar slot dari kontrak backend Anmul berdasarkan tanggal (C-08, FR-008).
  Stream<List<SlotModel>> watchCourtSlotsForDate({
    required String courtId,
    required DateTime date,
  }) {
    if (_shouldUseDemoData) {
      return Stream.value(demoSlotsForDate(courtId: courtId, date: date));
    }
    return _firestoreService.watchCourtSlotsForDate(
      courtId: courtId,
      date: date,
    );
  }

  /// Mencari tempat olahraga umum dari Google Places API (C-03, FR-004).
  /// Hasil tidak pernah otomatis dianggap terdaftar di CourtMate (FR-006).
  Future<List<CourtModel>> searchGooglePlaces({
    required String query,
    double? latitude,
    double? longitude,
  }) async {
    if (_shouldUseDemoData && !_placesService.isConfigured) {
      final q = query.trim().toLowerCase();
      return demoPlacesOnly.where((place) {
        if (q.isEmpty) return true;
        return place.name.toLowerCase().contains(q) ||
            place.addressDisplay.toLowerCase().contains(q) ||
            place.sportTypes.any((s) => s.toLowerCase().contains(q));
      }).toList();
    }
    return _placesService.searchSportsPlaces(
      query: query,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// Menggabungkan hasil CourtMate terverifikasi dengan hasil Google Places
  /// tanpa menduplikasi tempat yang sudah terdaftar lewat `placeId`.
  List<CourtModel> mergeVerifiedAndPlaces({
    required List<CourtModel> verifiedCourts,
    required List<CourtModel> placesResults,
  }) {
    final registeredPlaceIds = verifiedCourts
        .map((c) => c.placeId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final uniquePlaces = placesResults.where((place) {
      final pid = place.placeId;
      if (pid == null || pid.isEmpty) return true;
      return !registeredPlaceIds.contains(pid);
    });

    return [...verifiedCourts, ...uniquePlaces];
  }

  static final DateTime _demoTime = DateTime(2026, 11, 25, 8);

  static final List<CourtModel> demoCourts = [
    CourtModel(
      id: 'court-futsal-merdeka',
      name: 'Arena Futsal Kampus Merdeka',
      placeId: 'ChIJ_demo_futsal_merdeka',
      sportTypes: const ['Futsal'],
      addressDisplay:
          'Jl. Telekomunikasi No. 12, Sukapura, Kec. Dayeuhkolot, Bandung',
      latitude: -6.9735,
      longitude: 107.6309,
      priceRules: const {'hourly': 120000},
      facilities: const ['Parkir', 'Mushola', 'Toilet', 'Kantin', 'Wi-Fi'],
      openingHours: const {'open': '07:00', 'close': '23:00', 'days': 'Senin – Minggu'},
      ownerId: 'admin-demo-1',
      verificationStatus: CourtVerificationStatus.verified,
      isActive: true,
      createdAt: _demoTime,
      updatedAt: _demoTime,
    ),
    CourtModel(
      id: 'court-badminton-nusantara',
      name: 'GOR Badminton Nusantara',
      placeId: 'ChIJ_demo_badminton_nusantara',
      sportTypes: const ['Badminton'],
      addressDisplay: 'Jl. Bojongsoang Raya No. 45, Bandung',
      latitude: -6.9810,
      longitude: 107.6375,
      priceRules: const {'hourly': 65000},
      facilities: const ['Parkir', 'Toilet', 'Kantin', 'Sewa Raket'],
      openingHours: const {'open': '06:00', 'close': '22:00', 'days': 'Senin – Minggu'},
      ownerId: 'admin-demo-2',
      verificationStatus: CourtVerificationStatus.verified,
      isActive: true,
      createdAt: _demoTime,
      updatedAt: _demoTime,
    ),
    CourtModel(
      id: 'court-tenis-senayan',
      name: 'Tenis Club Kampus',
      placeId: 'ChIJ_demo_tenis_senayan',
      sportTypes: const ['Tenis'],
      addressDisplay: 'Jl. Buah Batu No. 118, Bandung',
      latitude: -6.9552,
      longitude: 107.6412,
      priceRules: const {'hourly': 150000},
      facilities: const ['Parkir', 'Toilet', 'Ruang Ganti', 'Lampu Malam'],
      openingHours: const {'open': '06:00', 'close': '21:00', 'days': 'Senin – Minggu'},
      ownerId: 'admin-demo-3',
      verificationStatus: CourtVerificationStatus.verified,
      isActive: true,
      createdAt: _demoTime,
      updatedAt: _demoTime,
    ),
  ];

  static final List<CourtModel> demoPlacesOnly = [
    CourtModel(
      id: 'places_demo_basket_taman',
      name: 'Lapangan Basket Taman Kota',
      placeId: 'ChIJ_demo_basket_taman',
      sportTypes: const ['Basket'],
      addressDisplay: 'Kawasan Taman Kota, Bandung',
      latitude: -6.9688,
      longitude: 107.6218,
      ownerId: '',
      verificationStatus: CourtVerificationStatus.pendingVerification,
      isActive: false,
      createdAt: _demoTime,
      updatedAt: _demoTime,
    ),
  ];

  static List<SlotModel> demoSlotsForDate({
    required String courtId,
    required DateTime date,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final basePrice = courtId.contains('badminton')
        ? 65000
        : courtId.contains('tenis')
            ? 150000
            : 120000;

    return [
      SlotModel(
        id: '${courtId}_${day.day}_08',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 8)),
        endAt: day.add(const Duration(hours: 9)),
        price: basePrice,
        status: SlotStatus.unavailable,
        updatedAt: _demoTime,
      ),
      SlotModel(
        id: '${courtId}_${day.day}_09',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 9)),
        endAt: day.add(const Duration(hours: 10)),
        price: basePrice,
        status: SlotStatus.booked,
        updatedAt: _demoTime,
      ),
      SlotModel(
        id: '${courtId}_${day.day}_10',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 10)),
        endAt: day.add(const Duration(hours: 11)),
        price: basePrice,
        status: SlotStatus.available,
        updatedAt: _demoTime,
      ),
      SlotModel(
        id: '${courtId}_${day.day}_11',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 11)),
        endAt: day.add(const Duration(hours: 12)),
        price: basePrice,
        status: SlotStatus.held,
        holdExpiresAt: DateTime.now().add(const Duration(minutes: 8)),
        updatedAt: _demoTime,
      ),
      SlotModel(
        id: '${courtId}_${day.day}_16',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 16)),
        endAt: day.add(const Duration(hours: 17)),
        price: basePrice,
        status: SlotStatus.available,
        updatedAt: _demoTime,
      ),
      SlotModel(
        id: '${courtId}_${day.day}_17',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 17)),
        endAt: day.add(const Duration(hours: 18)),
        price: basePrice,
        status: SlotStatus.booked,
        updatedAt: _demoTime,
      ),
      SlotModel(
        id: '${courtId}_${day.day}_19',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 19)),
        endAt: day.add(const Duration(hours: 20)),
        price: basePrice,
        status: SlotStatus.available,
        updatedAt: _demoTime,
      ),
      SlotModel(
        id: '${courtId}_${day.day}_20',
        courtId: courtId,
        startAt: day.add(const Duration(hours: 20)),
        endAt: day.add(const Duration(hours: 21)),
        price: basePrice,
        status: SlotStatus.available,
        updatedAt: _demoTime,
      ),
    ];
  }
}
