import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

// ══════════════════════════════════════════════════════════════
// ÉCRAN PRINCIPAL : Liste des examens du patient + ajout examen
// ══════════════════════════════════════════════════════════════
class ExamensMedecinScreen extends StatefulWidget {
  final UserModel user;
  final int? patientId;
  final String? patientNom;

  const ExamensMedecinScreen({
    super.key,
    required this.user,
    this.patientId,
    this.patientNom,
  });

  @override
  State<ExamensMedecinScreen> createState() => _ExamensMedecinScreenState();
}

class _ExamensMedecinScreenState extends State<ExamensMedecinScreen> {
  List<dynamic> _examens  = [];
  List<dynamic> _patients = [];
  bool _isLoading = true;

  static const Color _accent = Color(0xFF3949AB);

  static const Map<String, Map<String, dynamic>> _types = {
    'analyse_sang':  {'label': 'Analyse de sang',  'icon': Icons.bloodtype_outlined,        'color': Color(0xFFE53935)},
    'analyse_urine': {'label': "Analyse d'urine",  'icon': Icons.water_drop_outlined,       'color': Color(0xFFFB8C00)},
    'irm':           {'label': 'IRM',               'icon': Icons.psychology_outlined,       'color': Color(0xFF8E24AA)},
    'echographie':   {'label': 'Échographie',       'icon': Icons.monitor_heart_outlined,    'color': Color(0xFF00ACC1)},
    'radiographie':  {'label': 'Radiographie',      'icon': Icons.image_outlined,            'color': Color(0xFF3949AB)},
    'scanner':       {'label': 'Scanner',           'icon': Icons.document_scanner_outlined, 'color': Color(0xFF1E88E5)},
    'ecg':           {'label': 'ECG',               'icon': Icons.favorite_outline,          'color': Color(0xFFE53935)},
    'autre':         {'label': 'Autre',             'icon': Icons.science_outlined,          'color': Color(0xFF43A047)},
  };

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
      String url = '${AppConstants.baseUrl}/medecin/examens';
      if (widget.patientId != null) url += '?patient_id=${widget.patientId}';
      final r = await http.get(Uri.parse(url), headers: headers);
      if (r.statusCode == 200) {
        setState(() => _examens = jsonDecode(r.body)['examens'] ?? []);
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

  // ── Formulaire : créer un examen ─────────────────────
  Future<void> _creerExamen() async {
    int?   selectedPatientId = widget.patientId;
    String selectedType      = 'analyse_sang';
    final nomCtrl  = TextEditingController();
    final dateCtrl = TextEditingController(
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
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                )),
                const SizedBox(height: 16),
                const Text('Créer un examen',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 20),

                // Patient
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
                  const SizedBox(height: 14),
                ],

                // Nom de l'examen
                _label('Nom de l\'examen *'),
                const SizedBox(height: 6),
                TextField(
                  controller: nomCtrl,
                  decoration: _inputDeco(
                    Icons.assignment_outlined,
                    'Ex: Échographie abdominale, NFS...',
                  ),
                ),
                const SizedBox(height: 14),

                // Type
                _label('Type d\'examen *'),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8,
                  children: _types.entries.map((e) {
                    final sel   = selectedType == e.key;
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
                          Text(e.value['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                color: sel ? color : const Color(0xFF9E9E9E),
                              )),
                        ]),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Date
                _label('Date de l\'examen *'),
                const SizedBox(height: 6),
                TextField(
                  controller: dateCtrl,
                  readOnly: true,
                  decoration: _inputDeco(Icons.calendar_today_outlined, 'AAAA-MM-JJ'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      dateCtrl.text = picked.toIso8601String().substring(0, 10);
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (selectedPatientId == null) {
                        _snack('Sélectionnez un patient', const Color(0xFFE53935));
                        return;
                      }
                      if (nomCtrl.text.trim().isEmpty) {
                        _snack('Le nom est requis', const Color(0xFFE53935));
                        return;
                      }
                      Navigator.pop(context);

                      final headers = await _headers();
                      final response = await http.post(
                        Uri.parse('${AppConstants.baseUrl}/medecin/examens'),
                        headers: headers,
                        body: jsonEncode({
                          'patient_id':  selectedPatientId,
                          'nom_examen':  nomCtrl.text.trim(),
                          'type_examen': selectedType,
                          'date_examen': dateCtrl.text.trim(),
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
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Créer l\'examen',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
    nomCtrl.dispose();
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
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555)));

  InputDecoration _inputDeco(IconData icon, String hint) => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8F9FA),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.5)),
    prefixIcon: Icon(icon, color: _accent, size: 20),
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  String _formaterDate(dynamic d) {
    if (d == null) return '';
    final s    = d.toString();
    final date = s.contains('T') ? s.split('T')[0] : s;
    if (date.length >= 10) {
      final p = date.substring(0, 10).split('-');
      if (p.length == 3) return '${p[2]}/${p[1]}/${p[0]}';
    }
    return date;
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
              ? 'Examens — ${widget.patientNom}'
              : 'Examens médicaux',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
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
        onPressed: _creerExamen,
        backgroundColor: _accent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouvel examen',
            style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _examens.isEmpty
              ? _buildVide()
              : RefreshIndicator(
                  onRefresh: _charger,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _examens.length,
                    itemBuilder: (_, i) => _carteExamen(_examens[i]),
                  ),
                ),
    );
  }

  Widget _carteExamen(Map<String, dynamic> e) {
    final typeKey  = e['type_examen']?.toString() ?? 'autre';
    final typeInfo = _types[typeKey] ?? _types['autre']!;
    final tColor   = typeInfo['color'] as Color;
    final nbRes    = int.tryParse(e['nb_resultats']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AjouterResultatScreen(
            user: widget.user,
            examen: e,
          ),
        ),
      ).then((_) => _charger()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: tColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(typeInfo['icon'] as IconData, color: tColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e['nom_examen'] ?? '',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 3),
              Text(typeInfo['label'] as String,
                  style: TextStyle(fontSize: 12, color: tColor,
                      fontWeight: FontWeight.w500)),
              if (widget.patientId == null) ...[
                const SizedBox(height: 2),
                Text(
                  '${e['patient_prenom'] ?? ''} ${e['patient_nom'] ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: Color(0xFF9E9E9E)),
                const SizedBox(width: 4),
                Text(_formaterDate(e['date_examen']),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF9E9E9E))),
              ]),
            ],
          )),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: nbRes > 0
                    ? const Color(0xFF43A047).withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                nbRes > 0 ? '$nbRes résultat${nbRes > 1 ? 's' : ''}' : 'En attente',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: nbRes > 0
                        ? const Color(0xFF43A047)
                        : Colors.orange),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: Color(0xFFBBBBBB)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildVide() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.science_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      const Text('Aucun examen',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
      const SizedBox(height: 8),
      const Text('Appuyez sur + pour créer un examen',
          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
    ]),
  );
}

