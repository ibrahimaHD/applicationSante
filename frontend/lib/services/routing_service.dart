import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutingService {
  static const String _orsBaseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';
  static const String _apiKey = String.fromEnvironment('ORS_API_KEY');

  static Future<List<List<double>>?> getItineraire({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final osrm = await _getItineraireOsrm(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
    if (osrm != null) return osrm;

    if (_apiKey.isEmpty) return null;

    return _getItineraireOrs(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
  }

  static Future<List<List<double>>?> _getItineraireOrs({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_orsBaseUrl),
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

  static Future<List<List<double>>?> _getItineraireOsrm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = '$_osrmBaseUrl/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List? ?? [];
        if (routes.isEmpty) return null;
        final coords = routes.first['geometry']['coordinates'] as List;
        return coords
            .map<List<double>>((c) => [
                  (c[1] as num).toDouble(),
                  (c[0] as num).toDouble(),
                ])
            .toList();
      }
    } catch (_) {}
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

  static int estimerDureeMinutes(double distanceKm) {
    const vitesseUrbaineKmH = 25.0;
    final minutes = (distanceKm / vitesseUrbaineKmH * 60).round();
    return minutes < 1 ? 1 : minutes;
  }

  static double _rad(double deg) => deg * 3.14159265 / 180;
}
