import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/court_model.dart';

class PlacesServiceException implements Exception {
  const PlacesServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}

class PlacesService {
  PlacesService({
    http.Client? httpClient,
    String? apiKey,
  }) : _httpClient = httpClient ?? http.Client(),
       _apiKey = apiKey ?? const String.fromEnvironment('PLACES_API_KEY');

  final http.Client _httpClient;
  final String _apiKey;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  /// Mencari fasilitas olahraga via Google Places Text Search API (FR-004, C-03).
  /// Hasil Places selalu ditandai belum terdaftar di CourtMate (`canBeBooked == false`).
  Future<List<CourtModel>> searchSportsPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int radiusMeters = 5000,
  }) async {
    if (!isConfigured) {
      return const [];
    }

    final trimmed = query.trim();
    final effectiveQuery = trimmed.isEmpty
        ? 'lapangan olahraga futsal badminton basket tenis'
        : 'lapangan $trimmed';

    final params = <String, String>{
      'query': effectiveQuery,
      'language': 'id',
      'key': _apiKey,
    };

    if (latitude != null && longitude != null) {
      params['location'] = '$latitude,$longitude';
      params['radius'] = radiusMeters.toString();
    }

    final uri = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/textsearch/json',
      params,
    );

    final response = await _httpClient.get(uri);
    if (response.statusCode != 200) {
      throw PlacesServiceException(
        'Gagal menghubungi Google Places (HTTP ${response.statusCode}).',
      );
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = (body['status'] as String?) ?? 'UNKNOWN_ERROR';
    if (status == 'ZERO_RESULTS') {
      return const [];
    }
    if (status != 'OK') {
      final errorMessage = body['error_message'] as String?;
      throw PlacesServiceException(
        errorMessage ?? 'Google Places mengembalikan status $status.',
      );
    }

    final results = (body['results'] as List?) ?? const [];
    final now = DateTime.now();

    return results.whereType<Map<String, dynamic>>().map((item) {
      final geometry = item['geometry'] as Map<String, dynamic>?;
      final location = geometry?['location'] as Map<String, dynamic>?;
      final lat = ((location?['lat'] as num?) ?? 0).toDouble();
      final lng = ((location?['lng'] as num?) ?? 0).toDouble();
      final placeId = (item['place_id'] as String?) ?? '';
      final name = (item['name'] as String?) ?? 'Tempat Olahraga';
      final address = (item['formatted_address'] as String?) ?? '';
      final inferredSports = _inferSportTypes(name, trimmed);

      return CourtModel(
        id: 'places_$placeId',
        name: name,
        placeId: placeId,
        sportTypes: inferredSports,
        addressDisplay: address,
        latitude: lat,
        longitude: lng,
        ownerId: '',
        verificationStatus: CourtVerificationStatus.pendingVerification,
        isActive: false,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
  }

  List<String> _inferSportTypes(String name, String query) {
    final combined = '${name.toLowerCase()} ${query.toLowerCase()}';
    final matched = <String>[];
    if (combined.contains('futsal')) matched.add('Futsal');
    if (combined.contains('badminton') || combined.contains('bulutangkis')) {
      matched.add('Badminton');
    }
    if (combined.contains('basket')) matched.add('Basket');
    if (combined.contains('tenis') || combined.contains('tennis')) {
      matched.add('Tenis');
    }
    if (combined.contains('mini soccer')) matched.add('Mini Soccer');
    if (matched.isEmpty) matched.add('Olahraga');
    return matched;
  }
}
