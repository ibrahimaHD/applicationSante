// ═══════════════════════════════════════════════════════════════════════════
// PHARMACIEN DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'base_dashboard.dart';

class PharmacienDashboard extends StatelessWidget {
  final UserModel user;
  const PharmacienDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Espace Pharmacien',
      accentColor: const Color(0xFF8E24AA),
      children: [
        const Text('Gestion pharmacie', style: AppTextStyles.heading2),
        const SizedBox(height: 14),
        QuickActionCard(
          title: 'Ordonnances reçues',
          subtitle: 'Nouvelles prescriptions',
          icon: Icons.inbox_outlined,
          color: const Color(0xFF8E24AA),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Stock médicaments',
          subtitle: 'Gérer l\'inventaire',
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF00897B),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Commandes en cours',
          subtitle: 'Suivi des livraisons',
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFFF4511E),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Historique ventes',
          subtitle: 'Rapport & statistiques',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF1E88E5),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LIVREUR DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
class LivreurDashboard extends StatelessWidget {
  final UserModel user;
  const LivreurDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Espace Livreur',
      accentColor: const Color(0xFFF4511E),
      children: [
        const Text('Mes livraisons', style: AppTextStyles.heading2),
        const SizedBox(height: 14),
        QuickActionCard(
          title: 'Livraisons du jour',
          subtitle: 'Commandes assignées',
          icon: Icons.delivery_dining_outlined,
          color: const Color(0xFFF4511E),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mon profil',
          subtitle: 'Disponibilité & gains',
          icon: Icons.account_circle_outlined,
          color: const Color(0xFF8E24AA),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Carte & itinéraire',
          subtitle: 'Navigation GPS',
          icon: Icons.map_outlined,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Historique livraisons',
          subtitle: 'Livraisons effectuées',
          icon: Icons.history_outlined,
          color: const Color(0xFF00897B),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ADMIN JDS DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
class AdminDashboard extends StatelessWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Espace Admin JDS',
      accentColor: const Color(0xFF3949AB),
      children: [
        const Text('Administration', style: AppTextStyles.heading2),
        const SizedBox(height: 14),
        QuickActionCard(
          title: 'Gestion utilisateurs',
          subtitle: 'Comptes & validations',
          icon: Icons.manage_accounts_outlined,
          color: const Color(0xFF3949AB),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Médecins & pharmacies',
          subtitle: 'Valider les inscriptions',
          icon: Icons.verified_outlined,
          color: const Color(0xFF00897B),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Rapports & statistiques',
          subtitle: "Vue d'ensemble plateforme",
          icon: Icons.analytics_outlined,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Signalements',
          subtitle: 'Problèmes & réclamations',
          icon: Icons.flag_outlined,
          color: const Color(0xFFF4511E),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Paramètres système',
          subtitle: 'Configuration générale',
          icon: Icons.settings_outlined,
          color: const Color(0xFF546E7A),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SUPER ADMIN DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════
class SuperAdminDashboard extends StatelessWidget {
  final UserModel user;
  const SuperAdminDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Super Administration',
      accentColor: const Color(0xFFC62828),
      children: [
        const Text('Panneau de contrôle', style: AppTextStyles.heading2),
        const SizedBox(height: 14),
        QuickActionCard(
          title: 'Gestion des admins',
          subtitle: 'Créer & gérer les admins JDS',
          icon: Icons.admin_panel_settings_outlined,
          color: const Color(0xFFC62828),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Tous les utilisateurs',
          subtitle: 'Vue globale de la plateforme',
          icon: Icons.people_alt_outlined,
          color: const Color(0xFF3949AB),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Configuration système',
          subtitle: 'Paramètres avancés',
          icon: Icons.tune_outlined,
          color: const Color(0xFF00897B),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Logs & sécurité',
          subtitle: "Audit trail & accès",
          icon: Icons.security_outlined,
          color: const Color(0xFF546E7A),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Base de données',
          subtitle: 'Sauvegarde & intégrité',
          icon: Icons.storage_outlined,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Statistiques globales',
          subtitle: 'Analytics toute plateforme',
          icon: Icons.insights_outlined,
          color: const Color(0xFFF4511E),
        ),
      ],
    );
  }
}
