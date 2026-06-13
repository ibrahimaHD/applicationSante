import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class ResultatsMedecinScreen extends StatefulWidget {
  final UserModel user;
  final int? patientId;
  final String? patientNom;

  const ResultatsMedecinScreen({
    super.key,
    required this.user,
    this.patientId,
    this.patientNom,
  });

  @override
  State<ResultatsMedecinScreen> createState() => _ResultatsMedecinScreenState();
}

class _ResultatsMedecinScreenState extends State<ResultatsMedecinScreen> {
  List<dynamic> _resultats = [];
  List<dynamic> _patients  = [];
  bool _isLoading = true;

  static const Color _accent = Color(0xFF3949AB);

  // ── Types d'examens ───────────────────────────────────
  static const Map<String, Map<String, dynamic>> _types = {
    'analyse_sang':  {'label': 'Analyse de sang',  'icon': Icons.bloodtype_outlined,       'color': Color(0xFFE53935)},
    'analyse_urine': {'label': 'Analyse d\'urine', 'icon': Icons.water_drop_outlined,      'color': Color(0xFFFB8C00)},
    'irm':           {'label': 'IRM',               'icon': Icons.psychology_outlined,      'color': Color(0xFF8E24AA)},
    'echographie':   {'label': 'Échographie',       'icon': Icons.monitor_heart_outlined,   'color': Color(0xFF00ACC1)},
    'radiographie':  {'label': 'Radiographie',      'icon': Icons.image_outlined,           'color': Color(0xFF3949AB)},
    'scanner':       {'label': 'Scanner',           'icon': Icons.document_scanner_outlined,'color': Color(0xFF1E88E5)},
    'ecg':           {'label': 'ECG',               'icon': Icons.favorite_outline,         'color': Color(0xFFE53935)},
    'autre':         {'label': 'Autre',             'icon': Icons.science_outlined,         'color': Color(0xFF43A047)},
  };

  // ── Init ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _charger();
    if (widget.patientId == null) _chargerPatients();
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
      String url = '${AppConstants.baseUrl}/medecin/resultats';
      if (widget.patientId != null) url += '?patient_id=${widget.patientId}';
      final r = await http.get(Uri.parse(url), headers: headers);
      if (r.statusCode == 200) {
        setState(() => _resultats = jsonDecode(r.body)['resultats'] ?? []);
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _chargerPatients() async {
    try {
      final headers = await _headers();
      final r = await http.get(
        Uri.parse('${AppConstants.baseUrl}/medecin/patients/tous'),
        headers: headers,
      );
      if (r.statusCode == 200) {
        setState(() => _patients = jsonDecode(r.body)['patients'] ?? []);
      }
    } catch (_) {}
  }

  // ── Formulaire d'ajout ────────────────────────────────
  Future<void> _ajouterResultat() async {
    int?   selectedPatientId = widget.patientId;
    String selectedType      = 'analyse_sang';
    String selectedStatut    = 'normal';

    final resultatCtrl   = TextEditingController();
    final conclusionCtrl = TextEditingController();
    final observCtrl     = TextEditingController();
    final dateCtrl       = TextEditingController(
        text: DateTime.now().toIso8601String().substring(0, 10));

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setMod) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Poignée
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 16),

