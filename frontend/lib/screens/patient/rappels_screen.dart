import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';

class RappelsScreen extends StatefulWidget {
  final UserModel user;
  const RappelsScreen({super.key, required this.user});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends State<RappelsScreen> {
  final _service = PatientService();
  List<dynamic> _rappels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final result = await _service.getRappels();
    if (result['succes'] == true) {
      setState(() => _rappels = result['rappels'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _toggleRappel(int id, int index) async {
    final result = await _service.toggleRappel(id);
    if (result['succes'] == true) {
      setState(() => _rappels[index]['est_actif'] = result['actif']);
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'vaccin': return const Color(0xFF8E24AA);
      case 'traitement': return const Color(0xFF1E88E5);
      case 'rdv': return const Color(0xFF00897B);
      case 'mesure': return const Color(0xFFF4511E);
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'vaccin': return Icons.vaccines_outlined;
      case 'traitement': return Icons.medication_outlined;
      case 'rdv': return Icons.calendar_today_outlined;
      case 'mesure': return Icons.monitor_heart_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'vaccin': return 'Vaccin';
      case 'traitement': return 'Traitement';
      case 'rdv': return 'Rendez-vous';
      case 'mesure': return 'Mesure';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actifs = _rappels.where((r) => r['est_actif'] == true).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4511E),
        title: const Text('Mes rappels',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Header stats
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF4511E),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _statItem('Actifs', '$actifs', Icons.notifications_active_outlined),
                    _statItem('Total', '${_rappels.length}', Icons.notifications_outlined),
                  ]),
                  const SizedBox(height: 12),
                  // Info message
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(child: Text(
                        'Les rappels sont générés automatiquement par votre médecin et le système.',
                        style: TextStyle(color: Colors.white, fontSize: 11),
                      )),
                    ]),
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              _rappels.isEmpty
                  ? Expanded(child: Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Aucun rappel pour le moment',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Vos rappels apparaîtront ici',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    )))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _charger,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _rappels.length,
                          itemBuilder: (context, index) {
                            final r = _rappels[index];
                            final type = r['type'] ?? 'rdv';
                            final color = _typeColor(type);
                            final actif = r['est_actif'] == true;

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
                                  child: Icon(_typeIcon(type), color: color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(r['titre'] ?? '',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  if (r['description'] != null && r['description'].toString().isNotEmpty)
                                    Text(r['description'],
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(_typeLabel(type),
                                          style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                                    ),
                                    if (r['date_rappel'] != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text('${r['date_rappel']} ${r['heure_rappel'] ?? ''}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                    ],
                                  ]),
                                ])),
                                Switch(
                                  value: actif,
                                  onChanged: (_) => _toggleRappel(r['id'], index),
                                  activeColor: color,
                                ),
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
