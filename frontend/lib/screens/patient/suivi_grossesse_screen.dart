import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import '../../widgets/app_widgets.dart';

class SuiviGrossesseScreen extends StatefulWidget {
  final UserModel user;
  const SuiviGrossesseScreen({super.key, required this.user});

  @override
  State<SuiviGrossesseScreen> createState() => _SuiviGrossesseScreenState();
}

class _SuiviGrossesseScreenState extends State<SuiviGrossesseScreen> {
  final _service = PatientService();
  Map<String, dynamic>? _grossesse;
  List<dynamic> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final result = await _service.getGrossesse();
    if (result['succes'] == true) {
      setState(() {
        _grossesse = result['grossesse'];
        _consultations = result['consultations'] ?? [];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _creerGrossesse() async {
    final dateDebutController = TextEditingController();
    final dateTermeController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Nouveau suivi de grossesse', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Date de début *',
              hint: 'JJ/MM/AAAA',
              prefixIcon: Icons.calendar_today_outlined,
              controller: dateDebutController,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: 'Date d\'accouchement prévue',
              hint: 'JJ/MM/AAAA',
              prefixIcon: Icons.event_outlined,
              controller: dateTermeController,
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Créer le suivi',
              icon: Icons.pregnant_woman_outlined,
              color: const Color(0xFFE91E8C),
              onPressed: () async {
                if (dateDebutController.text.isEmpty) return;
                Navigator.pop(context);
                final result = await _service.creerGrossesse({
                  'date_debut': dateDebutController.text,
                  'date_accouchement_prevue': dateTermeController.text,
                });
                if (result['succes'] == true) _charger();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor: result['succes'] == true ? AppColors.success : AppColors.error,
                  ));
                }
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  Future<void> _majSuivi() async {
    final poidsController = TextEditingController(
        text: _grossesse?['poids_actuel']?.toString() ?? '');
    final tensionController = TextEditingController(
        text: _grossesse?['tension'] ?? '');
    final glycemieController = TextEditingController(
        text: _grossesse?['glycemie'] ?? '');
    final semaineController = TextEditingController(
        text: _grossesse?['semaine_actuelle']?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Mettre à jour le suivi', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            AppTextField(label: 'Semaine actuelle', hint: 'Ex: 24', prefixIcon: Icons.numbers, controller: semaineController, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            AppTextField(label: 'Poids (kg)', hint: 'Ex: 65', prefixIcon: Icons.monitor_weight_outlined, controller: poidsController, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            AppTextField(label: 'Tension', hint: 'Ex: 120/80', prefixIcon: Icons.favorite_outline, controller: tensionController),
            const SizedBox(height: 12),
            AppTextField(label: 'Glycémie', hint: 'Ex: Normal', prefixIcon: Icons.bloodtype_outlined, controller: glycemieController),
            const SizedBox(height: 20),
            AppButton(
              text: 'Mettre à jour',
              icon: Icons.save_outlined,
              color: const Color(0xFFE91E8C),
              onPressed: () async {
                Navigator.pop(context);
                final result = await _service.majGrossesse({
                  'semaine_actuelle': int.tryParse(semaineController.text),
                  'poids_actuel': double.tryParse(poidsController.text),
                  'tension': tensionController.text,
                  'glycemie': glycemieController.text,
                });
                if (result['succes'] == true) _charger();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(result['message'] ?? ''),
                    backgroundColor: result['succes'] == true ? AppColors.success : AppColors.error,
                  ));
                }
              },
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  String _getBabySize(int semaine) {
    if (semaine < 10) return 'Grain de raisin';
    if (semaine < 14) return 'Citron';
    if (semaine < 20) return 'Mangue';
    if (semaine < 28) return 'Aubergine';
    if (semaine < 34) return 'Noix de coco';
    return 'Pastèque';
  }

  @override
  Widget build(BuildContext context) {
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
        actions: [
          if (_grossesse != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: _majSuivi,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _grossesse == null
              ? _buildPasDeGrossesse()
              : _buildSuivi(),
    );
  }

  Widget _buildPasDeGrossesse() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.pregnant_woman_outlined, size: 80, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Aucun suivi de grossesse', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        const Text('Commencez un nouveau suivi', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _creerGrossesse,
          icon: const Icon(Icons.add),
          label: const Text('Créer un suivi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE91E8C),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSuivi() {
    final semaine = _grossesse?['semaine_actuelle'] ?? 1;
    final progression = semaine / 40;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Carte principale
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
                const Text('Semaine', style: TextStyle(color: Colors.white70, fontSize: 13)),
                Text('SA $semaine', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                Text(semaine <= 14 ? '1er trimestre' : semaine <= 28 ? '2ème trimestre' : '3ème trimestre',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ]),
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pregnant_woman_outlined, color: Colors.white, size: 44),
              ),
            ]),
            const SizedBox(height: 16),
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
              Text('${40 - semaine} semaines restantes', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              const Text('SA 40', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // Bébé
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Row(children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: const Color(0xFFE91E8C).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.child_friendly_outlined, color: Color(0xFFE91E8C), size: 30)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Bébé cette semaine', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('Taille d\'une ${_getBabySize(semaine)}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ]),
          ]),
        ),

        const SizedBox(height: 16),

        // Stats santé
        Row(children: [
          Expanded(child: _statCard('Poids', '${_grossesse?['poids_actuel'] ?? '--'} kg', Icons.monitor_weight_outlined, const Color(0xFF1E88E5))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Tension', _grossesse?['tension'] ?? '--', Icons.favorite_outline, const Color(0xFFE91E8C))),
          const SizedBox(width: 12),
          Expanded(child: _statCard('Glycémie', _grossesse?['glycemie'] ?? '--', Icons.bloodtype_outlined, const Color(0xFF00897B))),
        ]),

        const SizedBox(height: 20),

        // Calendrier
        const Align(alignment: Alignment.centerLeft, child: Text('Calendrier prénatal', style: AppTextStyles.heading2)),
        const SizedBox(height: 12),

        ..._consultations.map((c) {
          final fait = c['statut'] == 'fait';
          final color = fait ? AppColors.success : const Color(0xFFE91E8C);
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(fait ? Icons.check_circle_outline : Icons.schedule, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['type_consultation'] ?? c['type'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text('SA ${c['semaine']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              Text(fait ? 'Effectué' : 'À venir',
                  style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            ]),
          );
        }),

        const SizedBox(height: 32),
      ]),
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
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      ]),
    );
  }
}
