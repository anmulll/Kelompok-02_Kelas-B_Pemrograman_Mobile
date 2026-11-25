import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsService {
  static const LatLng defaultCenter = LatLng(-6.9730, 107.6304);
  static const double defaultZoom = 13.5;

  /// Gaya peta gelap Google Maps selaras dengan tema Stitch (#0B0B0C / #141516).
  static const String darkMapStyle = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#0B0B0C"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#8B8D88"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#0B0B0C"}]},
  {"featureType": "administrative", "elementType": "geometry", "stylers": [{"color": "#232528"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#141516"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#1C1D1F"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#232528"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#111822"}]}
]
''';

  CameraPosition initialCameraPosition({double? latitude, double? longitude}) {
    if (latitude != null && longitude != null) {
      return CameraPosition(
        target: LatLng(latitude, longitude),
        zoom: defaultZoom,
      );
    }
    return const CameraPosition(
      target: defaultCenter,
      zoom: defaultZoom,
    );
  }

  Future<bool> openInExternalMaps({
    required double latitude,
    required double longitude,
    required String label,
  }) async {
    final encodedLabel = Uri.encodeComponent(label);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude($encodedLabel)',
    );
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
