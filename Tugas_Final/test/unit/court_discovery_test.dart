import 'dart:convert';
import 'package:courtmate/models/court_model.dart';
import 'package:courtmate/providers/court_provider.dart';
import 'package:courtmate/services/court_repository.dart';
import 'package:courtmate/services/location_service.dart';
import 'package:courtmate/services/places_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeLocationService extends LocationService {
  _FakeLocationService(this.result);
  final LocationLookupResult result;

  @override
  Future<LocationLookupResult> getLocationWithStatus() async => result;

  @override
  double distanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final dx = startLatitude - endLatitude;
    final dy = startLongitude - endLongitude;
    return (dx * dx + dy * dy) * 111.0;
  }
}

void main() {
  group('PlacesService & CourtRepository', () {
    test('FR-006: hasil Google Places selalu berstatus belum dapat dibooking', () async {
      final client = MockClient((_) async {
        return http.Response(
          jsonEncode({
            'status': 'OK',
            'results': [
              {
                'place_id': 'place_123',
                'name': 'Lapangan Futsal Merdeka',
                'formatted_address': 'Jl. Merdeka No. 1',
                'geometry': {
                  'location': {'lat': -6.97, 'lng': 107.63},
                },
              },
            ],
          }),
          200,
        );
      });

      final service = PlacesService(httpClient: client, apiKey: 'test-key');
      final results = await service.searchSportsPlaces(query: 'futsal');

      expect(results, hasLength(1));
      expect(results.first.placeId, 'place_123');
      expect(results.first.canBeBooked, isFalse);
      expect(results.first.isGooglePlaceOnly, isTrue);
      expect(results.first.sportTypes, contains('Futsal'));
    });

    test('CT-07: PlacesService melempar PlacesServiceException saat HTTP error', () async {
      final client = MockClient((_) async => http.Response('error', 500));
      final service = PlacesService(httpClient: client, apiKey: 'test-key');

      expect(
        () => service.searchSportsPlaces(query: 'futsal'),
        throwsA(isA<PlacesServiceException>()),
      );
    });

    test('CourtRepository.mergeVerifiedAndPlaces menghindari duplikasi placeId', () {
      final now = DateTime(2026, 11, 25);
      final verified = CourtModel(
        id: 'c1',
        name: 'GOR Kampus',
        placeId: 'pid-1',
        sportTypes: const ['Futsal'],
        addressDisplay: 'Jl. Kampus',
        latitude: -6.97,
        longitude: 107.63,
        ownerId: 'admin1',
        verificationStatus: CourtVerificationStatus.verified,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
      final duplicatePlace = CourtModel(
        id: 'places_pid-1',
        name: 'GOR Kampus (Maps)',
        placeId: 'pid-1',
        sportTypes: const ['Futsal'],
        addressDisplay: 'Jl. Kampus',
        latitude: -6.97,
        longitude: 107.63,
        ownerId: '',
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );
      final otherPlace = CourtModel(
        id: 'places_pid-2',
        name: 'Basket Taman',
        placeId: 'pid-2',
        sportTypes: const ['Basket'],
        addressDisplay: 'Taman Kota',
        latitude: -6.98,
        longitude: 107.64,
        ownerId: '',
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );

      final repo = CourtRepository(useDemoFallbackWhenOffline: true);
      final merged = repo.mergeVerifiedAndPlaces(
        verifiedCourts: [verified],
        placesResults: [duplicatePlace, otherPlace],
      );

      expect(merged.map((c) => c.id), ['c1', 'places_pid-2']);
    });
  });

  group('CourtProvider Search, Filter, & Location (CT-01..CT-04, CT-07)', () {
    test('CT-01 & CT-02: pencarian kata kunci dan empty state', () {
      final provider = CourtProvider(
        repository: CourtRepository(useDemoFallbackWhenOffline: true),
      );
      provider.updateCourts(CourtRepository.demoCourts);
      provider.updatePlacesResults(CourtRepository.demoPlacesOnly);

      provider.setSearchQuery('Badminton');
      expect(provider.courts, hasLength(1));
      expect(provider.courts.first.name, 'GOR Badminton Nusantara');

      provider.setSearchQuery('Lapangan Tidak Ada XYZ');
      expect(provider.courts, isEmpty);
    });

    test('CT-03: izin lokasi diberikan mengurutkan lapangan terdekat', () async {
      final provider = CourtProvider(
        repository: CourtRepository(useDemoFallbackWhenOffline: true),
        locationService: _FakeLocationService(
          const LocationLookupResult(
            status: LocationAccessStatus.granted,
            latitude: -6.9550,
            longitude: 107.6410,
          ),
        ),
      );
      provider.updateCourts(CourtRepository.demoCourts);

      await provider.requestLocation();

      expect(provider.hasUserLocation, isTrue);
      expect(provider.courts.first.id, 'court-tenis-senayan');
    });

    test('CT-04: izin lokasi ditolak tetap mendukung pencarian teks', () async {
      final provider = CourtProvider(
        repository: CourtRepository(useDemoFallbackWhenOffline: true),
        locationService: _FakeLocationService(
          const LocationLookupResult(status: LocationAccessStatus.denied),
        ),
      );
      provider.updateCourts(CourtRepository.demoCourts);

      await provider.requestLocation();
      provider.setSearchQuery('Futsal');

      expect(provider.hasUserLocation, isFalse);
      expect(provider.locationStatus, LocationAccessStatus.denied);
      expect(provider.courts, hasLength(1));
      expect(provider.courts.first.name, 'Arena Futsal Kampus Merdeka');
    });

    test('CT-07 / NFR-008: kegagalan Places API tidak menghapus data CourtMate', () async {
      final failingPlaces = PlacesService(
        httpClient: MockClient((_) async => http.Response('fail', 503)),
        apiKey: 'test-key',
      );
      final provider = CourtProvider(
        repository: CourtRepository(
          placesService: failingPlaces,
          useDemoFallbackWhenOffline: true,
        ),
      );
      provider.updateCourts(CourtRepository.demoCourts);

      await provider.refreshPlaces();

      expect(provider.placesErrorMessage, isNotNull);
      expect(provider.courts, hasLength(CourtRepository.demoCourts.length));
    });
  });
}
