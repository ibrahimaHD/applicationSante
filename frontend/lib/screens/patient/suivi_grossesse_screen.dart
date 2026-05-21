import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class SuiviGrossesseScreen extends StatefulWidget {
  final UserModel user;
  const SuiviGrossesseScreen({super.key, required this.user});

  @override
  State<SuiviGrossesseScreen> createState() => _SuiviGrossesseScreenState();
}

class _SuiviGrossesseScreenState extends State<SuiviGrossesseScreen> {
  int _semaineActuelle = 24;
  final int _totalSemaines = 40;

  final List<Map<String, dynamic>> _consultations = [
    {'semaine': 8, 'date': '10/01/2026', 'type': 'Écho 1er trim.', 'statut': 'fait'},
    {'semaine': 12, 'date': '10/02/2026', 'type': 'Bilan sanguin', 'statut': 'fait'},
    {'semaine': 20, 'date': '15/04/2026', 'type': 'Écho morpho.', 'statut': 'fait'},
    {'semaine': 28, 'date': '20/06/2026', 'type': 'Écho 3ème trim.', 'statut': 'a_venir'},
    {'semaine': 32, 'date': '20/07/2026', 'type': 'Consultation', 'statut': 'a_venir'},
    {'semaine': 36, 'date': '17/08/2026', 'type': 'Préparation accouchement', 'statut': 'a_venir'},
  ];

  String _getTrimestreInfo() {
    if (_semaineActuelle <= 14) return '1er trimestre';
    if (_semaineActuelle <= 28) return '2ème trimestre';
    return '3ème trimestre';
  }

  String _getBabySize() {
    if (_semaineActuelle < 10) return 'Grain de raisin';
    if (_semaineActuelle < 14) return 'Citron';
    if (_semaineActuelle < 20) return 'Mangue';
    if (_semaineActuelle < 28) return 'Aubergine';
    if (_semaineActuelle < 34) return 'Noix de coco';
    return 'Pastèque';
  }

  @override
  Widget build(BuildContext context) {
    final progression = _semaineActuelle / _totalSemaines;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE91E8C),
        title: const Text('Suivi de grossesse',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Carte principale semaine
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E8C), Color(0xFFFF6B9D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Semaine de grossesse',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('SA $_semaineActuelle',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  Text(_getTrimestreInfo(),
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pregnant_woman_outlined, color: Colors.white, size: 44),
                ),
              ]),
              const SizedBox(height: 16),
              // Barre de progression
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progression,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Début', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text('${(_totalSemaines - _semaineActuelle)} semaines restantes',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const Text('SA 40', style: TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ]),
          ),

          const SizedBox(height: 20),

          // Bébé cette semaine
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Row(children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E8C).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.child_friendly_outlined, color: Color(0xFFE91E8C), size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Bébé cette semaine', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text('Taille d\'une ${_getBabySize()}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const Text('Développement normal', style: TextStyle(fontSize: 12, color: AppColors.success)),
              ])),
            ]),
          ),

          const SizedBox(height: 20),

          // Stats santé
          Row(children: [
            Expanded(child: _statCard('Poids', '65 kg', Icons.monitor_weight_outlined, const Color(0xFF1E88E5))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Tension', '120/80', Icons.favorite_outline, const Color(0xFFE91E8C))),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Glycémie', 'Normal', Icons.bloodtype_outlined, const Color(0xFF00897B))),
          ]),

          const SizedBox(height: 20),

          // Calendrier consultations
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Calendrier prénatal', style: AppTextStyles.heading2),
          ),
          const SizedBox(height: 12),

          ..._consultations.map((c) {
            final fait = c['statut'] == 'fait';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: fait ? AppColors.success.withOpacity(0.3) : const Color(0xFFE91E8C).withOpacity(0.3),
                ),
              ),
              child: Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: fait ? AppColors.success.withOpacity(0.1) : const Color(0xFFE91E8C).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    fait ? Icons.check_circle_outline : Icons.schedule,
                    color: fait ? AppColors.success : const Color(0xFFE91E8C),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c['type'] as String,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text('SA ${c['semaine']} - ${c['date']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ])),
                Text(
                  fait ? 'Effectué' : 'À venir',
                  style: TextStyle(
                    fontSize: 12,
                    color: fait ? AppColors.success : const Color(0xFFE91E8C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ]),
            );
          }),

          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}
