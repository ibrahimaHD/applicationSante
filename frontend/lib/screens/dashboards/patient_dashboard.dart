// ═══════════════════════════════════════════════════════════════════════════
// PATIENT DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'base_dashboard.dart';

class PatientDashboard extends StatelessWidget {
  final UserModel user;
  const PatientDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Espace Patient',
      accentColor: const Color(0xFF1E88E5),
      children: [
        const Text('Actions rapides', style: AppTextStyles.heading2),
        const SizedBox(height: 14),
        QuickActionCard(
          title: 'Prendre un rendez-vous',
          subtitle: 'Consulter un médecin',
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mes ordonnances',
          subtitle: 'Voir mes prescriptions',
          icon: Icons.description_outlined,
          color: const Color(0xFF8E24AA),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Commander des médicaments',
          subtitle: 'Livraison à domicile',
          icon: Icons.shopping_cart_outlined,
          color: const Color(0xFFF4511E),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mon dossier médical',
          subtitle: 'Historique & résultats',
          icon: Icons.folder_outlined,
          color: const Color(0xFF00897B),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Suivi des livraisons',
          subtitle: 'Localiser ma commande',
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFFF4511E),
        ),
      ],
    );
  }
}