// ══════════════════════════════════════════════════════════════
// ÉCRAN : Ajouter le résultat d'un examen
// ══════════════════════════════════════════════════════════════
class AjouterResultatScreen extends StatefulWidget {
  final UserModel user;
  final Map<String, dynamic> examen;

  const AjouterResultatScreen({
    super.key,
    required this.user,
    required this.examen,
  });

  @override
  State<AjouterResultatScreen> createState() => _AjouterResultatScreenState();
}

class _AjouterResultatScreenState extends State<AjouterResultatScreen> {
  List<dynamic> _resultats = [];
  bool _isLoading = true;
  String _selectedStatut = 'normal';

  final _resultatCtrl   = TextEditingController();
  final _conclusionCtrl = TextEditingController();
  final _observCtrl     = TextEditingController();
  final _dateCtrl       = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0,10));

  static const Color _accent = Color(0xFF3949AB);

  static const Map<String, Map<String, dynamic>> _types = {
    'analyse_sang':  {'label': 'Analyse de sang',  'color': Color(0xFFE53935)},
    'analyse_urine': {'label': "Analyse d'urine",  'color': Color(0xFFFB8C00)},
    'irm':           {'label': 'IRM',               'color': Color(0xFF8E24AA)},
    'echographie':   {'label': 'Échographie',       'color': Color(0xFF00ACC1)},
    'radiographie':  {'label': 'Radiographie',      'color': Color(0xFF3949AB)},
    'scanner':       {'label': 'Scanner',           'color': Color(0xFF1E88E5)},
    'ecg':           {'label': 'ECG',               'color': Color(0xFFE53935)},
    'autre':         {'label': 'Autre',             'color': Color(0xFF43A047)},
  };

  @override
  void initState() {
    super.initState();
    _chargerResultats();
  }

  @override
  void dispose() {
    _resultatCtrl.dispose();
    _conclusionCtrl.dispose();
    _observCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<void> _chargerResultats() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _headers();
      final r = await http.get(
        Uri.parse(
            '${AppConstants.baseUrl}/medecin/resultats?patient_id=${widget.examen['patient_id']}'),
        headers: headers,
      );
      if (r.statusCode == 200) {
        final all = (jsonDecode(r.body)['resultats'] ?? []) as List;
        setState(() => _resultats = all
            .where((x) =>
                x['examen_id']?.toString() ==
                widget.examen['id']?.toString())
            .toList());
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _soumettre() async {
    if (_dateCtrl.text.trim().isEmpty) {
      _snack('La date est requise', const Color(0xFFE53935));
      return;
    }

    final headers  = await _headers();
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}/medecin/resultats'),
      headers: headers,
      body: jsonEncode({
        'examen_id':   widget.examen['id'],
        'resultat':    _resultatCtrl.text.trim(),
        'conclusion':  _conclusionCtrl.text.trim(),
        'observation': _observCtrl.text.trim(),
        'statut':      _selectedStatut,
        'date_resultat': _dateCtrl.text.trim(),
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
      if (data['succes'] == true) {
        _resultatCtrl.clear();
        _conclusionCtrl.clear();
        _observCtrl.clear();
        setState(() => _selectedStatut = 'normal');
        _chargerResultats();
      }
    }
  }

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
          fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF555555)));

  InputDecoration _inputDeco(IconData icon, String hint, {int? maxLines}) =>
      InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent, width: 1.5)),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  String _formaterDate(dynamic d) {
    if (d == null) return '';
    final s    = d.toString();
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

  @override
  Widget build(BuildContext context) {
    final typeKey  = widget.examen['type_examen']?.toString() ?? 'autre';
    final typeInfo = _types[typeKey] ?? _types['autre']!;
    final tColor   = typeInfo['color'] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: _accent,
        title: Text(
          widget.examen['nom_examen'] ?? 'Résultat',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Info examen ──────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: tColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tColor.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: tColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.science_outlined, color: tColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.examen['nom_examen'] ?? '',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E))),
                  Text(typeInfo['label'] as String,
                      style: TextStyle(fontSize: 12, color: tColor,
                          fontWeight: FontWeight.w500)),
                  Text(
                    'Patient : ${widget.examen['patient_prenom'] ?? ''} ${widget.examen['patient_nom'] ?? ''}'.trim(),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF757575)),
                  ),
                  Text('Date : ${_formaterDate(widget.examen['date_examen'])}',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF9E9E9E))),
                ],
              )),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Résultats existants ──────────────────────────
          if (_resultats.isNotEmpty) ...[
            const Text('Résultats existants',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 10),
            ..._resultats.map((r) {
              final statut = r['statut']?.toString() ?? 'normal';
              final sColor = _statutColor(statut);
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: sColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statut == 'normal' ? 'Normal'
                              : statut == 'attention' ? 'Attention' : 'Urgent',
                          style: TextStyle(
                              fontSize: 11, color: sColor,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Spacer(),
                      Text(_formaterDate(r['date_resultat']),
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFF9E9E9E))),
                    ]),
                    if ((r['resultat'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _ligneResultat('Résultat', r['resultat']),
                    ],
                    if ((r['conclusion'] ?? '').toString().isNotEmpty)
                      _ligneResultat('Conclusion', r['conclusion']),
                    if ((r['observation'] ?? '').toString().isNotEmpty)
                      _ligneResultat('Observation', r['observation']),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
          ],

          // ── Formulaire ajout résultat ────────────────────
          const Text('Ajouter un résultat',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),

          _label('Résultat de l\'examen'),
          const SizedBox(height: 6),
          TextField(
            controller: _resultatCtrl,
            maxLines: 3,
            decoration: _inputDeco(
              Icons.assignment_outlined,
              'Ex: Foie normal, pas d\'anomalie détectée...',
            ),
          ),
          const SizedBox(height: 14),

          _label('Conclusion / Diagnostic'),
          const SizedBox(height: 6),
          TextField(
            controller: _conclusionCtrl,
            maxLines: 2,
            decoration: _inputDeco(
              Icons.check_circle_outline,
              'Ex: Aucune anomalie détectée...',
            ),
          ),
          const SizedBox(height: 14),

          _label('Observation du médecin'),
          const SizedBox(height: 6),
          TextField(
            controller: _observCtrl,
            maxLines: 2,
            decoration: _inputDeco(
              Icons.comment_outlined,
              'Ex: Contrôle recommandé dans 6 mois...',
            ),
          ),
          const SizedBox(height: 14),

          _label('Date du résultat *'),
          const SizedBox(height: 6),
          TextField(
            controller: _dateCtrl,
            readOnly: true,
            decoration: _inputDeco(Icons.calendar_today_outlined, 'AAAA-MM-JJ'),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                _dateCtrl.text = picked.toIso8601String().substring(0, 10);
              }
            },
          ),
          const SizedBox(height: 16),

          _label('Statut'),
          const SizedBox(height: 8),
          StatefulBuilder(builder: (_, setS) => Row(children: [
            _statutChip('Normal',    'normal',    _selectedStatut,
                () => setS(() => _selectedStatut = 'normal'),
                const Color(0xFF43A047)),
            const SizedBox(width: 8),
            _statutChip('Attention', 'attention', _selectedStatut,
                () => setS(() => _selectedStatut = 'attention'),
                const Color(0xFFFB8C00)),
            const SizedBox(width: 8),
            _statutChip('Urgent',    'urgent',    _selectedStatut,
                () => setS(() => _selectedStatut = 'urgent'),
                const Color(0xFFE53935)),
          ])),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _soumettre,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text('Enregistrer le résultat',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _ligneResultat(String label, dynamic val) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: _accent)),
      Text(val.toString(),
          style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
    ]),
  );

  Widget _statutChip(String label, String value, String selected,
      VoidCallback onTap, Color color) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected == value
                  ? color.withOpacity(0.12)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: selected == value ? color : Colors.transparent,
                  width: 1.5),
            ),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected == value
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: selected == value ? color : const Color(0xFF9E9E9E))),
            ),
          ),
        ),
      );
}