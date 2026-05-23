import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import '../../widgets/app_widgets.dart';

class VaccinationsScreen extends StatefulWidget {
  final UserModel user;
  const VaccinationsScreen({super.key, required this.user});

  @override
  State<VaccinationsScreen> createState() => _VaccinationsScreenState();
}

class _VaccinationsScreenState extends State<VaccinationsScreen> {
  final _service = PatientService();
  List<dynamic> _vaccinations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final result = await _service.getVaccinations();
    if (result['succes'] == true) {
      setState(() => _vaccinations = result['vaccinations'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterVaccin() async {
    final nomController = TextEditingController();
    final doseController = TextEditingController();
    final dateController = TextEditingController();
    final medecinController = TextEditingController();
    String statut = 'fait';

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
              const Text('Ajouter un vaccin', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              AppTextField(label: 'Nom du vaccin *', hint: 'Ex: BCG, Hépatite B...', prefixIcon: Icons.vaccines_outlined, controller: nomController),
              const SizedBox(height: 12),
              AppTextField(label: 'Dose', hint: 'Ex: 1/3, Rappel...', prefixIcon: Icons.numbers_outlined, controller: doseController),
              const SizedBox(height: 12),
              AppTextField(label: 'Date (AAAA-MM-JJ)', hint: '2026-01-15', prefixIcon: Icons.calendar_today_outlined, controller: dateController),
              const SizedBox(height: 12),
              AppTextField(label: 'Médecin', hint: 'Dr. Nom', prefixIcon: Icons.person_outlined, controller: medecinController),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Statut: ', style: AppTextStyles.label),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Fait'), selected: statut == 'fait',
                    onSelected: (_) => setStateModal(() => statut = 'fait'),
                    selectedColor: AppColors.success.withOpacity(0.2)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('À faire'), selected: statut == 'a_faire',
                    onSelected: (_) => setStateModal(() => statut = 'a_faire'),
                    selectedColor: Colors.orange.withOpacity(0.2)),
              ]),
              const SizedBox(height: 20),
              AppButton(
                text: 'Ajouter',
                icon: Icons.add,
                onPressed: () async {
                  if (nomController.text.isEmpty) return;
                  Navigator.pop(context);
                  final result = await _service.ajouterVaccination({
                    'nom_vaccin': nomController.text,
                    'dose': doseController.text,
                    'date_administration': dateController.text.isEmpty ? null : dateController.text,
                    'administre_par': medecinController.text,
                    'statut': statut,
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

  @override
  Widget build(BuildContext context) {
    final faits = _vaccinations.where((v) => v['statut'] == 'fait').length;
    final aFaire = _vaccinations.where((v) => v['statut'] != 'fait').length;

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
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterVaccin,
        backgroundColor: const Color(0xFF8E24AA),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                decoration: const BoxDecoration(
                  color: Color(0xFF8E24AA),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _statItem('Effectués', '$faits', Icons.check_circle_outline, Colors.greenAccent),
                  _statItem('À faire', '$aFaire', Icons.warning_amber_outlined, Colors.orangeAccent),
                  _statItem('Total', '${_vaccinations.length}', Icons.vaccines_outlined, Colors.white),
                ]),
              ),

              const SizedBox(height: 16),

              _vaccinations.isEmpty
                  ? Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.vaccines_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Aucun vaccin enregistré', style: TextStyle(color: AppColors.textSecondary)),
                    ])))
                  : Expanded(
                      child: RefreshIndicator(
                        onRefresh: _charger,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _vaccinations.length,
                          itemBuilder: (context, index) {
                            final v = _vaccinations[index];
                            final statut = v['statut'] ?? 'non_fait';
                            final color = statut == 'fait' ? AppColors.success
                                : statut == 'a_faire' ? Colors.orange : AppColors.error;
                            final icon = statut == 'fait' ? Icons.check_circle
                                : statut == 'a_faire' ? Icons.schedule : Icons.cancel_outlined;

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
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.vaccines_outlined, color: color, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(v['nom_vaccin'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  if (v['date_administration'] != null)
                                    Text('Date: ${v['date_administration']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  if (v['prochain_rappel'] != null)
                                    Text('Prochain: ${v['prochain_rappel']}', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
                                ])),
                                Icon(icon, color: color, size: 22),
                              ]),
                            );
                          },
                        ),
                      ),
                    ),
            ]),
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
