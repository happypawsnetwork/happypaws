import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

class GeocodingService {
  static final Map<String, String> _cache = <String, String>{};

  /// Returns a rounded key string to ~11 meters resolution (4 decimal places)
  static String _formatCoordKey(double lat, double lng) {
    return '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
  }

  static Future<String?> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    final cacheKey = _formatCoordKey(lat, lng);
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final apiKey = EnvConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return null;

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final address = data['results'][0]['formatted_address'] as String?;
          if (address != null) {
            _cache[cacheKey] = address;
          }
          return address;
        }
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }
}
