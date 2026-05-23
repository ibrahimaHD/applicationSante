import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import '../../widgets/app_widgets.dart';

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
      setState(() => _rappels[index]['actif'] = result['actif']);
    }
  }

  Future<void> _supprimerRappel(int id) async {
    await _service.supprimerRappel(id);
    _charger();
  }

  Future<void> _ajouterRappel() async {
    final titreController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController();
    final heureController = TextEditingController();
    String type = 'rdv';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
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
              const Text('Nouveau rappel', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              AppTextField(label: 'Titre *', hint: 'Ex: Vaccin grippe', prefixIcon: Icons.title, controller: titreController),
              const SizedBox(height: 12),
              AppTextField(label: 'Description', hint: 'Détails du rappel', prefixIcon: Icons.description_outlined, controller: descController),
              const SizedBox(height: 12),
              // Type
              Wrap(spacing: 8, children: [
                for (final t in ['vaccin', 'traitement', 'rdv', 'mesure'])
                  ChoiceChip(
                    label: Text(t),
                    selected: type == t,
                    onSelected: (_) => setStateModal(() => type = t),
                    selectedColor: const Color(0xFFF4511E).withOpacity(0.2),
                  ),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: AppTextField(label: 'Date', hint: 'JJ/MM/AAAA', prefixIcon: Icons.calendar_today_outlined, controller: dateController)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Heure', hint: 'HH:MM', prefixIcon: Icons.access_time, controller: heureController)),
              ]),
              const SizedBox(height: 20),
              AppButton(
                text: 'Créer le rappel',
                icon: Icons.add_alert_outlined,
                onPressed: () async {
                  if (titreController.text.isEmpty) return;
                  Navigator.pop(context);
                  final result = await _service.ajouterRappel({
                    'titre': titreController.text,
                    'description': descController.text,
                    'type': type,
                    'date_rappel': dateController.text,
                    'heure_rappel': heureController.text,
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
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final actifs = _rappels.where((r) => r['actif'] == true || r['est_actif'] == true).length;

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
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterRappel,
        backgroundColor: const Color(0xFFF4511E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
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
                  _statItem('Actifs', '$actifs', Icons.notifications_active_outlined),
                  _statItem('Total', '${_rappels.length}', Icons.notifications_outlined),
                ]),
              ),

              const SizedBox(height: 16),

              _rappels.isEmpty
                  ? Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Aucun rappel', style: TextStyle(color: AppColors.textSecondary)),
                    ])))
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
                            final actif = r['actif'] == true || r['est_actif'] == true;

                            return Dismissible(
                              key: Key('${r['id']}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              onDismissed: (_) => _supprimerRappel(r['id']),
                              child: Container(
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
                                    Text(r['titre'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    if (r['description'] != null && r['description'].toString().isNotEmpty)
                                      Text(r['description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    if (r['date_rappel'] != null)
                                      Row(children: [
                                        Icon(Icons.access_time, size: 12, color: color),
                                        const SizedBox(width: 4),
                                        Text('${r['date_rappel']} ${r['heure_rappel'] ?? ''}',
                                            style: TextStyle(fontSize: 11, color: color)),
                                      ]),
                                  ])),
                                  Switch(
                                    value: actif,
                                    onChanged: (_) => _toggleRappel(r['id'], index),
                                    activeColor: color,
                                  ),
                                ]),
                              ),
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
