import 'package:geolocator/geolocator.dart';

enum LocationAccessStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class LocationLookupResult {
  const LocationLookupResult({
    required this.status,
    this.latitude,
    this.longitude,
  });

  final LocationAccessStatus status;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates =>
      status == LocationAccessStatus.granted &&
      latitude != null &&
      longitude != null;
}

class LocationService {
  /// Meminta izin lokasi dengan persetujuan pengguna (FR-005).
  /// Mengembalikan `null` bila layanan lokasi nonaktif atau izin ditolak (NFR-008).
  Future<Position?> getCurrentPositionSafely() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition();
  }

  /// Mengambil koordinat beserta status izin agar UI dapat menampilkan fallback yang jelas (C-04).
  Future<LocationLookupResult> getLocationWithStatus() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationLookupResult(
          status: LocationAccessStatus.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return const LocationLookupResult(
            status: LocationAccessStatus.denied,
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return const LocationLookupResult(
          status: LocationAccessStatus.deniedForever,
        );
      }

      final pos = await Geolocator.getCurrentPosition();
      return LocationLookupResult(
        status: LocationAccessStatus.granted,
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {
      return const LocationLookupResult(
        status: LocationAccessStatus.denied,
      );
    }
  }

  /// Menghitung jarak dalam kilometer antara dua titik koordinat.
  double distanceInKm({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    final meters = Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
    return meters / 1000.0;
  }
}
