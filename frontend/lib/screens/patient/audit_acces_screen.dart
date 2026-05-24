import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class AuditAccesScreen extends StatefulWidget {
  final UserModel user;
  const AuditAccesScreen({super.key, required this.user});

  @override
  State<AuditAccesScreen> createState() => _AuditAccesScreenState();
}

class _AuditAccesScreenState extends State<AuditAccesScreen> {
  List<dynamic> _audits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/patient/audits'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _audits = data['audits'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'medecin': return const Color(0xFF00897B);
      case 'pharmacien': return const Color(0xFF8E24AA);
      case 'admin': return const Color(0xFF3949AB);
      case 'superadmin': return const Color(0xFFC62828);
      default: return AppColors.primary;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'medecin': return Icons.local_hospital_outlined;
      case 'pharmacien': return Icons.medication_outlined;
      case 'admin': return Icons.admin_panel_settings_outlined;
      case 'superadmin': return Icons.security_outlined;
      default: return Icons.person_outline;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'medecin': return 'Médecin';
      case 'pharmacien': return 'Pharmacien';
      case 'admin': return 'Admin';
      case 'superadmin': return 'Super Admin';
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        title: const Text('Audit des accès',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF37474F),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _statItem('Total accès', '${_audits.length}', Icons.visibility_outlined),
                    _statItem('Médecins', '${_audits.where((a) => a['role_acces'] == 'medecin').length}', Icons.local_hospital_outlined),
                    _statItem('Autres', '${_audits.where((a) => a['role_acces'] != 'medecin').length}', Icons.person_outline),
                  ]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.security_outlined, color: Colors.white70, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Chaque accès à votre dossier est enregistré automatiquement.',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      )),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              _audits.isEmpty
                  ? Expanded(child: Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.visibility_off_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Aucun accès enregistré',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text(
                          'Les accès à votre dossier apparaîtront ici',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _charger,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _audits.length,
                          itemBuilder: (context, index) {
                            final a = _audits[index];
                            final role = a['role_acces'] ?? 'patient';
                            final color = _roleColor(role);
                            final dateStr = a['created_at']?.toString() ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_roleIcon(role), color: color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(
                                    '${a['prenom_acces'] ?? ''} ${a['nom_acces'] ?? ''}'.trim().isEmpty
                                        ? 'Utilisateur inconnu'
                                        : '${a['prenom_acces'] ?? ''} ${a['nom_acces'] ?? ''}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _roleLabel(role),
                                        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        a['type_acces'] ?? 'Consultation dossier',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                ])),
                                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                                  Text(
                                    dateStr.length >= 10 ? dateStr.substring(0, 10) : '--',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  Text(
                                    dateStr.length >= 16 ? dateStr.substring(11, 16) : '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                ]),
                              ]),
                            );
                          },
                        ),
                      ),
                    ),
            ]),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}
