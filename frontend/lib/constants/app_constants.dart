import 'package:flutter/material.dart';
 
class AppColors {
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFFBBDEFB);
  static const Color accent = Color(0xFF00ACC1);
  static const Color background = Color(0xFFF5F9FF);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color textPrimary = Color(0xFF1A237E);
  static const Color textSecondary = Color(0xFF546E7A);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color inputFill = Color(0xFFF0F4FF);
}
 
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
 
  static const TextStyle heading2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
 
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
 
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );
 
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: 0.5,
  );
}
 
class AppConstants {
  // ⚠️ Change selon ta situation :
  // Chrome / Edge (web)  → http://localhost:3000/api
  // Émulateur Android    → http://10.0.2.2:3000/api
  // Téléphone réel       → http://192.168.X.X:3000/api
  static const String baseUrl = 'http://localhost:3000/api';
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
}
 
class UserRole {
  // ✅ Ces valeurs correspondent exactement à ce que le backend renvoie
  static const String patient    = 'patient';
  static const String medecin    = 'medecin';
  static const String pharmacien = 'pharmacien';
  static const String livreur    = 'livreur';
  static const String adminJds   = 'admin';       // backend renvoie 'admin'
  static const String superAdmin = 'superadmin';  // backend renvoie 'superadmin'
 
  static const List<String> allRoles = [
    patient,
    medecin,
    pharmacien,
    livreur,
    adminJds,
    superAdmin,
  ];
 
  static String getLabel(String role) {
    switch (role) {
      case patient:     return 'Patient';
      case medecin:     return 'Médecin';
      case pharmacien:  return 'Pharmacien';
      case livreur:     return 'Livreur';
      case adminJds:    return 'Admin';
      case superAdmin:  return 'Super Admin';
      default:          return role;
    }
  }
 
  static IconData getIcon(String role) {
    switch (role) {
      case patient:     return Icons.person_outline;
      case medecin:     return Icons.local_hospital_outlined;
      case pharmacien:  return Icons.medication_outlined;
      case livreur:     return Icons.delivery_dining_outlined;
      case adminJds:    return Icons.admin_panel_settings_outlined;
      case superAdmin:  return Icons.security_outlined;
      default:          return Icons.person_outline;
    }
  }
 
  static Color getRoleColor(String role) {
    switch (role) {
      case patient:     return const Color(0xFF1E88E5);
      case medecin:     return const Color(0xFF00897B);
      case pharmacien:  return const Color(0xFF8E24AA);
      case livreur:     return const Color(0xFFF4511E);
      case adminJds:    return const Color(0xFF3949AB);
      case superAdmin:  return const Color(0xFFC62828);
      default:          return AppColors.primary;
    }
  }
}
 