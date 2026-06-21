import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/app_constants.dart';

class PharmacieService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<List<Medicament>> getMedicaments({
    String? search,
    String? categorie,
  }) async {
    String url = '${AppConstants.baseUrl}/pharmacie/medicaments';
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (categorie != null) params['categorie'] = categorie;
    if (params.isNotEmpty) url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';

    final response = await http.get(Uri.parse(url), headers: await _headers());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['medicaments'] as List)
          .map((m) => Medicament.fromJson(m))
          .toList();
    }
    throw Exception('Erreur ${response.statusCode}');
  }

  static Future<List<String>> getCategories() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/pharmacie/medicaments/categories'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['categories'] ?? []);
    }
    return [];
  }

  static Future<List<Commande>> getCommandes() async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['commandes'] as List)
          .map((c) => Commande.fromJson(c))
          .toList();
    }
    throw Exception('Erreur ${response.statusCode}');
  }

  static Future<Map<String, dynamic>> creerCommande({
    required List<ArticlePanier> articles,
    required String adresseLivraison,
    required String modePaiement,
  }) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes'),
      headers: await _headers(),
      body: jsonEncode({
        'articles': articles.map((a) => a.toJson()).toList(),
        'adresse_livraison': adresseLivraison,
        'mode_paiement': modePaiement,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<void> effectuerPaiement({
    required int commandeId,
    required String numeroMobile,
  }) async {
    await http.post(
      Uri.parse('${AppConstants.baseUrl}/pharmacie/paiement'),
      headers: await _headers(),
      body: jsonEncode({
        'commande_id': commandeId,
        'numero_mobile': numeroMobile,
      }),
    );
  }

  static Future<List<dynamic>> getSuiviCommande(int commandeId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes/$commandeId/suivi'),
      headers: await _headers(),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['suivi'] ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> renouvelerCommande(int commandeId) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes/$commandeId/renouveler'),
      headers: await _headers(),
    );
    return jsonDecode(response.body);
  }
}