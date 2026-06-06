import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';
 
class CreerOrdonnanceScreen extends StatefulWidget {
  final UserModel user;
  const CreerOrdonnanceScreen({super.key, required this.user});
 
  @override
  State<CreerOrdonnanceScreen> createState() => _OrdonnancesMedecinScreenState();
}
 
class _OrdonnancesMedecinScreenState extends State<CreerOrdonnanceScreen> {
  List<dynamic> _ordonnances = [];
  List<dynamic> _patients = [];
  bool _isLoading = true;
 
  @override
  void initState() {
    super.initState();
    _charger();
  }
 
  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }
 
  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        http.get(Uri.parse('${AppConstants.baseUrl}/medecin/ordonnances'), headers: await _headers()),
        http.get(Uri.parse('${AppConstants.baseUrl}/medecin/patients'), headers: await _headers()),
      ]);
      if (results[0].statusCode == 200) setState(() => _ordonnances = jsonDecode(results[0].body)['ordonnances'] ?? []);
      if (results[1].statusCode == 200) setState(() => _patients = jsonDecode(results[1].body)['patients'] ?? []);
    } catch (e) { debugPrint('Erreur: $e'); }
    setState(() => _isLoading = false);
  }
 
  Future<void> _creerOrdonnance() async {
    int? patientId;
    final medsCtrl = TextEditingController();
    final instrCtrl = TextEditingController();
 
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
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Nouvelle ordonnance', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: patientId,
                onChanged: (v) => setStateModal(() => patientId = v),
                decoration: InputDecoration(
                  filled: true, fillColor: AppColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
                  hintText: 'Sélectionner le patient',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                items: _patients.map((p) => DropdownMenuItem<int>(
                  value: p['id'],
                  child: Text('${p['prenom']} ${p['nom']}'),
                )).toList(),
              ),
              const SizedBox(height: 12),
              AppTextField(label: 'Médicaments *', hint: 'Ex: Paracétamol 500mg - 3x/jour\nAmoxicilline 500mg - 2x/jour', prefixIcon: Icons.medication_outlined, controller: medsCtrl, maxLines: 4),
              const SizedBox(height: 12),
              AppTextField(label: 'Instructions', hint: 'Conseils au patient', prefixIcon: Icons.info_outline, controller: instrCtrl, maxLines: 2),
              const SizedBox(height: 20),
              AppButton(
                text: 'Créer l\'ordonnance',
                icon: Icons.description_outlined,
                color: const Color(0xFF8E24AA),
                onPressed: () async {
                  if (patientId == null || medsCtrl.text.isEmpty) return;
                  Navigator.pop(context);
                  final response = await http.post(
                    Uri.parse('${AppConstants.baseUrl}/medecin/ordonnances'),
                    headers: await _headers(),
                    body: jsonEncode({'patient_id': patientId, 'medicaments': medsCtrl.text, 'instructions': instrCtrl.text}),
                  );
                  final data = jsonDecode(response.body);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(data['message'] ?? ''),
                      backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
                    ));
                    if (data['succes'] == true) _charger();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        title: const Text('Mes ordonnances', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerOrdonnance,
        backgroundColor: const Color(0xFF8E24AA),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvelle', style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ordonnances.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Aucune ordonnance', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                ]))
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ordonnances.length,
                    itemBuilder: (context, index) {
                      final o = _ordonnances[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: const Color(0xFF8E24AA).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.description_outlined, color: Color(0xFF8E24AA), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${o['patient_prenom'] ?? ''} ${o['patient_nom'] ?? ''}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              Text('Du ${o['date_ordonnance'] ?? ''}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ])),
                          ]),
                          const Divider(height: 16),
                          Text(o['medicaments'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                          if (o['instructions'] != null) ...[
                            const SizedBox(height: 6),
                            Text(o['instructions'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                          ],
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
 