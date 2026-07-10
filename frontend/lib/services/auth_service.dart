import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';
 
class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;
 
  AuthResult({required this.success, this.message, this.user});
}
class AuthService {
  // Utilisateur en mémoire (accessible via currentUser)
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;
 
  // ── VÉRIFIER SI CONNECTÉ (utilisé par splash_screen.dart) ─────────────
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    final userStr = prefs.getString(AppConstants.userKey);
 
    if (token == null || userStr == null) return false;
 
    try {
      final userMap = jsonDecode(userStr) as Map<String, dynamic>;
      _currentUser = UserModel.fromJson({...userMap, 'token': token});
      return true;
    } catch (e) {
      return false;
    }
  }
 
  // ── CONNEXION (utilisé par login_screen.dart) ──────────────────────────
  Future<AuthResult> login(String email, String motDePasse) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/connexion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'mot_de_passe': motDePasse,
        }),
      );
 
      final data = jsonDecode(response.body) as Map<String, dynamic>;
 
      if (response.statusCode == 200 && data['succes'] == true) {
        final token = data['token'] as String;
        final utilisateur = data['utilisateur'] as Map<String, dynamic>;
 
        // Sauvegarder localement
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.userKey, jsonEncode(utilisateur));
        await prefs.setString(AppConstants.roleKey, utilisateur['role'] ?? '');
 
        // Créer le UserModel et le garder en mémoire
        _currentUser = UserModel.fromJson({...utilisateur, 'token': token});
 
        return AuthResult(success: true, user: _currentUser);
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Email ou mot de passe incorrect',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Serveur inaccessible. Le backend est-il démarré ?',
      );
    }
  }
 
  // ── INSCRIPTION (utilisé par register_screen.dart) ─────────────────────
  Future<AuthResult> register(Map<String, dynamic> donnees) async {
    try {
      // Mapper les champs Flutter → backend
      final body = {
        'nom': donnees['nom'],
        'prenom': donnees['prenom'],
        'email': donnees['email'],
        'telephone': donnees['telephone'],
        'mot_de_passe': donnees['password'], // Flutter envoie 'password'
        'role': donnees['role'],
        // Champs médecin
        if (donnees['specialite'] != null) 'specialite': donnees['specialite'],
        if (donnees['numero_licence'] != null) 'numero_ordre': donnees['numero_licence'],
        if (donnees['hopital_clinique'] != null) 'hopital_clinique': donnees['hopital_clinique'],
        if (donnees['diplome_url'] != null) 'diplome_url': donnees['diplome_url'],
        if (donnees['document_identite_url'] != null) 'document_identite_url': donnees['document_identite_url'],
        // Champs pharmacien
        if (donnees['nom_pharmacie'] != null) 'nom_pharmacie': donnees['nom_pharmacie'],
        if (donnees['adresse_pharmacie'] != null) 'adresse_pharmacie': donnees['adresse_pharmacie'],
        if (donnees['nom_pharmacie'] != null && donnees['numero_licence'] != null)
          'numero_licence': donnees['numero_licence'],
        // Champs livreur
        if (donnees['vehicle_type'] != null) 'vehicule': donnees['vehicle_type'],
        if (donnees['zone'] != null) 'zone_livraison': donnees['zone'],
        if (donnees['numero_permis'] != null) 'numero_permis': donnees['numero_permis'],
      };

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/auth/inscription'),
      );
      body.forEach((key, value) {
        if (value != null) request.fields[key] = value.toString();
      });

      await _ajouterFichier(request, 'diplome', donnees['diplome']);
      await _ajouterFichier(request, 'document_identite', donnees['document_identite']);
      await _ajouterFichier(request, 'autorisation_exercice', donnees['autorisation_exercice']);
      await _ajouterFichier(request, 'permis_conduire', donnees['permis_conduire']);

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      final data = jsonDecode(response.body) as Map<String, dynamic>;
 
      return AuthResult(
        success: data['succes'] == true,
        message: data['message'],
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Serveur inaccessible.',
      );
    }
  }

  Future<void> _ajouterFichier(
    http.MultipartRequest request,
    String field,
    dynamic file,
  ) async {
    if (file == null || file is! PlatformFile) return;
    if (file.bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        field,
        file.bytes!,
        filename: file.name,
      ));
      return;
    }
    if (file.path != null) {
      request.files.add(await http.MultipartFile.fromPath(
        field,
        file.path!,
        filename: file.name,
      ));
    }
  }
 
  // ── DÉCONNEXION ────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.roleKey);
    _currentUser = null;
  }
 
  // ── RÉCUPÉRER LE TOKEN ─────────────────────────────────────────────────
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
 
  // ── RÉCUPÉRER L'UTILISATEUR ────────────────────────────────────────────
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(AppConstants.userKey);
    final token = prefs.getString(AppConstants.tokenKey);
    if (userStr == null) return null;
    final userMap = jsonDecode(userStr) as Map<String, dynamic>;
    return UserModel.fromJson({...userMap, 'token': token});
  }
}
