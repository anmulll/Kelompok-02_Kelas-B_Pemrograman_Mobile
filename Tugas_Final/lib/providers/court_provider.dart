import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/court_model.dart';
import '../services/court_repository.dart';
import '../services/location_service.dart';

class CourtProvider extends ChangeNotifier {
  CourtProvider({
    CourtRepository? repository,
    LocationService? locationService,
  }) : _repository = repository ?? CourtRepository(),
       _locationService = locationService ?? LocationService();

  final CourtRepository _repository;
  final LocationService _locationService;

  StreamSubscription<List<CourtModel>>? _courtsSub;

  List<CourtModel> _verifiedCourts = const [];
  List<CourtModel> _placesResults = const [];

  String? _selectedSport;
  String _searchQuery = '';
  bool _sortByDistance = true;
  double? _maxDistanceKm;

  bool _isLoading = false;
  bool _isSearchingPlaces = false;
  String? _errorMessage;
  String? _placesErrorMessage;

  LocationAccessStatus? _locationStatus;
  double? _userLatitude;
  double? _userLongitude;
  bool _isRequestingLocation = false;

  List<CourtModel> get verifiedCourts => _verifiedCourts;
  List<CourtModel> get placesResults => _placesResults;

  /// Gabungan lapangan terverifikasi CourtMate dan tempat umum Google Places
  /// yang sudah difilter & diurutkan sesuai pencarian, kategori, dan jarak.
  List<CourtModel> get courts => _filteredAndSortedCourts();

  String? get selectedSport => _selectedSport;
  String get searchQuery => _searchQuery;
  bool get sortByDistance => _sortByDistance;
  double? get maxDistanceKm => _maxDistanceKm;

  bool get isLoading => _isLoading;
  bool get isSearchingPlaces => _isSearchingPlaces;
  String? get errorMessage => _errorMessage;
  String? get placesErrorMessage => _placesErrorMessage;

  LocationAccessStatus? get locationStatus => _locationStatus;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;
  bool get hasUserLocation => _userLatitude != null && _userLongitude != null;
  bool get isRequestingLocation => _isRequestingLocation;

  /// Memulai pemuatan daftar lapangan terverifikasi + pencarian awal Places.
  Future<void> initializeDiscovery() async {
    subscribeToVerifiedCourts();
    await refreshPlaces();
  }

  void subscribeToVerifiedCourts() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _courtsSub?.cancel();
    _courtsSub = _repository.watchVerifiedCourts().listen(
      (items) {
        _verifiedCourts = items;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
      },
      onError: (Object error) {
        _isLoading = false;
        _errorMessage = 'Gagal memuat data lapangan: $error';
        notifyListeners();
      },
    );
  }

  Future<void> refreshPlaces() async {
    _isSearchingPlaces = true;
    _placesErrorMessage = null;
    notifyListeners();

    try {
      final results = await _repository.searchGooglePlaces(
        query: _searchQuery.isNotEmpty
            ? _searchQuery
            : (_selectedSport ?? ''),
        latitude: _userLatitude,
        longitude: _userLongitude,
      );
      _placesResults = results;
    } catch (error) {
      // NFR-008: Kegagalan Google Places tidak menghapus data CourtMate.
      _placesErrorMessage =
          'Pencarian Google Places gagal dimuat. Menampilkan data CourtMate.';
    } finally {
      _isSearchingPlaces = false;
      notifyListeners();
    }
  }

  Future<void> requestLocation() async {
    if (_isRequestingLocation) return;
    _isRequestingLocation = true;
    notifyListeners();

    final result = await _locationService.getLocationWithStatus();
    _locationStatus = result.status;
    _userLatitude = result.latitude;
    _userLongitude = result.longitude;
    _isRequestingLocation = false;
    notifyListeners();

    if (result.hasCoordinates) {
      await refreshPlaces();
    }
  }

  void setSelectedSport(String? sport) {
    final normalized = (sport == null || sport == 'Semua') ? null : sport;
    if (_selectedSport == normalized) return;
    _selectedSport = normalized;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setSortByDistance(bool value) {
    if (_sortByDistance == value) return;
    _sortByDistance = value;
    notifyListeners();
  }

  void setMaxDistanceKm(double? km) {
    if (_maxDistanceKm == km) return;
    _maxDistanceKm = km;
    notifyListeners();
  }

  void updateCourts(List<CourtModel> items) {
    _verifiedCourts = items;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }

  void updatePlacesResults(List<CourtModel> items) {
    _placesResults = items;
    _placesErrorMessage = null;
    notifyListeners();
  }

  double? distanceKmFor(CourtModel court) {
    if (!hasUserLocation) return null;
    if (court.latitude == 0 && court.longitude == 0) return null;
    return _locationService.distanceInKm(
      startLatitude: _userLatitude!,
      startLongitude: _userLongitude!,
      endLatitude: court.latitude,
      endLongitude: court.longitude,
    );
  }

  List<CourtModel> _filteredAndSortedCourts() {
    final merged = _repository.mergeVerifiedAndPlaces(
      verifiedCourts: _verifiedCourts,
      placesResults: _placesResults,
    );

    final q = _searchQuery.trim().toLowerCase();
    final filtered = merged.where((court) {
      if (_selectedSport != null && _selectedSport!.isNotEmpty) {
        final target = _selectedSport!.toLowerCase();
        final matchesSport = court.sportTypes.any(
          (s) => s.toLowerCase().contains(target),
        );
        if (!matchesSport) return false;
      }

      if (q.isNotEmpty) {
        final matchesText =
            court.name.toLowerCase().contains(q) ||
            court.addressDisplay.toLowerCase().contains(q) ||
            court.sportTypes.any((s) => s.toLowerCase().contains(q));
        if (!matchesText) return false;
      }

      if (_maxDistanceKm != null && hasUserLocation) {
        final dist = distanceKmFor(court);
        if (dist != null && dist > _maxDistanceKm!) return false;
      }

      return true;
    }).toList();

    if (_sortByDistance && hasUserLocation) {
      filtered.sort((a, b) {
        final distA = distanceKmFor(a) ?? double.infinity;
        final distB = distanceKmFor(b) ?? double.infinity;
        return distA.compareTo(distB);
      });
    } else {
      // Prioritaskan lapangan terverifikasi CourtMate jika belum ada koordinat.
      filtered.sort((a, b) {
        if (a.canBeBooked != b.canBeBooked) {
          return a.canBeBooked ? -1 : 1;
        }
        return a.name.compareTo(b.name);
      });
    }

    return filtered;
  }

  @override
  void dispose() {
    _courtsSub?.cancel();
    super.dispose();
  }
}
