import 'package:geolocator/geolocator.dart';

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
}
