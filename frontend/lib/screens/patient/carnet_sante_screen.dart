import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/patient_service.dart';
import '../../widgets/app_widgets.dart';

class CarnetSanteScreen extends StatefulWidget {
  final UserModel user;
  const CarnetSanteScreen({super.key, required this.user});

  @override
  State<CarnetSanteScreen> createState() => _CarnetSanteScreenState();
}

class _CarnetSanteScreenState extends State<CarnetSanteScreen> {
  final _service = PatientService();
  List<dynamic> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    final result = await _service.getConsultations();
    if (result['succes'] == true) {
      setState(() => _consultations = result['consultations'] ?? []);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterConsultation() async {
    final medecin = TextEditingController();
    final motif = TextEditingController();
    final diagnostic = TextEditingController();
    final traitement = TextEditingController();
    final date = TextEditingController();

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
            const Text('Nouvelle consultation', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            AppTextField(label: 'Médecin', hint: 'Dr. Nom', prefixIcon: Icons.person_outlined, controller: medecin),
            const SizedBox(height: 12),
            AppTextField(label: 'Motif *', hint: 'Raison de la consultation', prefixIcon: Icons.medical_services_outlined, controller: motif),
            const SizedBox(height: 12),
            AppTextField(label: 'Diagnostic', hint: 'Diagnostic posé', prefixIcon: Icons.assignment_outlined, controller: diagnostic),
            const SizedBox(height: 12),
            AppTextField(label: 'Traitement', hint: 'Traitement prescrit', prefixIcon: Icons.medication_outlined, controller: traitement),
            const SizedBox(height: 12),
            AppTextField(label: 'Date *', hint: 'AAAA-MM-JJ', prefixIcon: Icons.calendar_today_outlined, controller: date),
            const SizedBox(height: 20),
            AppButton(
              text: 'Ajouter',
              icon: Icons.add,
              onPressed: () async {
                if (motif.text.isEmpty || date.text.isEmpty) return;
                Navigator.pop(context);
                final result = await _service.ajouterConsultation({
                  'medecin_nom': medecin.text,
                  'motif': motif.text,
                  'diagnostic': diagnostic.text,
                  'traitement': traitement.text,
                  'date_consultation': date.text,
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

  Future<void> _supprimer(int id) async {
    final result = await _service.supprimerConsultation(id);
    if (result['succes'] == true) _charger();
  }

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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterConsultation,
        backgroundColor: const Color(0xFF1E88E5),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations.isEmpty
              ? _buildEmpty()
              : Column(children: [
                  // Stats
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E88E5),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _statItem('Total', '${_consultations.length}', Icons.calendar_today_outlined),
                      _statItem('Cette année', '${_consultations.where((c) => (c['date_consultation'] ?? '').startsWith('2026')).length}', Icons.today_outlined),
                    ]),
                  ),

                  const SizedBox(height: 16),

                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _consultations.length,
                        itemBuilder: (context, index) {
                          final c = _consultations[index];
                          return Dismissible(
                            key: Key('${c['id']}'),
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
                            onDismissed: (_) => _supprimer(c['id']),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E88E5).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.medical_services_outlined, color: Color(0xFF1E88E5), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(c['motif'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  if (c['medecin_nom'] != null)
                                    Text(c['medecin_nom'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  if (c['diagnostic'] != null)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1E88E5).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(c['diagnostic'],
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E88E5))),
                                    ),
                                ])),
                                Text(c['date_consultation'] ?? '',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      const Text('Aucune consultation', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
      const SizedBox(height: 8),
      const Text('Appuyez sur + pour ajouter', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
    ]));
  }
}
