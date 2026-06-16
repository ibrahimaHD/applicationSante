import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class OrdonnancesPharmacienScreen extends StatefulWidget {
  final UserModel user;
  const OrdonnancesPharmacienScreen({super.key, required this.user});
  @override State<OrdonnancesPharmacienScreen> createState() => _OrdonnancesPharmState();
}

class _OrdonnancesPharmState extends State<OrdonnancesPharmacienScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _ordonnances = [];
  Map<String,dynamic> _stats = {};
  bool _isLoading = true;

  @override void initState() { super.initState(); _tabController = TabController(length: 3, vsync: this); _charger(); }
  @override void dispose()   { _tabController.dispose(); super.dispose(); }

  Future<Map<String,String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {'Content-Type':'application/json','Authorization':'Bearer ${prefs.getString(AppConstants.tokenKey)}'};
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final r = await http.get(Uri.parse('${AppConstants.baseUrl}/pharmacien/ordonnances'), headers: await _headers());
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        setState(() { _ordonnances = d['ordonnances']??[]; _stats = d['stats']??{}; });
      }
    } catch (e) { debugPrint('$e'); }
    setState(() => _isLoading = false);
  }

  Future<void> _traiter(Map<String,dynamic> ord, String statut) async {
    String? notes;
    if (statut == 'refusee') {
      final ctrl = TextEditingController();
      await showDialog(context: context, builder: (_) => AlertDialog(
        title: const Text('Motif du refus'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Ex: médicament non disponible')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(onPressed: () { notes = ctrl.text; Navigator.pop(context); }, child: const Text('Confirmer')),
        ],
      ));
      if (notes == null) return;
    }

    final r = await http.patch(
      Uri.parse('${AppConstants.baseUrl}/pharmacien/ordonnances/${ord['id']}'),
      headers: await _headers(),
      body: jsonEncode({'statut': statut, 'notes': notes}),
    );
    final d = jsonDecode(r.body);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(d['message']??''),
        backgroundColor: d['succes']==true ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ));
      if (d['succes']==true) _charger();
    }
  }

  List<dynamic> _filtrer(String statut) =>
    statut == 'tous' ? _ordonnances
    : _ordonnances.where((o) => (o['statut']??'nouvelle') == statut).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        title: const Text('Ordonnances reçues', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _charger)],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(text: 'Nouvelles (${_filtrer('nouvelle').length})'),
            const Tab(text: 'Traitées'),
            const Tab(text: 'Toutes'),
          ],
        ),
      ),
      body: Column(children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          color: const Color(0xFF8E24AA),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _statItem('Nouvelles',  '${_stats['nouvelles']??0}',  Icons.mark_email_unread_outlined),
            _statItem('Traitées',   '${_stats['traitees']??0}',   Icons.check_circle_outline),
            _statItem('Total',      '${_stats['total']??0}',      Icons.description_outlined),
          ]),
        ),
        Expanded(
          child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(controller: _tabController, children: [
                _buildListe(_filtrer('nouvelle'),  showActions: true),
                _buildListe(_filtrer('traitee')),
                _buildListe(_ordonnances),
              ]),
        ),
      ]),
    );
  }

  Widget _buildListe(List<dynamic> liste, {bool showActions = false}) {
    if (liste.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
      const SizedBox(height: 16),
      const Text('Aucune ordonnance', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
    ]));
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: liste.length,
        itemBuilder: (_, i) {
          final o = liste[i];
          final statut = o['statut']??'nouvelle';
          final color  = statut == 'traitee' ? AppColors.success
                       : statut == 'refusee' ? AppColors.error : Colors.orange;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.description_outlined, color: color, size: 22)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${o['patient_prenom']??''} ${o['patient_nom']??''}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text('Dr. ${o['medecin_nom']??''} • ${o['specialite']??'Médecin'}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(o['date_ordonnance']?.toString()??'', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(statut == 'traitee' ? 'Traitée' : statut == 'refusee' ? 'Refusée' : 'Nouvelle',
                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                ),
              ]),
              const Divider(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Médicaments prescrits', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(o['medicaments']??'—', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  if ((o['instructions']??'').toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(o['instructions'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                  ],
                ]),
              ),
              if ((o['notes_pharmacien']??'').toString().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Note: ${o['notes_pharmacien']}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
              if (showActions && statut == 'nouvelle') ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: () => _traiter(o, 'refusee'),
                    icon: const Icon(Icons.close, size: 14),
                    label: const Text('Refuser', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error)),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: ElevatedButton.icon(
                    onPressed: () => _traiter(o, 'traitee'),
                    icon: const Icon(Icons.check, size: 14),
                    label: const Text('Traiter', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA), foregroundColor: Colors.white),
                  )),
                ]),
              ],
            ]),
          );
        },
      ),
    );
  }

  Widget _statItem(String l, String v, IconData i) => Column(children: [
    Icon(i, color: Colors.white70, size: 18),
    const SizedBox(height: 2),
    Text(v, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
    Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)),
  ]);
}