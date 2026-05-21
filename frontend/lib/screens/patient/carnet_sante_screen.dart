import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class CarnetSanteScreen extends StatelessWidget {
  final UserModel user;
  const CarnetSanteScreen({super.key, required this.user});

  final List<Map<String, dynamic>> _consultations = const [
    {'date': '15/05/2026', 'medecin': 'Dr. Traoré', 'motif': 'Consultation générale', 'diagnostic': 'Rhinite allergique', 'color': Color(0xFF1E88E5)},
    {'date': '02/04/2026', 'medecin': 'Dr. Ouédraogo', 'motif': 'Douleur abdominale', 'diagnostic': 'Gastrite légère', 'color': Color(0xFF00897B)},
    {'date': '18/02/2026', 'medecin': 'Dr. Kaboré', 'motif': 'Bilan annuel', 'diagnostic': 'Bonne santé générale', 'color': Color(0xFF8E24AA)},
    {'date': '05/01/2026', 'medecin': 'Dr. Traoré', 'motif': 'Fièvre', 'diagnostic': 'Infection virale', 'color': Color(0xFFF4511E)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Carnet de santé',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF1E88E5),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _statItem('Consultations', '12', Icons.calendar_today_outlined),
                _statItem('Cette année', '4', Icons.today_outlined),
                _statItem('Médecins', '3', Icons.person_outlined),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('Historique', style: AppTextStyles.heading2),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF1E88E5)),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _consultations.length,
              itemBuilder: (context, index) {
                final c = _consultations[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: (c['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.medical_services_outlined, color: c['color'] as Color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['motif'] as String,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 2),
                            Text(c['medecin'] as String,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (c['color'] as Color).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(c['diagnostic'] as String,
                                  style: TextStyle(fontSize: 11, color: c['color'] as Color, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Text(c['date'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textSecondary),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
}
