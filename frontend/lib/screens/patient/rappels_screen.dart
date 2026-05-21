import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class RappelsScreen extends StatefulWidget {
  final UserModel user;
  const RappelsScreen({super.key, required this.user});

  @override
  State<RappelsScreen> createState() => _RappelsScreenState();
}

class _RappelsScreenState extends State<RappelsScreen> {
  final List<Map<String, dynamic>> _rappels = [
    {'titre': 'Vaccin grippe', 'description': 'Rappel annuel vaccin antigrippal', 'date': '01/11/2026', 'heure': '09:00', 'type': 'vaccin', 'actif': true},
    {'titre': 'Metformine 500mg', 'description': 'Prendre avec le repas du soir', 'date': 'Quotidien', 'heure': '20:00', 'type': 'traitement', 'actif': true},
    {'titre': 'Consultation Dr. Traoré', 'description': 'Bilan de suivi trimestriel', 'date': '25/05/2026', 'heure': '14:30', 'type': 'rdv', 'actif': true},
    {'titre': 'Prise de tension', 'description': 'Mesure tension artérielle', 'date': 'Quotidien', 'heure': '08:00', 'type': 'mesure', 'actif': false},
  ];

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

  @override
  Widget build(BuildContext context) {
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => _ajouterRappel(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFFF4511E),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statItem('Actifs', '${_rappels.where((r) => r['actif'] == true).length}', Icons.notifications_active_outlined),
              _statItem('Aujourd\'hui', '2', Icons.today_outlined),
              _statItem('Cette semaine', '3', Icons.date_range_outlined),
            ]),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text('Tous les rappels', style: AppTextStyles.heading2),
            ),
          ),

          const SizedBox(height: 12),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _rappels.length,
              itemBuilder: (context, index) {
                final r = _rappels[index];
                final color = _typeColor(r['type'] as String);
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_typeIcon(r['type'] as String), color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r['titre'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(r['description'] as String,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Icon(Icons.access_time, size: 12, color: color),
                          const SizedBox(width: 4),
                          Text('${r['date']} à ${r['heure']}',
                              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500)),
                        ]),
                      ]),
                    ),
                    Switch(
                      value: r['actif'] as bool,
                      onChanged: (val) => setState(() => _rappels[index]['actif'] = val),
                      activeColor: color,
                    ),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _ajouterRappel(context),
        backgroundColor: const Color(0xFFF4511E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
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

  void _ajouterRappel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Nouveau rappel', style: AppTextStyles.heading2),
            const SizedBox(height: 20),
            const Text('Fonctionnalité disponible prochainement',
                style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}
