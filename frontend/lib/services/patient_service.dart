import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
 
class PatientService {
  // Récupérer le token sauvegardé
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
 
  // Headers avec token
  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
 
  // ═══════════════════════════════════════════════════════
  // PROFIL MÉDICAL
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getProfilMedical() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/profil-medical'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> sauvegarderProfilMedical(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/patient/profil-medical'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // INFORMATIONS PERSONNELLES
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getInfosPersonnelles() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/infos-personnelles'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> majInfosPersonnelles(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/patient/infos-personnelles'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // CARNET DE SANTÉ
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getConsultations() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/consultations'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> ajouterConsultation(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/patient/consultations'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> supprimerConsultation(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/patient/consultations/$id'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // VACCINATIONS
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getVaccinations() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/vaccinations'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> ajouterVaccination(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/patient/vaccinations'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> majVaccination(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/patient/vaccinations/$id'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // RAPPELS
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getRappels() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/rappels'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> ajouterRappel(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/patient/rappels'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> toggleRappel(int id) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/patient/rappels/$id/toggle'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> supprimerRappel(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/patient/rappels/$id'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // SUIVI GROSSESSE
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getGrossesse() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/grossesse'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> creerGrossesse(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/patient/grossesse'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> majGrossesse(Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/patient/grossesse'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // ENFANTS
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getEnfants() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/enfants'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> ajouterEnfant(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/patient/enfants'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> majVaccinEnfant(int id, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/patient/enfants/vaccins/$id'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // DOSSIER MÉDICAL
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getDossierMedical() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/dossier-medical'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // EXAMENS
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getExamens() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/examens'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  Future<Map<String, dynamic>> ajouterExamen(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/patient/examens'),
        headers: await _headers(),
        body: jsonEncode(data),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
 
  // ═══════════════════════════════════════════════════════
  // ORDONNANCES
  // ═══════════════════════════════════════════════════════
 
  Future<Map<String, dynamic>> getOrdonnances() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/ordonnances'),
        headers: await _headers(),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }
}
 