                Text(
                  widget.patientNom != null
                      ? 'Résultat — ${widget.patientNom}'
                      : 'Nouveau résultat médical',
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Sélection patient ────────────────────
                if (widget.patientId == null) ...[
                  _label('Patient *'),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: selectedPatientId,
                    onChanged: (v) => setMod(() => selectedPatientId = v),
                    decoration: _inputDeco(Icons.person_outline, 'Sélectionner un patient'),
                    items: _patients.map((p) => DropdownMenuItem<int>(
                      value: int.tryParse(p['id'].toString()),
                      child: Text('${p['prenom']} ${p['nom']}',
                          overflow: TextOverflow.ellipsis),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Type d'examen ────────────────────────
                _label("Type d'examen *"),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: _types.entries.map((e) {
                  final sel = selectedType == e.key;
                  final color = e.value['color'] as Color;
                  return GestureDetector(
                    onTap: () => setMod(() => selectedType = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel
                            ? color.withOpacity(0.12)
                            : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel ? color : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(e.value['icon'] as IconData,
                            size: 14,
                            color: sel ? color : const Color(0xFF9E9E9E)),
                        const SizedBox(width: 6),
                        Text(
                          e.value['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: sel ? color : const Color(0xFF9E9E9E),
                          ),
                        ),
                      ]),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 16),

                // ── Résultat ─────────────────────────────
                _label('Résultat de l\'examen'),
                const SizedBox(height: 6),
                TextField(
                  controller: resultatCtrl,
                  maxLines: 3,
                  decoration: _inputDeco(
                    Icons.assignment_outlined,
                    'Ex: Hémoglobine 12g/dl, Foie d\'aspect normal...',
                  ),
                ),
                const SizedBox(height: 14),

                // ── Conclusion ───────────────────────────
                _label('Conclusion / Diagnostic'),
                const SizedBox(height: 6),
                TextField(
                  controller: conclusionCtrl,
                  maxLines: 2,
                  decoration: _inputDeco(
                    Icons.check_circle_outline,
                    'Ex: Aucune anomalie détectée...',
                  ),
                ),
                const SizedBox(height: 14),

                // ── Observation ──────────────────────────
                _label('Observation du médecin'),
                const SizedBox(height: 6),
                TextField(
                  controller: observCtrl,
                  maxLines: 2,
                  decoration: _inputDeco(
                    Icons.comment_outlined,
                    'Ex: Contrôle recommandé dans 6 mois...',
                  ),
                ),
                const SizedBox(height: 14),

                // ── Date ─────────────────────────────────
                _label('Date de l\'examen *'),
                const SizedBox(height: 6),
                TextField(
                  controller: dateCtrl,
                  decoration: _inputDeco(
                      Icons.calendar_today_outlined, 'AAAA-MM-JJ'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      dateCtrl.text =
                          picked.toIso8601String().substring(0, 10);
                    }
                  },
                  readOnly: true,
                ),
                const SizedBox(height: 16),

                // ── Statut ───────────────────────────────
                _label('Statut'),
                const SizedBox(height: 8),
                Row(children: [
                  _statutChip('Normal',    'normal',    selectedStatut,
                      () => setMod(() => selectedStatut = 'normal'),
                      const Color(0xFF43A047)),
                  const SizedBox(width: 8),
                  _statutChip('Attention', 'attention', selectedStatut,
                      () => setMod(() => selectedStatut = 'attention'),
                      const Color(0xFFFB8C00)),
                  const SizedBox(width: 8),
                  _statutChip('Urgent',    'urgent',    selectedStatut,
                      () => setMod(() => selectedStatut = 'urgent'),
                      const Color(0xFFE53935)),
                ]),
                const SizedBox(height: 24),

                // ── Bouton ───────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedPatientId == null) {
                        _snack('Sélectionnez un patient',
                            const Color(0xFFE53935));
                        return;
                      }
                      if (dateCtrl.text.trim().isEmpty) {
                        _snack('La date est requise',
                            const Color(0xFFE53935));
                        return;
                      }
                      Navigator.pop(context);

                      final headers = await _headers();
                      final response = await http.post(
                        Uri.parse(
                            '${AppConstants.baseUrl}/medecin/resultats'),
                        headers: headers,
                        body: jsonEncode({
                          'patient_id':    selectedPatientId,
                          'type_examen':   selectedType,
                          'resultat':      resultatCtrl.text.trim(),
                          'conclusion':    conclusionCtrl.text.trim(),
                          'observation':   observCtrl.text.trim(),
                          'date_resultat': dateCtrl.text.trim(),
                          'statut':        selectedStatut,
                        }),
                      );

                      final data = jsonDecode(response.body);
                      if (mounted) {
                        _snack(
                          data['message'] ?? '',
                          data['succes'] == true
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935),
                        );
                        if (data['succes'] == true) _charger();
                      }
                    },
                    icon: const Icon(Icons.save_outlined,
                        color: Colors.white),
                    label: const Text('Enregistrer le résultat',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            )),
          ),
        ),
      ),
    );

    resultatCtrl.dispose();
    conclusionCtrl.dispose();
    observCtrl.dispose();
    dateCtrl.dispose();
  }

  // ── Helpers ───────────────────────────────────────────
  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555)));

  InputDecoration _inputDeco(IconData icon, String hint) => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8F9FA),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5)),
    prefixIcon: Icon(icon, color: _accent, size: 20),
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Widget _statutChip(String label, String value, String selected,
      VoidCallback onTap, Color color) {
    final sel = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? color.withOpacity(0.12) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: sel ? color : Colors.transparent, width: 1.5),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w400,
                    color: sel ? color : const Color(0xFF9E9E9E))),
          ),
        ),
      ),
    );
  }

  // ── Formatage ─────────────────────────────────────────
  String _formaterDate(dynamic d) {
    if (d == null) return '';
    final s = d.toString();
    final date = s.contains('T') ? s.split('T')[0] : s;
    if (date.length >= 10) {
      final p = date.substring(0, 10).split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    }
    return date;
  }

  Color _statutColor(String? s) {
    switch (s) {
      case 'attention': return const Color(0xFFFB8C00);
      case 'urgent':    return const Color(0xFFE53935);
      default:          return const Color(0xFF43A047);
    }
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _accent,
        title: Text(
          widget.patientNom != null
              ? 'Résultats — ${widget.patientNom}'
              : 'Résultats médicaux',
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
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
        onPressed: _ajouterResultat,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter',
            style: TextStyle(color: Colors.white)),
      ),
      body: Column(children: [
        // Stats header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          decoration: const BoxDecoration(
            color: _accent,
            borderRadius: BorderRadius.only(
              bottomLeft:  Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem('Total',     '${_resultats.length}',                                                       Icons.science_outlined,       Colors.white),
              _statItem('Normaux',   '${_resultats.where((r) => r['statut'] == 'normal').length}',    Icons.check_circle_outline,   Colors.greenAccent),
              _statItem('Attention', '${_resultats.where((r) => r['statut'] == 'attention').length}', Icons.warning_amber_outlined,  Colors.orangeAccent),
              _statItem('Urgents',   '${_resultats.where((r) => r['statut'] == 'urgent').length}',    Icons.emergency_outlined,      Colors.redAccent),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _resultats.isEmpty
                  ? _buildVide()
                  : RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _resultats.length,
                        itemBuilder: (_, i) => _carteResultat(_resultats[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _carteResultat(Map<String, dynamic> r) {
    final typeKey = r['type_examen']?.toString() ?? 'autre';
    final typeInfo = _types[typeKey] ?? _types['autre']!;
    final statut   = r['statut']?.toString() ?? 'normal';
    final sColor   = _statutColor(statut);
    final tColor   = typeInfo['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: [
        // ── En-tête carte ──────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tColor.withOpacity(0.06),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                  color: tColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(typeInfo['icon'] as IconData,
                  color: tColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(typeInfo['label'] as String,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: tColor)),
                if (widget.patientId == null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${r['patient_prenom'] ?? ''} ${r['patient_nom'] ?? ''}'.trim(),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF757575)),
                  ),
                ],
              ],
            )),
            // Statut badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: sColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statut == 'normal'
                    ? 'Normal'
                    : statut == 'attention'
                        ? 'Attention'
                        : 'Urgent',
                style: TextStyle(
                    fontSize: 11,
                    color: sColor,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        ),

        // ── Corps carte ────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((r['resultat'] ?? '').toString().isNotEmpty)
                _sectionCarte('Résultat',
                    r['resultat'].toString(),
                    Icons.assignment_outlined),
              if ((r['conclusion'] ?? '').toString().isNotEmpty)
                _sectionCarte('Conclusion',
                    r['conclusion'].toString(),
                    Icons.check_circle_outline),
              if ((r['observation'] ?? '').toString().isNotEmpty)
                _sectionCarte('Observation',
                    r['observation'].toString(),
                    Icons.comment_outlined),

              const Divider(height: 16),
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 4),
                Text(_formaterDate(r['date_resultat']),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF9E9E9E))),
                if ((r['medecin'] ?? '').toString().isNotEmpty) ...[
                  const Spacer(),
                  const Icon(Icons.person_outline,
                      size: 13, color: Color(0xFF9E9E9E)),
                  const SizedBox(width: 4),
                  Text(r['medecin'].toString(),
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF9E9E9E))),
                ],
              ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _sectionCarte(String label, String content, IconData icon) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 14, color: _accent),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accent)),
          ]),
          const SizedBox(height: 4),
          Text(content,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF444444))),
        ]),
      );

  Widget _statItem(
      String label, String value, IconData icon, Color color) =>
      Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]);

  Widget _buildVide() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Aucun résultat',
                style: TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Appuyez sur + pour ajouter',
                style: TextStyle(
                    color: Color(0xFF9E9E9E), fontSize: 13)),
          ],
        ),
      );
}