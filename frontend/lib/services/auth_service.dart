import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../constants/app_constants.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // ─── LOGIN ─────────────────────────────────────────────────────────────────
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final user = UserModel.fromJson(data['user']);
        final token = data['token'];
        await _saveSession(user, token);
        _currentUser = user.copyWith(token: token);
        return AuthResult(success: true, user: _currentUser);
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Identifiants incorrects',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre réseau.',
      );
    }
  }

  // ─── REGISTER ──────────────────────────────────────────────────────────────
  Future<AuthResult> register(Map<String, dynamic> userData) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return AuthResult(
          success: true,
          message: data['message'] ?? 'Compte créé avec succès',
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Erreur lors de la création du compte',
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre réseau.',
      );
    }
  }

  // ─── SESSION ───────────────────────────────────────────────────────────────
  Future<void> _saveSession(UserModel user, String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
    await prefs.setString(AppConstants.roleKey, user.role);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    if (token == null) return false;

    // Vérifier le token côté serveur
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/auth/verify'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final userData = prefs.getString(AppConstants.userKey);
        if (userData != null) {
          _currentUser = UserModel.fromJson(jsonDecode(userData))
              .copyWith(token: token);
        }
        return true;
      }
    } catch (_) {}

    await logout();
    return false;
  }

  Future<String?> getSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.roleKey);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.roleKey);
    _currentUser = null;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final UserModel? user;

  AuthResult({required this.success, this.message, this.user});
}
