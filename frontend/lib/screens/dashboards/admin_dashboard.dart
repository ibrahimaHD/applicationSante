import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../dashboards/base_dashboard.dart';
import '../admin/gestion_utilisateurs_screen.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel user;
  const AdminDashboard({super.key, required this.user});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  Map<String, dynamic> _stats = {};
  List<dynamic> _derniersInscrits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerStats();
  }

  Future<void> _chargerStats() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/dashboard/admin'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final donnees = data['donnees'] ?? {};
        setState(() {
          _stats = donnees['statistiques'] ?? {};
          _derniersInscrits = donnees['derniers_inscrits'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Erreur stats admin: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final totalUsers = _stats['total_utilisateurs'] ?? 0;
    final parRole = _stats['par_role'] as List? ?? [];

    return BaseDashboard(
      user: widget.user,
      title: 'Espace Admin',
      accentColor: const Color(0xFF3949AB),
      children: [
        // Stats rapides
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _statCard('Total utilisateurs', '$totalUsers',
                  Icons.people_alt_outlined, const Color(0xFF3949AB)),
              ...parRole.take(3).map((r) => _statCard(
                    r['role'] ?? '',
                    '${r['total'] ?? 0}',
                    _roleIcon(r['role'] ?? ''),
                    _roleColor(r['role'] ?? ''),
                  )),
            ],
          ),

        const SizedBox(height: 24),

        // Actions rapides
        const Text('Administration', style: AppTextStyles.heading2),
        const SizedBox(height: 12),

        QuickActionCard(
          title: 'Gestion utilisateurs',
          subtitle: 'Voir, activer ou désactiver les comptes',
          icon: Icons.manage_accounts_outlined,
          color: const Color(0xFF3949AB),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GestionUtilisateursScreen(user: widget.user),
            ),
          ),
        ),

        const SizedBox(height: 10),

        QuickActionCard(
          title: 'Médecins & pharmacies',
          subtitle: 'Valider les inscriptions professionnelles',
          icon: Icons.verified_outlined,
          color: const Color(0xFF00897B),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GestionUtilisateursScreen(
                user: widget.user,
                filtreRole: 'medecin',
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        QuickActionCard(
          title: 'Rapports & statistiques',
          subtitle: 'Vue d\'ensemble de la plateforme',
          icon: Icons.analytics_outlined,
          color: const Color(0xFF1E88E5),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Module rapports — bientôt disponible'),
                backgroundColor: Color(0xFF1E88E5),
              ),
            );
          },
        ),

        const SizedBox(height: 10),

        QuickActionCard(
          title: 'Signalements',
          subtitle: 'Problèmes et réclamations',
          icon: Icons.flag_outlined,
          color: const Color(0xFFF4511E),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Module signalements — bientôt disponible'),
                backgroundColor: Color(0xFFF4511E),
              ),
            );
          },
        ),

        const SizedBox(height: 24),

        // Derniers inscrits
        if (_derniersInscrits.isNotEmpty) ...[
          Row(children: [
            const Text('Derniers inscrits', style: AppTextStyles.heading2),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GestionUtilisateursScreen(user: widget.user),
                ),
              ),
              child: const Text('Voir tout'),
            ),
          ]),
          const SizedBox(height: 8),
          ..._derniersInscrits.take(5).map((u) => _userCard(u)),
        ],

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: Row(children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    );
  }

  Widget _userCard(Map<String, dynamic> u) {
    final role = u['role'] ?? 'patient';
    final color = _roleColor(role);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '${(u['prenom'] ?? 'U')[0]}${(u['nom'] ?? 'N')[0]}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${u['prenom'] ?? ''} ${u['nom'] ?? ''}',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          Text(u['email'] ?? '',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(UserRole.getLabel(role),
              style: TextStyle(
                  fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Color _roleColor(String role) => UserRole.getRoleColor(role);

  IconData _roleIcon(String role) => UserRole.getIcon(role);
}
