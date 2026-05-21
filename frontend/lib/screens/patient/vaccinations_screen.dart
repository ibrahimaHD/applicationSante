import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class VaccinationsScreen extends StatelessWidget {
  final UserModel user;
  const VaccinationsScreen({super.key, required this.user});

  final List<Map<String, dynamic>> _vaccins = const [
    {'nom': 'COVID-19', 'date': '10/03/2024', 'dose': 'Rappel', 'statut': 'fait', 'prochain': null},
    {'nom': 'Grippe saisonnière', 'date': '01/11/2025', 'dose': 'Annuel', 'statut': 'fait', 'prochain': '01/11/2026'},
    {'nom': 'Tétanos', 'date': '15/06/2020', 'dose': 'Rappel', 'statut': 'a_faire', 'prochain': '15/06/2030'},
    {'nom': 'Hépatite B', 'date': '20/01/2010', 'dose': '3/3', 'statut': 'fait', 'prochain': null},
    {'nom': 'Fièvre jaune', 'date': '05/04/2019', 'dose': '1/1', 'statut': 'fait', 'prochain': null},
    {'nom': 'Méningite', 'date': null, 'dose': null, 'statut': 'non_fait', 'prochain': 'Recommandé'},
  ];

  @override
  Widget build(BuildContext context) {
    final faits = _vaccins.where((v) => v['statut'] == 'fait').length;
    final aFaire = _vaccins.where((v) => v['statut'] != 'fait').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        title: const Text('Mes vaccinations',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header stats
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            decoration: const BoxDecoration(
              color: Color(0xFF8E24AA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Effectués', '$faits', Icons.check_circle_outline, Colors.greenAccent),
                _statItem('À faire', '$aFaire', Icons.warning_amber_outlined, Colors.orangeAccent),
                _statItem('Total', '${_vaccins.length}', Icons.vaccines_outlined, Colors.white),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              const Text('Carnet vaccinal', style: AppTextStyles.heading2),
              const Spacer(),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Ajouter'),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFF8E24AA)),
              ),
            ]),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _vaccins.length,
              itemBuilder: (context, index) {
                final v = _vaccins[index];
                final statut = v['statut'] as String;
                final color = statut == 'fait'
                    ? AppColors.success
                    : statut == 'a_faire'
                        ? Colors.orange
                        : AppColors.error;
                final icon = statut == 'fait'
                    ? Icons.check_circle
                    : statut == 'a_faire'
                        ? Icons.schedule
                        : Icons.cancel_outlined;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
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
                      child: Icon(Icons.vaccines_outlined, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v['nom'] as String,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 2),
                        if (v['date'] != null)
                          Text('Dernière dose: ${v['date']}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        if (v['prochain'] != null)
                          Text('Prochain: ${v['prochain']}',
                              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    Icon(icon, color: color, size: 22),
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }
}
