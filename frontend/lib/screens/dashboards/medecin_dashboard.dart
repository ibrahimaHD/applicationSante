import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'base_dashboard.dart';

class MedecinDashboard extends StatelessWidget {
  final UserModel user;
  const MedecinDashboard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: user,
      title: 'Espace Médecin',
      accentColor: const Color(0xFF00897B),
      children: [
        const Text('Tableau de bord', style: AppTextStyles.heading2),
        const SizedBox(height: 14),
        QuickActionCard(
          title: 'Mes rendez-vous',
          subtitle: 'Planning du jour',
          icon: Icons.calendar_month_outlined,
          color: const Color(0xFF00897B),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Dossiers patients',
          subtitle: 'Consulter les dossiers',
          icon: Icons.people_outline,
          color: const Color(0xFF1E88E5),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Rédiger une ordonnance',
          subtitle: 'Nouvelle prescription',
          icon: Icons.edit_note_outlined,
          color: const Color(0xFF8E24AA),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Téléconsultation',
          subtitle: 'Consultation en ligne',
          icon: Icons.video_call_outlined,
          color: const Color(0xFF3949AB),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mes statistiques',
          subtitle: 'Activité & patients vus',
          icon: Icons.bar_chart_outlined,
          color: const Color(0xFFF4511E),
        ),
      ],
    );
  }
}
