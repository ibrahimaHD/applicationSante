import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class MesConsultationsScreen extends StatefulWidget {
  final UserModel user;
  const MesConsultationsScreen({super.key, required this.user});

  @override
  State<MesConsultationsScreen> createState() => _MesConsultationsScreenState();
}

class _MesConsultationsScreenState extends State<MesConsultationsScreen> {
  List<dynamic> _consultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/consultations'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _consultations = data['consultations'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur chargement consultations: $e');
    }
    setState(() => _isLoading = false);
  }

  // ── Formulaire d'ajout ────────────────────────────────────────────
  Future<void> _ajouterConsultation() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormulaireConsultation(
        headers: _headers,
        onSuccess: () {
          _charger();
          _snack('Consultation enregistrée !', AppColors.success);
        },
      ),
    );
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Mes consultations',
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _charger,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterConsultation,
        backgroundColor: const Color(0xFF00897B),
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Nouvelle', style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        // Stats header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF00897B),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('Total', '${_consultations.length}', Icons.medical_services_outlined),
            _statItem(
              "Aujourd'hui",
              '${_consultations.where((c) {
                final d = c['date_consultation']?.toString() ?? '';
                final today = DateTime.now();
                return d.startsWith(
                    '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}');
              }).length}',
              Icons.today_outlined,
            ),
            _statItem(
              'Ce mois',
              '${_consultations.where((c) {
                final d = c['date_consultation']?.toString() ?? '';
                final today = DateTime.now();
                return d.startsWith(
                    '${today.year}-${today.month.toString().padLeft(2, '0')}');
              }).length}',
              Icons.calendar_month_outlined,
            ),
          ]),
        ),

        // Liste
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _consultations.isEmpty
                  ? _buildVide()
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _consultations.length,
                        itemBuilder: (_, i) => _carteConsultation(_consultations[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _carteConsultation(Map<String, dynamic> c) {
    final nomPatient =
        '${c['patient_prenom'] ?? ''} ${c['patient_nom'] ?? ''}'.trim();
    final date = c['date_consultation']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medical_services_outlined,
              color: Color(0xFF00897B), size: 22),
        ),
        title: Text(
          c['motif'] ?? '—',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(nomPatient.isEmpty ? 'Patient inconnu' : nomPatient,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            Text(date,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          if ((c['diagnostic'] ?? '').toString().isNotEmpty)
            _ligneDetail(Icons.assignment_outlined, 'Diagnostic', c['diagnostic']),
          if ((c['traitement'] ?? '').toString().isNotEmpty)
            _ligneDetail(Icons.medication_outlined, 'Traitement', c['traitement']),
          if ((c['notes'] ?? '').toString().isNotEmpty)
            _ligneDetail(Icons.notes_outlined, 'Notes', c['notes']),
        ],
      ),
    );
  }

  Widget _ligneDetail(IconData icon, String label, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary))),
        Expanded(
            child: Text(valeur,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _statItem(String label, String valeur, IconData icon) {
    return Column(children: [
      Icon(icon, color: Colors.white70, size: 20),
      const SizedBox(height: 4),
      Text(valeur,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700)),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    ]);
  }

  Widget _buildVide() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Aucune consultation',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        const Text('Appuyez sur + pour créer',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// FORMULAIRE SÉPARÉ (bottom sheet)
// ─────────────────────────────────────────────────────────────────────
class _FormulaireConsultation extends StatefulWidget {
  final Future<Map<String, String>> Function() headers;
  final VoidCallback onSuccess;

  const _FormulaireConsultation({
    required this.headers,
    required this.onSuccess,
  });

  @override
  State<_FormulaireConsultation> createState() =>
      _FormulaireConsultationState();
}

class _FormulaireConsultationState extends State<_FormulaireConsultation> {
  final _formKey = GlobalKey<FormState>();

  // Sélection patient
  List<dynamic> _patients = [];
  List<dynamic> _patientsFiltres = [];
  int? _patientId;
  String _nomPatientChoisi = '';
  bool _chargementPatients = true;
  final _searchController = TextEditingController();

  // Champs consultation
  final _motifCtrl       = TextEditingController();
  final _diagCtrl        = TextEditingController();
  final _traitCtrl       = TextEditingController();
  final _notesCtrl       = TextEditingController();
  final _dateCtrl        = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10));

  bool _enregistrement = false;
  int _etape = 0; // 0 = choix patient, 1 = formulaire

  @override
  void initState() {
    super.initState();
    _chargerPatients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _motifCtrl.dispose();
    _diagCtrl.dispose();
    _traitCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerPatients() async {
    try {
      // Essaie d'abord mes patients (ceux avec consultation existante)
      final h = await widget.headers();
      final r1 = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients'),
        headers: h,
      );
      // Puis tous les patients enregistrés
      final r2 = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients/tous'),
        headers: h,
      );

      final Set<int> ids = {};
      final List<dynamic> tous = [];

      void ajouterSiNouveau(List<dynamic> liste) {
        for (final p in liste) {
          final id = p['id'] as int?;
          if (id != null && !ids.contains(id)) {
            ids.add(id);
            tous.add(p);
          }
        }
      }

      if (r1.statusCode == 200) {
        ajouterSiNouveau(jsonDecode(r1.body)['patients'] ?? []);
      }
      if (r2.statusCode == 200) {
        ajouterSiNouveau(jsonDecode(r2.body)['patients'] ?? []);
      }

      tous.sort((a, b) =>
          '${a['nom']}'.compareTo('${b['nom']}'));

      if (mounted) {
        setState(() {
          _patients       = tous;
          _patientsFiltres = tous;
          _chargementPatients = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _chargementPatients = false);
    }
  }

  void _filtrerPatients(String q) {
    setState(() {
      _patientsFiltres = q.isEmpty
          ? _patients
          : _patients.where((p) {
              final nom = '${p['prenom'] ?? ''} ${p['nom'] ?? ''}'.toLowerCase();
              final email = (p['email'] ?? '').toLowerCase();
              return nom.contains(q.toLowerCase()) ||
                  email.contains(q.toLowerCase());
            }).toList();
    });
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patientId == null) return;

    setState(() => _enregistrement = true);

    try {
      final h = await widget.headers();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/medecin/consultations'),
        headers: h,
        body: jsonEncode({
          'patient_id':       _patientId,
          'motif':            _motifCtrl.text.trim(),
          'diagnostic':       _diagCtrl.text.trim(),
          'traitement':       _traitCtrl.text.trim(),
          'notes':            _notesCtrl.text.trim(),
          'date_consultation': _dateCtrl.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (mounted) {
        Navigator.pop(context); // ferme le bottom sheet
        if (data['succes'] == true) {
          widget.onSuccess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(data['message'] ?? 'Erreur'),
            backgroundColor: AppColors.error,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur réseau : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _enregistrement = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _etape == 0 ? _buildEtapePatient() : _buildEtapeFormulaire(),
        ),
      ),
    );
  }

  // ── ÉTAPE 1 : Choisir un patient ──────────────────────────────────
  Widget _buildEtapePatient() {
    return Column(
      key: const ValueKey('patient'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _poignee(),
        const SizedBox(height: 12),
        const Text('Nouvelle consultation',
            style: AppTextStyles.heading2),
        const SizedBox(height: 4),
        const Text('Sélectionnez le patient',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 16),

        // Recherche
        TextField(
          controller: _searchController,
          onChanged: _filtrerPatients,
          decoration: InputDecoration(
            hintText: 'Rechercher par nom ou email…',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: AppColors.inputFill,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),

        const SizedBox(height: 12),

        // Liste patients
        SizedBox(
          height: 280,
          child: _chargementPatients
              ? const Center(child: CircularProgressIndicator())
              : _patientsFiltres.isEmpty
                  ? Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Icon(Icons.person_search_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 8),
                        const Text('Aucun patient trouvé',
                            style: TextStyle(
                                color: AppColors.textSecondary)),
                      ]))
                  : ListView.builder(
                      itemCount: _patientsFiltres.length,
                      itemBuilder: (_, i) {
                        final p = _patientsFiltres[i];
                        final selected = p['id'] == _patientId;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _patientId = p['id'];
                            _nomPatientChoisi =
                                '${p['prenom'] ?? ''} ${p['nom'] ?? ''}'
                                    .trim();
                          }),
                          child: Container(
                            margin:
                                const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF00897B)
                                      .withOpacity(0.08)
                                  : Colors.grey[50],
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF00897B)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF00897B)
                                      : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${(p['prenom'] ?? 'P')[0]}${(p['nom'] ?? 'N')[0]}'
                                        .toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                Text(
                                  '${p['prenom'] ?? ''} ${p['nom'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? const Color(0xFF00897B)
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                Text(p['email'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color:
                                            AppColors.textSecondary)),
                              ])),
                              if (selected)
                                const Icon(Icons.check_circle,
                                    color: Color(0xFF00897B), size: 20),
                            ]),
                          ),
                        );
                      },
                    ),
        ),

        const SizedBox(height: 16),

        AppButton(
          text: 'Continuer',
          icon: Icons.arrow_forward_rounded,
          color: const Color(0xFF00897B),
          onPressed: _patientId == null ? null : () => setState(() => _etape = 1),
        ),
      ],
    );
  }

  // ── ÉTAPE 2 : Formulaire consultation ─────────────────────────────
  Widget _buildEtapeFormulaire() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          key: const ValueKey('form'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _poignee(),
            const SizedBox(height: 12),

            // En-tête avec patient sélectionné
            Row(children: [
              GestureDetector(
                onTap: () => setState(() => _etape = 0),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  const Text('Nouvelle consultation',
                      style: AppTextStyles.heading2),
                  Row(children: [
                    const Icon(Icons.person_outline,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(_nomPatientChoisi,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF00897B),
                            fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
            ]),

            const SizedBox(height: 20),

            AppTextField(
              label: 'Motif *',
              hint: 'Raison de la consultation',
              prefixIcon: Icons.medical_services_outlined,
              controller: _motifCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Le motif est requis' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Diagnostic',
              hint: 'Diagnostic posé',
              prefixIcon: Icons.assignment_outlined,
              controller: _diagCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Traitement',
              hint: 'Traitement prescrit',
              prefixIcon: Icons.medication_outlined,
              controller: _traitCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Notes complémentaires',
              hint: 'Observations, recommandations…',
              prefixIcon: Icons.notes_outlined,
              controller: _notesCtrl,
              maxLines: 2,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Date *',
              hint: 'AAAA-MM-JJ',
              prefixIcon: Icons.calendar_today_outlined,
              controller: _dateCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'La date est requise' : null,
            ),

            const SizedBox(height: 24),

            AppButton(
              text: 'Enregistrer la consultation',
              icon: Icons.save_outlined,
              color: const Color(0xFF00897B),
              onPressed: _enregistrement ? null : _enregistrer,
              isLoading: _enregistrement,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _poignee() => Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
            color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
      );
}