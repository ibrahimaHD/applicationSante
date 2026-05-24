import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import '../../widgets/app_widgets.dart';

class VaccinationsEnfantsScreen extends StatefulWidget {
  final UserModel user;
  const VaccinationsEnfantsScreen({super.key, required this.user});

  @override
  State<VaccinationsEnfantsScreen> createState() => _VaccinationsEnfantsScreenState();
}

class _VaccinationsEnfantsScreenState extends State<VaccinationsEnfantsScreen> {
  final _service = PatientService();
  List<dynamic> _enfants = [];
  bool _isLoading = true;
  int _enfantSelectionne = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final result = await _service.getEnfants();
    if (result['succes'] == true) {
      setState(() => _enfants = result['enfants'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterEnfant() async {
    final nomController = TextEditingController();
    final prenomController = TextEditingController();
    final dateController = TextEditingController();
    String sexe = 'M';

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
              const Text('Ajouter un enfant', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: AppTextField(label: 'Prénom', hint: 'Prénom', prefixIcon: Icons.person_outline, controller: prenomController)),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(label: 'Nom *', hint: 'Nom', prefixIcon: Icons.person_outline, controller: nomController)),
              ]),
              const SizedBox(height: 12),
              AppTextField(label: 'Date de naissance *', hint: 'JJ/MM/AAAA', prefixIcon: Icons.cake_outlined, controller: dateController),
              const SizedBox(height: 12),
              Row(children: [
                const Text('Sexe: ', style: AppTextStyles.label),
                const SizedBox(width: 12),
                ChoiceChip(label: const Text('Garcon'), selected: sexe == 'M',
                    onSelected: (_) => setStateModal(() => sexe = 'M'),
                    selectedColor: const Color(0xFF1E88E5).withOpacity(0.2)),
                const SizedBox(width: 8),
                ChoiceChip(label: const Text('Fille'), selected: sexe == 'F',
                    onSelected: (_) => setStateModal(() => sexe = 'F'),
                    selectedColor: const Color(0xFFE91E8C).withOpacity(0.2)),
              ]),
              const SizedBox(height: 20),
              AppButton(
                text: 'Ajouter',
                icon: Icons.child_care_outlined,
                color: const Color(0xFF00ACC1),
                onPressed: () async {
                  if (nomController.text.isEmpty || dateController.text.isEmpty) return;
                  Navigator.pop(context);
                  final result = await _service.ajouterEnfant({
                    'nom': nomController.text,
                    'prenom': prenomController.text,
                    'date_naissance': dateController.text,
                    'sexe': sexe,
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

  Future<void> _majVaccin(int vaccinId) async {
    String nouveauStatut = 'fait';
    final dateController = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mettre a jour'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            ChoiceChip(label: const Text('Fait'), selected: nouveauStatut == 'fait',
                onSelected: (_) => nouveauStatut = 'fait',
                selectedColor: AppColors.success.withOpacity(0.2)),
            const SizedBox(width: 8),
            ChoiceChip(label: const Text('A faire'), selected: nouveauStatut == 'a_faire',
                onSelected: (_) => nouveauStatut = 'a_faire',
                selectedColor: Colors.orange.withOpacity(0.2)),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: dateController,
            decoration: const InputDecoration(labelText: 'Date (JJ/MM/AAAA)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.majVaccinEnfant(vaccinId, {
                'statut': nouveauStatut,
                'date_administration': dateController.text,
              });
              _charger();
            },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            onPressed: _ajouterEnfant,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enfants.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.child_care_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aucun enfant enregistre', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _ajouterEnfant,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un enfant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00ACC1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]))
              : Column(children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00ACC1),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(_enfants.length, (i) {
                          final selected = i == _enfantSelectionne;
                          final enfant = _enfants[i];
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
                                  '${enfant['prenom'] ?? ''} ${enfant['nom'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600,
                                    color: selected ? const Color(0xFF00ACC1) : Colors.white,
                                  ),
                                ),
                              ]),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _charger,
                      child: Builder(builder: (context) {
                        final vaccins = (_enfants[_enfantSelectionne]['vaccinations'] as List?) ?? [];
                        if (vaccins.isEmpty) {
                          return const Center(child: Text('Aucun vaccin', style: TextStyle(color: AppColors.textSecondary)));
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: vaccins.length,
                          itemBuilder: (context, index) {
                            final v = vaccins[index];
                            final statut = v['statut'] ?? 'non_fait';
                            final color = statut == 'fait' ? AppColors.success
                                : statut == 'a_faire' ? Colors.orange : AppColors.error;
                            return GestureDetector(
                              onTap: () => _majVaccin(v['id']),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: color.withOpacity(0.3)),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                                ),
                                child: Row(children: [
                                  Icon(statut == 'fait' ? Icons.check_circle : Icons.schedule, color: color, size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(v['nom_vaccin'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    if (v['date_vaccination'] != null)
                                      Text('Administre le ${v['date_vaccination']}',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  ])),
                                  Text(statut == 'fait' ? 'Fait' : 'A faire',
                                      style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                                ]),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ]),
    );
  }
}
