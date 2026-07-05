import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import 'dashboards/patient_dashboard.dart';
import 'dashboards/medecin_dashboard.dart';
import 'dashboards/pharmacien_dashboard.dart';
import 'dashboards/livreur_dashboard.dart';
import 'dashboards/admin_dashboard.dart';

class RoleRedirectScreen extends StatelessWidget {
  final UserModel user;

  const RoleRedirectScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return _getDashboardForRole(user.role);
  }

  Widget _getDashboardForRole(String role) {
    switch (role) {
      case UserRole.patient:
        return PatientDashboard(user: user);
      case UserRole.medecin:
        return MedecinDashboard(user: user);
      case UserRole.pharmacien:
        return PharmacienDashboard(user: user);
      case UserRole.livreur:
        return LivreurDashboard(user: user);
      case UserRole.adminJds:
        return AdminDashboard(user: user);
      case UserRole.superAdmin:
       // return SuperAdminDashboard(user: user);
      default:
        return PatientDashboard(user: user);
    }
  }
}