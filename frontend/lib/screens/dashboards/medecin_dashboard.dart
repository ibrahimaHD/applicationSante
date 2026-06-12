import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'base_dashboard.dart';
import '../medecin/mes_patients_screen.dart';
import '../medecin/ajouter_consultation_screen.dart';
import '../medecin/creer_ordonnance_screen.dart';
import '../medecin/mes_consultations_screen.dart';
import '../medecin/scanner_qr_screen.dart';
import '../medecin/mes_rdv_medecin_screen.dart';

class MedecinDashboard extends StatefulWidget {
  final UserModel user;
  const MedecinDashboard({super.key, required this.user});

  @override
  State<MedecinDashboard> createState() => _MedecinDashboardState();
}

class _MedecinDashboardState extends State<MedecinDashboard> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _rdvDuJour = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> _chargerStats() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _stats = data['stats'] ?? {};
          _rdvDuJour = data['rdv_du_jour'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return BaseDashboard(
      user: widget.user,
      title: 'Espace Médecin',
      accentColor: const Color(0xFF00897B),
      children: [
        Row(children: [
          Expanded(
              child: _statCard(
                  "RDV aujourd'hui",
                  '${_stats['rdv_aujourd_hui'] ?? 0}',
                  Icons.today_outlined,
                  const Color(0xFF00897B))),
          const SizedBox(width: 12),
          Expanded(
              child: _statCard('En attente', '${_stats['rdv_en_attente'] ?? 0}',
                  Icons.schedule_outlined, Colors.orange)),
          const SizedBox(width: 12),
          Expanded(
              child: _statCard('Patients', '${_stats['total_patients'] ?? 0}',
                  Icons.people_outline, const Color(0xFF1E88E5))),
        ]),
        const SizedBox(height: 24),
        if (_rdvDuJour.isNotEmpty) ...[
          Row(children: [
            const Text('RDV du jour', style: AppTextStyles.heading2),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MesRdvMedecinScreen(user: widget.user))),
              child: const Text('Voir tout'),
            ),
          ]),
          const SizedBox(height: 8),
          ..._rdvDuJour.take(3).map((rdv) => _rdvCard(context, rdv)),
          const SizedBox(height: 16),
        ],
        const Text('Actions rapides', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        QuickActionCard(
          title: 'Mes rendez-vous',
          subtitle: 'Gérer et confirmer les RDV',
          icon: Icons.calendar_today_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MesRdvMedecinScreen(user: widget.user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mes patients',
          subtitle: 'Consulter la liste de mes patients',
          icon: Icons.people_outline,
          color: const Color(0xFF1E88E5),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MesPatientsScreen(user: widget.user))),
        ),
        const SizedBox(height: 10),

        QuickActionCard(
          title: 'Scanner QR patient',
          subtitle: 'Accéder au dossier via QR code',
          icon: Icons.qr_code_scanner_outlined,
          color: const Color(0xFF3949AB),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ScannerQrScreen(user: widget.user))),
        ),

        const SizedBox(height: 24),
        const Text('Actes médicaux', style: AppTextStyles.heading2),
        const SizedBox(height: 12),
        QuickActionCard(
          title: 'Ajouter une consultation',
          subtitle: 'Diagnostic, traitement, notes',
          icon: Icons.medical_services_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MesConsultationsScreen(user: widget.user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Créer une ordonnance',
          subtitle: 'Prescrire des médicaments',
          icon: Icons.description_outlined,
          color: const Color(0xFF8E24AA),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CreerOrdonnanceScreen(user: widget.user))),
        ),
        const SizedBox(height: 10),
        QuickActionCard(
          title: 'Mes consultations',
          subtitle: 'Historique de mes consultations',
          icon: Icons.history_outlined,
          color: const Color(0xFF00ACC1),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MesConsultationsScreen(user: widget.user))),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w800, color: color)),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _rdvCard(BuildContext context, Map<String, dynamic> rdv) {
    final statut = rdv['statut'] ?? 'en_attente';
    final color = statut == 'confirme' ? AppColors.success : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Center(
              child: Text(rdv['heure_rdv'] ?? '',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color))),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${rdv['patient_prenom'] ?? ''} ${rdv['patient_nom'] ?? ''}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          Text(rdv['motif'] ?? '',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ])),
        if (statut == 'en_attente')
          TextButton(
            // Dans _rdvCard, remplacer :
            onPressed: () async {
              final token = await _getToken();
              final response = await http.patch(
                // ✅ Bonne route
                Uri.parse(
                    '${AppConstants.baseUrl}/rendez-vous/${rdv['id']}/statut'),
                headers: {
                  'Content-Type': 'application/json',
                  'Authorization': 'Bearer $token',
                },
                body: jsonEncode({'statut': 'confirme'}),
              );
              debugPrint(
                  'Confirm RDV: ${response.statusCode} - ${response.body}');
              _chargerStats();
            },

            style: TextButton.styleFrom(foregroundColor: AppColors.success),
            child: const Text('Confirmer', style: TextStyle(fontSize: 12)),
          ),
      ]),
    );
  }
}