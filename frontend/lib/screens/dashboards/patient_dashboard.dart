import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'base_dashboard.dart';
import '../patient/profil_medical_screen.dart';
import '../patient/carnet_sante_screen.dart';
import '../patient/vaccinations_screen.dart';
import '../patient/rappels_screen.dart';
import '../patient/suivi_grossesse_screen.dart';
import '../patient/vaccinations_enfants_screen.dart';
import '../patient/dossier_medical_screen.dart';
import '../patient/informations_personnelles_screen.dart';

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
        // ── Bannière de bienvenue ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E88E5), Color(0xFF00ACC1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.health_and_safety_outlined,
                  color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bienvenue ${user.prenom} !',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Text('Votre santé, notre priorité',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── Section Profil & Infos ─────────────────────────────────────
        const Text('Mon Profil', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Informations personnelles',
          subtitle: 'Gérer mes données personnelles',
          icon: Icons.person_outline,
          color: const Color(0xFF1E88E5),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => InformationsPersonnellesScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Profil médical',
          subtitle: 'Créer et modifier mon profil médical',
          icon: Icons.medical_information_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => ProfilMedicalScreen(user: user))),
        ),

        const SizedBox(height: 24),

        // ── Section Santé ──────────────────────────────────────────────
        const Text('Ma Santé', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Mon dossier médical',
          subtitle: 'Consulter et exporter mon dossier',
          icon: Icons.folder_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DossierMedicalScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Carnet de santé',
          subtitle: 'Historique de mes consultations',
          icon: Icons.book_outlined,
          color: const Color(0xFF1E88E5),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => CarnetSanteScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mes vaccinations',
          subtitle: 'Historique et calendrier vaccinal',
          icon: Icons.vaccines_outlined,
          color: const Color(0xFF8E24AA),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => VaccinationsScreen(user: user))),
        ),

        const SizedBox(height: 24),

        // ── Section Rappels & Suivi ────────────────────────────────────
        const Text('Suivi & Rappels', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Mes rappels',
          subtitle: 'Vaccins, traitements, rendez-vous',
          icon: Icons.notifications_outlined,
          color: const Color(0xFFF4511E),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => RappelsScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Suivi de grossesse',
          subtitle: 'Suivre ma grossesse semaine par semaine',
          icon: Icons.pregnant_woman_outlined,
          color: const Color(0xFFE91E8C),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SuiviGrossesseScreen(user: user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Vaccinations des enfants',
          subtitle: 'Carnet vaccinal de mes enfants',
          icon: Icons.child_care_outlined,
          color: const Color(0xFF00ACC1),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => VaccinationsEnfantsScreen(user: user))),
        ),

        const SizedBox(height: 24),

        // ── Section Données ────────────────────────────────────────────
        const Text('Mes Données', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Accès hors ligne',
          subtitle: 'Dossier médical disponible sans internet',
          icon: Icons.offline_bolt_outlined,
          color: const Color(0xFF3949AB),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DossierMedicalScreen(user: user, horsLigne: true))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Exporter en PDF',
          subtitle: 'Télécharger mon dossier médical',
          icon: Icons.picture_as_pdf_outlined,
          color: const Color(0xFFC62828),
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => DossierMedicalScreen(user: user, exportPdf: true))),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}
