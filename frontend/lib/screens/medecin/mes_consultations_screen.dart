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
  State<MesConsultationsScreen> createState() =>
      _MesConsultationsScreenState();
}

class _MesConsultationsScreenState extends State<MesConsultationsScreen> {
  List<dynamic> _patients = [];
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
      final headers = await _headers();

      final results = await Future.wait([
        // ✅ CORRECTION : /medecins/ → /medecin/
        http.get(
          Uri.parse('${AppConstants.baseUrl}/medecin/patients'),
          headers: headers,
        ),
        // ✅ CORRECTION : /medecins/ → /medecin/
        http.get(
          Uri.parse('${AppConstants.baseUrl}/medecin/consultations'),
          headers: headers,
        ),
      ]);

      if (results[0].statusCode == 200) {
        setState(() =>
            _patients = jsonDecode(results[0].body)['patients'] ?? []);
      }
      if (results[1].statusCode == 200) {
        setState(() =>
            _consultations =
                jsonDecode(results[1].body)['consultations'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterConsultation() async {
    int? patientId;
    final motifCtrl   = TextEditingController();
    final diagCtrl    = TextEditingController();
    final traitCtrl   = TextEditingController();
    final notesCtrl   = TextEditingController();
    final dateCtrl    = TextEditingController(
      text: () {
        final now = DateTime.now();
        return '${now.day.toString().padLeft(2,'0')}/'
               '${now.month.toString().padLeft(2,'0')}/'
               '${now.year}';
      }(),
    );
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setStateModal) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Nouvelle consultation',
                      style: AppTextStyles.heading2),
                  const SizedBox(height: 20),

                  // Sélection patient
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Patient *', style: AppTextStyles.label),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: patientId,
                        onChanged: (v) =>
                            setStateModal(() => patientId = v),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                              size: 20),
                          hintText: 'Sélectionner le patient',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                        items: _patients.map((p) {
                          final id = p['id'] is int
                              ? p['id'] as int
                              : int.tryParse(p['id'].toString()) ?? 0;
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(
                              '${p['prenom'] ?? ''} ${p['nom'] ?? ''}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Motif *',
                    hint: 'Raison de la consultation',
                    prefixIcon: Icons.medical_services_outlined,
                    controller: motifCtrl,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Diagnostic',
                    hint: 'Diagnostic posé',
                    prefixIcon: Icons.assignment_outlined,
                    controller: diagCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Traitement',
                    hint: 'Traitement prescrit',
                    prefixIcon: Icons.medication_outlined,
                    controller: traitCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Notes',
                    hint: 'Observations complémentaires',
                    prefixIcon: Icons.notes_outlined,
                    controller: notesCtrl,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Date *',
                    hint: 'JJ/MM/AAAA',
                    prefixIcon: Icons.calendar_today_outlined,
                    controller: dateCtrl,
                    keyboardType: TextInputType.datetime,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ))
                          : const Icon(Icons.save_outlined, size: 20),
                      label: Text(
                        isSubmitting
                            ? 'Enregistrement...'
                            : 'Enregistrer la consultation',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (patientId == null) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Sélectionnez un patient'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              if (motifCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Motif requis'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              if (dateCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Date requise'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              setStateModal(() => isSubmitting = true);

                              try {
                                // Convertir JJ/MM/AAAA → AAAA-MM-JJ
                                String dateFormatee = dateCtrl.text.trim();
                                if (dateFormatee.contains('/')) {
                                  final p = dateFormatee.split('/');
                                  if (p.length == 3) {
                                    dateFormatee =
                                        '${p[2]}-${p[1].padLeft(2,'0')}-${p[0].padLeft(2,'0')}';
                                  }
                                }

                                final body = {
                                  'patient_id': patientId,
                                  'motif': motifCtrl.text.trim(),
                                  'diagnostic': diagCtrl.text.trim(),
                                  'traitement': traitCtrl.text.trim(),
                                  'notes': notesCtrl.text.trim(),
                                  'date_consultation': dateFormatee,
                                };

                                debugPrint('Envoi consultation: $body');

                                // ✅ CORRECTION : /medecins/ → /medecin/
                                final response = await http.post(
                                  Uri.parse(
                                      '${AppConstants.baseUrl}/medecin/consultations'),
                                  headers: await _headers(),
                                  body: jsonEncode(body),
                                );

                                debugPrint(
                                    'Réponse: ${response.statusCode} — ${response.body}');

                                final data = jsonDecode(response.body);

                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(data['message'] ?? ''),
                                    backgroundColor: data['succes'] == true
                                        ? AppColors.success
                                        : AppColors.error,
                                  ));
                                  if (data['succes'] == true) {
                                    _charger();
                                  }
                                }
                              } catch (e) {
                                debugPrint('Erreur: $e');
                                setStateModal(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text('Erreur réseau: $e'),
                                    backgroundColor: AppColors.error,
                                  ));
                                }
                              }
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    motifCtrl.dispose();
    diagCtrl.dispose();
    traitCtrl.dispose();
    notesCtrl.dispose();
    dateCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Mes consultations',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
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
        label: const Text('Nouvelle',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.medical_services_outlined,
                          size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('Aucune consultation',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _ajouterConsultation,
                        icon: const Icon(Icons.add),
                        label: const Text('Ajouter une consultation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _consultations.length,
                    itemBuilder: (context, index) {
                      final c = _consultations[index]
                          as Map<String, dynamic>;
                      final dateStr =
                          c['date_consultation']?.toString() ?? '';
                      final dateAffichee = dateStr.contains('T')
                          ? dateStr.split('T')[0]
                          : dateStr.length >= 10
                              ? dateStr.substring(0, 10)
                              : dateStr;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00897B)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                    Icons.medical_services_outlined,
                                    color: Color(0xFF00897B),
                                    size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c['motif']?.toString() ?? '',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary),
                                  ),
                                  Text(
                                    '${c['patient_prenom'] ?? ''} ${c['patient_nom'] ?? ''}'
                                        .trim(),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              )),
                              Text(dateAffichee,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ]),
                            if ((c['diagnostic']?.toString().isNotEmpty ?? false)) ...[
                              const Divider(height: 14),
                              _infoRow('Diagnostic', c['diagnostic'].toString()),
                            ],
                            if ((c['traitement']?.toString().isNotEmpty ?? false))
                              _infoRow('Traitement', c['traitement'].toString()),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary)),
        ),
      ]),
    );
  }
}