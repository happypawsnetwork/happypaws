import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

class GooglePlace {
  final String description;
  final String placeId;

  GooglePlace({required this.description, required this.placeId});

  factory GooglePlace.fromJson(Map<String, dynamic> json) {
    final prediction = json['placePrediction'] as Map<String, dynamic>?;
    final textObj = prediction?['text'] as Map<String, dynamic>?;
    return GooglePlace(
      description: textObj?['text'] as String? ?? '',
      placeId: prediction?['placeId'] as String? ?? '',
    );
  }
}

class GooglePlacesService {
  static final Map<String, Map<String, double>> _coordsCache =
      <String, Map<String, double>>{};
  static String? _currentSessionToken;

  /// Generates a session token or returns the active one.
  static String getSessionToken() {
    _currentSessionToken ??= DateTime.now().microsecondsSinceEpoch.toString();
    return _currentSessionToken!;
  }

  /// Resets the session token once place details are resolved.
  static void resetSessionToken() {
    _currentSessionToken = null;
  }

  static Future<List<GooglePlace>> searchPlaces(String query) async {
    final apiKey = EnvConfig.googleMapsApiKey;
    if (apiKey.isEmpty || query.trim().isEmpty) return [];

    final sessionToken = getSessionToken();
    final url = Uri.parse(
      'https://places.googleapis.com/v1/places:autocomplete',
    );
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'X-Goog-Api-Key': apiKey},
        body: json.encode({'input': query, 'sessionToken': sessionToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suggestions = data['suggestions'] as List?;
        if (suggestions != null) {
          return suggestions
              .map((p) => GooglePlace.fromJson(p as Map<String, dynamic>))
              .where((place) => place.placeId.isNotEmpty)
              .toList();
        }
      }
    } catch (e) {
      // Ignore
    }
    return [];
  }

  static Future<Map<String, double>?> getPlaceCoordinates(
    String placeId,
  ) async {
    if (_coordsCache.containsKey(placeId)) {
      return _coordsCache[placeId];
    }

    final apiKey = EnvConfig.googleMapsApiKey;
    if (apiKey.isEmpty) return null;

    final sessionToken = _currentSessionToken;
    final url = sessionToken != null
        ? Uri.parse(
            'https://places.googleapis.com/v1/places/$placeId?sessionToken=$sessionToken',
          )
        : Uri.parse('https://places.googleapis.com/v1/places/$placeId');

    try {
      final response = await http.get(
        url,
        headers: {'X-Goog-Api-Key': apiKey, 'X-Goog-FieldMask': 'location'},
      );

      // Reset the session token after completing the details call
      resetSessionToken();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final location = data['location'];
        if (location != null) {
          final coords = {
            'lat': (location['latitude'] as num).toDouble(),
            'lng': (location['longitude'] as num).toDouble(),
          };
          _coordsCache[placeId] = coords;
          return coords;
        }
      }
    } catch (e) {
      resetSessionToken();
    }
    return null;
  }
}
