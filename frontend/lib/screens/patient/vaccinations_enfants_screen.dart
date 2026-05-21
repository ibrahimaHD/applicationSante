import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class VaccinationsEnfantsScreen extends StatefulWidget {
  final UserModel user;
  const VaccinationsEnfantsScreen({super.key, required this.user});

  @override
  State<VaccinationsEnfantsScreen> createState() => _VaccinationsEnfantsScreenState();
}

class _VaccinationsEnfantsScreenState extends State<VaccinationsEnfantsScreen> {
  int _enfantSelectionne = 0;

  final List<Map<String, dynamic>> _enfants = [
    {
      'nom': 'Aminata',
      'age': '2 ans',
      'naissance': '15/03/2024',
      'vaccins': [
        {'nom': 'BCG', 'date': '15/03/2024', 'statut': 'fait'},
        {'nom': 'Hépatite B (1)', 'date': '15/03/2024', 'statut': 'fait'},
        {'nom': 'Pentavalent (1)', 'date': '15/05/2024', 'statut': 'fait'},
        {'nom': 'Pentavalent (2)', 'date': '15/07/2024', 'statut': 'fait'},
        {'nom': 'Rougeole', 'date': '15/03/2025', 'statut': 'fait'},
        {'nom': 'Méningite A', 'date': null, 'statut': 'a_faire'},
      ],
    },
    {
      'nom': 'Moussa',
      'age': '5 ans',
      'naissance': '10/08/2020',
      'vaccins': [
        {'nom': 'BCG', 'date': '10/08/2020', 'statut': 'fait'},
        {'nom': 'Hépatite B', 'date': '10/08/2020', 'statut': 'fait'},
        {'nom': 'Pentavalent (1-2-3)', 'date': '10/12/2020', 'statut': 'fait'},
        {'nom': 'Rougeole', 'date': '10/08/2021', 'statut': 'fait'},
        {'nom': 'Rappel DTP', 'date': null, 'statut': 'a_faire'},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final enfant = _enfants[_enfantSelectionne];
    final vaccins = enfant['vaccins'] as List;
    final faits = vaccins.where((v) => v['statut'] == 'fait').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00ACC1),
        title: const Text('Vaccinations enfants',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined, color: Colors.white),
            onPressed: () => _ajouterEnfant(context),
          ),
        ],
      ),
      body: Column(children: [
        // Sélection enfant
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF00ACC1),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(children: [
            Row(
              children: List.generate(_enfants.length, (i) {
                final selected = i == _enfantSelectionne;
                return GestureDetector(
                  onTap: () => setState(() => _enfantSelectionne = i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(children: [
                      Icon(Icons.child_care, size: 16,
                          color: selected ? const Color(0xFF00ACC1) : Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        _enfants[i]['nom'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? const Color(0xFF00ACC1) : Colors.white,
                        ),
                      ),
                    ]),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statItem('Âge', enfant['age'] as String, Icons.cake_outlined),
              _statItem('Effectués', '$faits/${vaccins.length}', Icons.vaccines_outlined),
              _statItem('Naissance', enfant['naissance'] as String, Icons.calendar_today_outlined),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('Carnet de ${enfant['nom']}', style: AppTextStyles.heading2),
            const Spacer(),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Vaccin'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF00ACC1)),
            ),
          ]),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: vaccins.length,
            itemBuilder: (context, index) {
              final v = vaccins[index];
              final fait = v['statut'] == 'fait';
              final color = fait ? AppColors.success : Colors.orange;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                ),
                child: Row(children: [
                  Icon(fait ? Icons.check_circle : Icons.schedule, color: color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v['nom'] as String,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    if (v['date'] != null)
                      Text('Administré le ${v['date']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary))
                    else
                      Text('Non encore administré',
                          style: TextStyle(fontSize: 11, color: Colors.orange[700])),
                  ])),
                  Text(
                    fait ? 'Fait' : 'À faire',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
                  ),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
    ]);
  }

  void _ajouterEnfant(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Ajouter un enfant', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          const Text('Fonctionnalité disponible prochainement', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }
}
