import 'dart:convert';
import 'package:http/http.dart' as http;

class RoutingService {
  static const String _googleDirectionsBaseUrl =
      'https://maps.googleapis.com/maps/api/directions/json';
  static const String _orsBaseUrl =
      'https://api.openrouteservice.org/v2/directions/driving-car';
  static const String _osrmBaseUrl = 'https://router.project-osrm.org/route/v1/driving';
  static const String _apiKey = String.fromEnvironment('ORS_API_KEY');
  static const String _googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static Future<List<List<double>>?> getItineraire({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final google = await _getItineraireGoogleMaps(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );
    if (google != null) return google;

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

  static Future<List<List<double>>?> _getItineraireGoogleMaps({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    if (_googleMapsApiKey.isEmpty) return null;
    try {
      final uri = Uri.parse(_googleDirectionsBaseUrl).replace(queryParameters: {
        'origin': '$startLat,$startLng',
        'destination': '$endLat,$endLng',
        'mode': 'driving',
        'key': _googleMapsApiKey,
      });
      final response = await http.get(uri);
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body);
      final routes = data['routes'] as List? ?? [];
      if (routes.isEmpty) return null;
      final encoded = routes.first['overview_polyline']?['points']?.toString();
      if (encoded == null || encoded.isEmpty) return null;
      return _decodePolyline(encoded);
    } catch (_) {
      return null;
    }
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

  static List<List<double>> _decodePolyline(String encoded) {
    final points = <List<double>>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add([lat / 1E5, lng / 1E5]);
    }
    return points;
  }
}
