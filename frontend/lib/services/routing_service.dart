import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutingService {
  // OpenRouteService — gratuit, pas de clé requise pour usage basique
  static const String _baseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';
  static const String _apiKey =
      '5b3ce3597851110001cf6248a4b9f9b0b3e14b2e8d5e3e9c3f1f1e1e';
      // ⚠️ Remplace par ta clé gratuite sur openrouteservice.org

  static Future<List<List<double>>?> getItineraire({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': _apiKey,
        },
        body: jsonEncode({
          'coordinates': [
            [startLng, startLat],
            [endLng, endLat],
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['routes'][0]['geometry']['coordinates']
            as List;
        return coords
            .map<List<double>>((c) =>
                [c[1].toDouble(), c[0].toDouble()])
            .toList();
      }
    } catch (e) {
      // Fallback : ligne droite
    }
    return null;
  }

  static double calculerDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = (dLat / 2) * (dLat / 2) +
        (dLng / 2) * (dLng / 2);
    return R * 2 * (a < 0 ? 0 : a > 1 ? 1 : a);
  }

  static double _rad(double deg) => deg * 3.14159265 / 180;
}