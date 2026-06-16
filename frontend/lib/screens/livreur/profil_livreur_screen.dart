import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class ProfilLivreurScreen extends StatefulWidget {
  final UserModel user;
  const ProfilLivreurScreen({super.key, required this.user});
  @override State<ProfilLivreurScreen> createState() => _ProfilLivreurState();
}

class _ProfilLivreurState extends State<ProfilLivreurScreen> {
  Map<String,dynamic> _profil = {};
  Map<String,dynamic> _stats  = {};
  bool _isLoading = true;
  bool _editMode  = false;
  bool _saving    = false;

  final _nomCtrl   = TextEditingController();
  final _prenomCtrl= TextEditingController();
  final _telCtrl   = TextEditingController();
  final _zoneCtrl  = TextEditingController();
  final _vehicCtrl = TextEditingController();

  @override void initState() { super.initState(); _charger(); }
  @override void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose(); _telCtrl.dispose();
    _zoneCtrl.dispose(); _vehicCtrl.dispose(); super.dispose();
  }

  Future<Map<String,String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {'Content-Type':'application/json','Authorization':'Bearer ${prefs.getString(AppConstants.tokenKey)}'};
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(Uri.parse('${AppConstants.baseUrl}/livreur/profil'), headers: await _headers());
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        final p = d['profil']??{};
        setState(() { _profil = p; _stats = d['stats']??{}; });
        _nomCtrl.text    = p['nom']??'';
        _prenomCtrl.text = p['prenom']??'';
        _telCtrl.text    = p['telephone']??'';
        _zoneCtrl.text   = p['zone_livraison']??'';
        _vehicCtrl.text  = p['vehicule']??'';
      }
    } catch (e) { debugPrint('$e'); }
    setState(() => _isLoading = false);
  }

  Future<void> _sauvegarder() async {
    setState(() => _saving = true);
    try {
      final r = await http.put(
        Uri.parse('${AppConstants.baseUrl}/livreur/profil'),
        headers: await _headers(),
        body: jsonEncode({
          'nom': _nomCtrl.text, 'prenom': _prenomCtrl.text,
          'telephone': _telCtrl.text, 'zone_livraison': _zoneCtrl.text,
          'vehicule': _vehicCtrl.text,
        }),
      );
      final d = jsonDecode(r.body);
      if (mounted) {
        _snack(d['message']??'', d['succes']==true ? AppColors.success : AppColors.error);
        if (d['succes']==true) { setState(() => _editMode = false); _charger(); }
      }
    } catch (e) { _snack('Erreur réseau', AppColors.error); }
    setState(() => _saving = false);
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.all(16)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4511E),
        title: const Text('Mon profil', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
            icon: Icon(_editMode ? Icons.close : Icons.edit_outlined, color: Colors.white),
            onPressed: () => setState(() => _editMode = !_editMode),
          ),
        ],
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              // Avatar
              Center(child: Column(children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4511E).withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF4511E), width: 2),
                  ),
                  child: Center(child: Text(
                    '${(_profil['prenom']??'L')[0]}${(_profil['nom']??'V')[0]}'.toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFF4511E)),
                  )),
                ),
                const SizedBox(height: 12),
                Text('${_profil['prenom']??''} ${_profil['nom']??''}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Livreur', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ])),

              const SizedBox(height: 24),

              // Stats
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFF4511E), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _statItem("Aujourd'hui", '${_stats['aujourd_hui']??0}', Icons.today_outlined),
                  _divV(),
                  _statItem('En cours',    '${_stats['en_cours']??0}',    Icons.local_shipping_outlined),
                  _divV(),
                  _statItem('Total',       '${_stats['total_livraisons']??0}', Icons.check_circle_outline),
                ]),
              ),

              const SizedBox(height: 24),

              // Formulaire profil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.person_outline, color: Color(0xFFF4511E), size: 18),
                    const SizedBox(width: 8),
                    const Text('Informations personnelles', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ]),
                  const Divider(height: 20),
                  if (_editMode) ...[
                    Row(children: [
                      Expanded(child: AppTextField(label:'Prénom', hint:'', prefixIcon:Icons.person_outline, controller:_prenomCtrl)),
                      const SizedBox(width:10),
                      Expanded(child: AppTextField(label:'Nom', hint:'', prefixIcon:Icons.person_outline, controller:_nomCtrl)),
                    ]),
                    const SizedBox(height:12),
                    AppTextField(label:'Téléphone', hint:'', prefixIcon:Icons.phone_outlined, controller:_telCtrl, keyboardType:TextInputType.phone),
                    const SizedBox(height:12),
                    AppTextField(label:'Zone de livraison', hint:'Ex: Secteur 10 - Dafra', prefixIcon:Icons.map_outlined, controller:_zoneCtrl),
                    const SizedBox(height:12),
                    AppTextField(label:'Véhicule', hint:'Ex: Moto, Voiture...', prefixIcon:Icons.two_wheeler_outlined, controller:_vehicCtrl),
                    const SizedBox(height:20),
                    AppButton(
                      text:'Sauvegarder', icon:Icons.save_outlined, color:const Color(0xFFF4511E),
                      onPressed: _saving ? null : _sauvegarder, isLoading: _saving,
                    ),
                  ] else ...[
                    _infoRow('Prénom',           _profil['prenom']??'—'),
                    _infoRow('Nom',              _profil['nom']??'—'),
                    _infoRow('Email',            _profil['email']??'—'),
                    _infoRow('Téléphone',        _profil['telephone']??'—'),
                    _infoRow('Zone livraison',   _profil['zone_livraison']??'—'),
                    _infoRow('Véhicule',         _profil['vehicule']??'—'),
                    _infoRow('Disponibilité',    (_profil['disponible']==true||_profil['disponible']==1) ? '🟢 En ligne' : '🔴 Hors ligne'),
                  ],
                ]),
              ),
              const SizedBox(height: 32),
            ]),
          ),
    );
  }

  Widget _infoRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      SizedBox(width: 130, child: Text(l, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
      Expanded(child: Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
    ]),
  );

  Widget _statItem(String l, String v, IconData i) => Column(children: [
    Icon(i, color: Colors.white70, size: 18),
    const SizedBox(height: 2),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
  ]);

  Widget _divV() => Container(width: 1, height: 36, color: Colors.white.withOpacity(0.3));
}