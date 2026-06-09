import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class ExamensMedecinScreen extends StatefulWidget {
  final UserModel user;
  const ExamensMedecinScreen({super.key, required this.user});

  @override
  State<ExamensMedecinScreen> createState() => _ExamensMedecinScreenState();
}

class _ExamensMedecinScreenState extends State<ExamensMedecinScreen> {
  List<dynamic> _patients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chargerPatients();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
  }

  Future<void> _chargerPatients() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        setState(() => _patients = jsonDecode(response.body)['patients'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterExamen() async {
    int? patientId;
    final typeCtrl = TextEditingController();
    final resultatCtrl = TextEditingController();
    final dateCtrl =
        TextEditingController(text: DateTime.now().toString().substring(0, 10));
    String statut = 'normal';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                const Text('Ajouter un examen', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: patientId,
                  onChanged: (v) => setStateModal(() => patientId = v),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.primary, size: 20),
                    hintText: 'Sélectionner le patient',
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: _patients
                      .map((p) => DropdownMenuItem<int>(
                            value: p['id'],
                            child: Text('${p['prenom']} ${p['nom']}'),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'Type d\'examen *',
                    hint: 'Ex: Bilan sanguin, Radio thorax...',
                    prefixIcon: Icons.science_outlined,
                    controller: typeCtrl),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'Résultat',
                    hint: 'Résultat de l\'examen',
                    prefixIcon: Icons.assignment_outlined,
                    controller: resultatCtrl,
                    maxLines: 3),
                const SizedBox(height: 12),
                AppTextField(
                    label: 'Date *',
                    hint: 'AAAA-MM-JJ',
                    prefixIcon: Icons.calendar_today_outlined,
                    controller: dateCtrl),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('Statut: ', style: AppTextStyles.label),
                  const SizedBox(width: 8),
                  ChoiceChip(
                      label: const Text('Normal'),
                      selected: statut == 'normal',
                      onSelected: (_) => setStateModal(() => statut = 'normal'),
                      selectedColor: AppColors.success.withOpacity(0.2)),
                  const SizedBox(width: 6),
                  ChoiceChip(
                      label: const Text('Attention'),
                      selected: statut == 'attention',
                      onSelected: (_) =>
                          setStateModal(() => statut = 'attention'),
                      selectedColor: Colors.orange.withOpacity(0.2)),
                  const SizedBox(width: 6),
                  ChoiceChip(
                      label: const Text('Urgent'),
                      selected: statut == 'urgent',
                      onSelected: (_) => setStateModal(() => statut = 'urgent'),
                      selectedColor: AppColors.error.withOpacity(0.2)),
                ]),
                const SizedBox(height: 20),
                AppButton(
                  text: 'Ajouter l\'examen',
                  icon: Icons.science_outlined,
                  color: const Color(0xFF3949AB),
                  onPressed: () async {
                    if (patientId == null || typeCtrl.text.isEmpty) return;
                    Navigator.pop(context);
                    final response = await http.post(
                      Uri.parse('${AppConstants.baseUrl}/medecin/examens'),
                      headers: await _headers(),
                      body: jsonEncode({
                        'patient_id': patientId,
                        'type_examen': typeCtrl.text, // backend attend 'titre'
                        'titre': typeCtrl.text,
                        'description': resultatCtrl.text,
                        'statut': statut,
                        'date_resultat': dateCtrl.text,
                        'type': 'analyse',
                      }),
                    );
                    final data = jsonDecode(response.body);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(data['message'] ?? ''),
                        backgroundColor: data['succes'] == true
                            ? AppColors.success
                            : AppColors.error,
                      ));
                    }
                  },
                ),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Résultats d\'examens',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10)
                        ],
                      ),
                      child: Column(children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color: const Color(0xFF3949AB).withOpacity(0.1),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.science_outlined,
                              color: Color(0xFF3949AB), size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('Ajouter un résultat d\'examen',
                            style: AppTextStyles.heading2,
                            textAlign: TextAlign.center),
                        const SizedBox(height: 8),
                        const Text(
                          'Les résultats seront automatiquement visibles dans le dossier du patient.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        AppButton(
                          text: 'Ajouter un examen',
                          icon: Icons.add,
                          color: const Color(0xFF3949AB),
                          onPressed: _ajouterExamen,
                        ),
                      ]),
                    ),
                    Text('${_patients.length} patient(s) disponible(s)',
                        style: const TextStyle(color: AppColors.textSecondary)),
                  ]),
            ),
    );
  }
}
