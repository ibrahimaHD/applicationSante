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
  State<MesConsultationsScreen> createState() => _ConsultationScreenState();
}
 
class _ConsultationScreenState extends State<MesConsultationsScreen> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> _patients = [];
  int? _patientSelectionne;
  bool _isLoading = false;
  bool _isLoadingPatients = true;
 
  final _motifCtrl = TextEditingController();
  final _diagCtrl = TextEditingController();
  final _traitCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController(
      text: DateTime.now().toString().substring(0, 10));
 
  @override
  void initState() {
    super.initState();
    _chargerPatients();
  }
 
  @override
  void dispose() {
    _motifCtrl.dispose();
    _diagCtrl.dispose();
    _traitCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }
 
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }
 
  Future<void> _chargerPatients() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        setState(() => _patients = jsonDecode(response.body)['patients'] ?? []);
      }
    } catch (e) { debugPrint('Erreur: $e'); }
    setState(() => _isLoadingPatients = false);
  }
 
  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_patientSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un patient'), backgroundColor: AppColors.error),
      );
      return;
    }
 
    setState(() => _isLoading = true);
 
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/medecin/consultations'),
      headers: await _headers(),
      body: jsonEncode({
        'patient_id': _patientSelectionne,
        'motif': _motifCtrl.text,
        'diagnostic': _diagCtrl.text,
        'traitement': _traitCtrl.text,
        'notes': _notesCtrl.text,
        'date_consultation': _dateCtrl.text,
      }),
    );
 
    setState(() => _isLoading = false);
    final data = jsonDecode(response.body);
 
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? ''),
        backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
      ));
      if (data['succes'] == true) Navigator.pop(context);
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF00897B),
        title: const Text('Nouvelle consultation',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  // Sélection patient
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.person_outline, color: Color(0xFF00897B), size: 18),
                        SizedBox(width: 8),
                        Text('Patient', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ]),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _patientSelectionne,
                        onChanged: (v) => setState(() => _patientSelectionne = v),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          prefixIcon: const Icon(Icons.search, size: 18),
                          hintText: 'Sélectionner un patient',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        items: _patients.map((p) => DropdownMenuItem<int>(
                          value: p['id'],
                          child: Text('${p['prenom']} ${p['nom']}'),
                        )).toList(),
                      ),
                    ]),
                  ),
 
                  const SizedBox(height: 16),
 
                  // Formulaire consultation
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.medical_services_outlined, color: Color(0xFF00897B), size: 18),
                        SizedBox(width: 8),
                        Text('Consultation', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ]),
                      const SizedBox(height: 16),
                      AppTextField(
                        label: 'Motif *',
                        hint: 'Raison de la consultation',
                        prefixIcon: Icons.medical_services_outlined,
                        controller: _motifCtrl,
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Diagnostic',
                        hint: 'Diagnostic posé',
                        prefixIcon: Icons.assignment_outlined,
                        controller: _diagCtrl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Traitement',
                        hint: 'Traitement prescrit',
                        prefixIcon: Icons.medication_outlined,
                        controller: _traitCtrl,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        label: 'Notes',
                        hint: 'Observations complémentaires',
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
                        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ]),
                  ),
 
                  const SizedBox(height: 24),
 
                  AppButton(
                    text: 'Enregistrer la consultation',
                    onPressed: _enregistrer,
                    isLoading: _isLoading,
                    color: const Color(0xFF00897B),
                    icon: Icons.save_outlined,
                  ),
 
                  const SizedBox(height: 32),
                ]),
              ),
            ),
    );
  }
}