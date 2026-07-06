import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class CreerOrdonnanceScreen extends StatefulWidget {
  final UserModel user;
  const CreerOrdonnanceScreen({super.key, required this.user});

  @override
  State<CreerOrdonnanceScreen> createState() =>
      _CreerOrdonnanceScreenState();
}

class _CreerOrdonnanceScreenState extends State<CreerOrdonnanceScreen> {
  List<dynamic> _patients = [];
  Map<String, dynamic>? _patientSelectionne;

  final _instructionsController = TextEditingController();

  // Liste de médicaments saisis dynamiquement
  final List<Map<String, TextEditingController>> _medicaments = [];

  bool _isLoading = true;
  bool _isSaving  = false;
  bool _afficherApercu = false;

  @override
  void initState() {
    super.initState();
    _ajouterLigneMedicament();
    _chargerPatients();
  }

  void _ajouterLigneMedicament() {
    setState(() {
      _medicaments.add({
        'nom':       TextEditingController(),
        'dosage':    TextEditingController(),
        'frequence': TextEditingController(),
        'duree':     TextEditingController(),
      });
    });
  }

  void _supprimerLigneMedicament(int index) {
    setState(() => _medicaments.removeAt(index));
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> _chargerPatients() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() => _patients = data['patients'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur chargement patients: $e');
    }
    setState(() => _isLoading = false);
  }

  String _texteMedicamentsFormate() {
    final lignes = <String>[];
    for (final m in _medicaments) {
      final nom    = m['nom']!.text.trim();
      if (nom.isEmpty) continue;
      final dosage    = m['dosage']!.text.trim();
      final frequence = m['frequence']!.text.trim();
      final duree     = m['duree']!.text.trim();

      var ligne = nom;
      if (dosage.isNotEmpty) ligne += ' — $dosage';
      if (frequence.isNotEmpty) ligne += ', $frequence';
      if (duree.isNotEmpty) ligne += ', pendant $duree';
      lignes.add(ligne);
    }
    return lignes.join('\n');
  }

  Future<void> _enregistrerOrdonnance() async {
    if (_patientSelectionne == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez un patient')),
      );
      return;
    }
    final medicaments = _texteMedicamentsFormate();
    if (medicaments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un médicament')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/medecin/ordonnances'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'patient_id':    _patientSelectionne!['id'],
          'medicaments':   medicaments,
          'instructions':  _instructionsController.text.trim(),
        }),
      );

      debugPrint('Ordonnance status: ${response.statusCode}');
      debugPrint('Ordonnance body: ${response.body}');

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ordonnance créée avec succès !'),
            backgroundColor: Color(0xFF00897B),
          ),
        );
        Navigator.pop(context);
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Erreur')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Créer une ordonnance'),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_afficherApercu
                ? Icons.edit_outlined
                : Icons.visibility_outlined),
            tooltip: _afficherApercu ? 'Modifier' : 'Aperçu',
            onPressed: () =>
                setState(() => _afficherApercu = !_afficherApercu),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _afficherApercu
              ? _buildApercu()
              : _buildFormulaire(),
      bottomNavigationBar: _isSaving
          ? const LinearProgressIndicator()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _enregistrerOrdonnance,
                  icon: const Icon(Icons.check),
                  label: const Text('Enregistrer l\'ordonnance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8E24AA),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
    );
  }

  // ──────────────────────────────────────────────────
  // FORMULAIRE DE SAISIE
  // ──────────────────────────────────────────────────
  Widget _buildFormulaire() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Patient',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333))),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Map<String, dynamic>>(
              isExpanded: true,
              hint: const Text('Sélectionner un patient'),
              value: _patientSelectionne,
              items: _patients.map((p) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: p,
                  child: Text('${p['prenom']} ${p['nom']}'),
                );
              }).toList(),
              onChanged: (val) =>
                  setState(() => _patientSelectionne = val),
            ),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Médicaments',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF333333))),
            TextButton.icon(
              onPressed: _ajouterLigneMedicament,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Ajouter'),
              style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8E24AA)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        ...List.generate(_medicaments.length, (index) {
          final m = _medicaments[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: m['nom'],
                    decoration: const InputDecoration(
                      labelText: 'Médicament',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                if (_medicaments.length > 1)
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.redAccent, size: 20),
                    onPressed: () =>
                        _supprimerLigneMedicament(index),
                  ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: m['dosage'],
                    decoration: const InputDecoration(
                      labelText: 'Dosage (ex: 500mg)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: m['frequence'],
                    decoration: const InputDecoration(
                      labelText: 'Fréquence (ex: 2x/jour)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              TextField(
                controller: m['duree'],
                decoration: const InputDecoration(
                  labelText: 'Durée (ex: 7 jours)',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ]),
          );
        }),

        const SizedBox(height: 16),

        const Text('Instructions complémentaires',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF333333))),
        const SizedBox(height: 8),
        TextField(
          controller: _instructionsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ex: à prendre après les repas, '
                'éviter l\'alcool...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),

        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () => setState(() => _afficherApercu = true),
          icon: const Icon(Icons.remove_red_eye_outlined),
          label: const Text('Aperçu de l\'ordonnance'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF8E24AA),
            minimumSize: const Size.fromHeight(46),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  // ──────────────────────────────────────────────────
  // APERÇU "DOCUMENT MÉDICAL"
  // ──────────────────────────────────────────────────
  Widget _buildApercu() {
    final now = DateFormat('dd/MM/yyyy').format(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── En-tête ──────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.local_hospital,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LaafiBa',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF00897B))),
                      Text(
                        'Dr. ${widget.user.prenom} '
                        '${widget.user.nom}',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333)),
                      ),
                    ],
                  ),
                ),
                Text(now,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600)),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300, thickness: 1.2),
            const SizedBox(height: 16),

            // ── Patient ─────────────────────────────
            const Text('ORDONNANCE MÉDICALE',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                    color: Color(0xFF8E24AA))),
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.person_outline,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _patientSelectionne != null
                    ? 'Patient : '
                      '${_patientSelectionne!['prenom']} '
                      '${_patientSelectionne!['nom']}'
                    : 'Patient : —',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF333333)),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Médicaments ──────────────────────────
            const Text('Prescription',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey)),
            const SizedBox(height: 8),

            ...(_texteMedicamentsFormate().isEmpty
                ? [Text('Aucun médicament saisi',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic))]
                : _texteMedicamentsFormate()
                    .split('\n')
                    .map((ligne) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding:
                                    EdgeInsets.only(top: 2, right: 8),
                                child: Icon(Icons.medication_outlined,
                                    size: 16,
                                    color: Color(0xFF8E24AA)),
                              ),
                              Expanded(
                                child: Text(ligne,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Color(0xFF333333))),
                              ),
                            ],
                          ),
                        ))
                    .toList()),

            if (_instructionsController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Instructions',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey)),
              const SizedBox(height: 6),
              Text(_instructionsController.text.trim(),
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Color(0xFF333333))),
            ],

            const SizedBox(height: 40),
            Divider(color: Colors.grey.shade300, thickness: 1.2),
            const SizedBox(height: 8),

            // ── Signature ────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('Signature et cachet',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500)),
                    const SizedBox(height: 30),
                    Container(
                      width: 140,
                      height: 1,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dr. ${widget.user.prenom} '
                      '${widget.user.nom}',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    for (final m in _medicaments) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }
}
