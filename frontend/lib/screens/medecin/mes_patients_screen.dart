import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import 'dossier_patient_screen.dart';

 
class MesPatientsScreen extends StatefulWidget {
  final UserModel user;
  const MesPatientsScreen({super.key, required this.user});
 
  @override
  State<MesPatientsScreen> createState() => _PatientsScreenState();
}
 
class _PatientsScreenState extends State<MesPatientsScreen> {
  List<dynamic> _patients = [];
  List<dynamic> _patientsFiltres = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
 
  @override
  void initState() {
    super.initState();
    _charger();
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
 
  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.tokenKey);
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _patients = data['patients'] ?? [];
          _patientsFiltres = _patients;
        });
      }
    } catch (e) { debugPrint('Erreur: $e'); }
    setState(() => _isLoading = false);
  }
 
  void _filtrer(String query) {
    setState(() {
      _patientsFiltres = _patients.where((p) =>
        '${p['prenom']} ${p['nom']}'.toLowerCase().contains(query.toLowerCase()) ||
        (p['email'] ?? '').toLowerCase().contains(query.toLowerCase())
      ).toList();
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Mes patients',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        // Stats + Recherche
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          color: const Color(0xFF1E88E5),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.people_outline, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Text('${_patients.length} patients', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _filtrer,
              decoration: InputDecoration(
                hintText: 'Rechercher un patient...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ]),
        ),
 
        _isLoading
            ? const Expanded(child: Center(child: CircularProgressIndicator()))
            : _patientsFiltres.isEmpty
                ? Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    const Text('Aucun patient trouvé', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  ])))
                : Expanded(
                    child: RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _patientsFiltres.length,
                        itemBuilder: (context, index) {
                          final p = _patientsFiltres[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => DossierPatientScreen(user: widget.user, patientId: p['id'], patientNom: '${p['prenom']} ${p['nom']}'),
                            )),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                              ),
                              child: Row(children: [
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(colors: [Color(0xFF1E88E5), Color(0xFF00ACC1)]),
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                  child: Center(child: Text(
                                    '${(p['prenom'] ?? 'P')[0]}${(p['nom'] ?? 'N')[0]}',
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                                  )),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${p['prenom'] ?? ''} ${p['nom'] ?? ''}',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  Text(p['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  if (p['derniere_consultation'] != null)
                                    Text('Dernière visite: ${p['derniere_consultation'].toString().substring(0, 10)}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ])),
                                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
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
}