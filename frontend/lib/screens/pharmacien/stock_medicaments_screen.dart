import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class StockMedicamentsScreen extends StatefulWidget {
  final UserModel user;
  const StockMedicamentsScreen({super.key, required this.user});
  @override
  State<StockMedicamentsScreen> createState() => _StockState();
}

class _StockState extends State<StockMedicamentsScreen> {
  List<dynamic> _meds = [];
  List<String>  _categories = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  String? _filtreCategorie;
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _charger(); }
  @override void dispose()   { _searchCtrl.dispose(); super.dispose(); }

  Future<Map<String,String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    return {'Content-Type':'application/json',
            'Authorization':'Bearer ${prefs.getString(AppConstants.tokenKey)}'};
  }

  Future<void> _charger({String search='', String? cat}) async {
    setState(() => _isLoading = true);
    try {
      String url = '${AppConstants.baseUrl}/pharmacien/stock';
      final params = <String>[];
      if (search.isNotEmpty) params.add('search=$search');
      if (cat != null)        params.add('categorie=$cat');
      if (params.isNotEmpty)  url += '?${params.join('&')}';

      final r = await http.get(Uri.parse(url), headers: await _headers());
      if (r.statusCode == 200) {
        final d = jsonDecode(r.body);
        setState(() {
          _meds       = d['medicaments']  ?? [];
          _categories = List<String>.from(d['categories'] ?? []);
          _stats      = d['stats']        ?? {};
        });
      }
    } catch (e) { debugPrint('$e'); }
    setState(() => _isLoading = false);
  }

  Future<void> _ajouterMedicament() async {
    final nomCtrl   = TextEditingController();
    final prixCtrl  = TextEditingController();
    final stockCtrl = TextEditingController();
    final catCtrl   = TextEditingController();
    final dosCtrl   = TextEditingController();
    bool ordonnance = false;

    await showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setM) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            _poignee(),
            const SizedBox(height: 12),
            const Text('Nouveau médicament', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            AppTextField(label:'Nom *',      hint:'Ex: Paracétamol 500mg', prefixIcon:Icons.medication_outlined,       controller:nomCtrl),
            const SizedBox(height:10),
            Row(children:[
              Expanded(child: AppTextField(label:'Prix (FCFA) *', hint:'Ex: 500', prefixIcon:Icons.payments_outlined, controller:prixCtrl, keyboardType:TextInputType.number)),
              const SizedBox(width:10),
              Expanded(child: AppTextField(label:'Stock initial',  hint:'Ex: 100', prefixIcon:Icons.inventory_2_outlined, controller:stockCtrl, keyboardType:TextInputType.number)),
            ]),
            const SizedBox(height:10),
            AppTextField(label:'Catégorie', hint:'Ex: Antibiotique', prefixIcon:Icons.category_outlined, controller:catCtrl),
            const SizedBox(height:10),
            AppTextField(label:'Dosage',    hint:'Ex: 500mg x 3/jour', prefixIcon:Icons.info_outline,    controller:dosCtrl),
            const SizedBox(height:10),
            Row(children:[
              const Text('Ordonnance requise', style: AppTextStyles.label),
              const Spacer(),
              Switch(value:ordonnance, onChanged:(v)=>setM(()=>ordonnance=v),
                     activeColor:const Color(0xFF8E24AA)),
            ]),
            const SizedBox(height:16),
            AppButton(
              text:'Ajouter', icon:Icons.add,
              color:const Color(0xFF8E24AA),
              onPressed:() async {
                if (nomCtrl.text.isEmpty || prixCtrl.text.isEmpty) return;
                Navigator.pop(context);
                final r = await http.post(
                  Uri.parse('${AppConstants.baseUrl}/pharmacien/stock'),
                  headers: await _headers(),
                  body: jsonEncode({
                    'nom': nomCtrl.text, 'prix': double.tryParse(prixCtrl.text)??0,
                    'stock': int.tryParse(stockCtrl.text)??0,
                    'categorie': catCtrl.text, 'dosage': dosCtrl.text,
                    'ordonnance_requise': ordonnance,
                  }),
                );
                final d = jsonDecode(r.body);
                if (mounted) {
                  _snack(d['message']??'', d['succes']==true ? AppColors.success : AppColors.error);
                  if (d['succes']==true) _charger();
                }
              },
            ),
            const SizedBox(height:8),
          ])),
        ),
      )),
    );
  }

  Future<void> _editStock(Map<String,dynamic> med) async {
    final stockCtrl = TextEditingController(text: '${med['stock']??0}');
    final prixCtrl  = TextEditingController(text: '${med['prix']??0}');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(med['nom']??''),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          AppTextField(label:'Stock', hint:'Quantité', prefixIcon:Icons.inventory_outlined, controller:stockCtrl, keyboardType:TextInputType.number),
          const SizedBox(height:10),
          AppTextField(label:'Prix (FCFA)', hint:'Prix', prefixIcon:Icons.payments_outlined, controller:prixCtrl, keyboardType:TextInputType.number),
        ]),
        actions:[
          TextButton(onPressed:()=>Navigator.pop(context), child:const Text('Annuler')),
          ElevatedButton(
            onPressed:() async {
              Navigator.pop(context);
              final r = await http.patch(
                Uri.parse('${AppConstants.baseUrl}/pharmacien/stock/${med['id']}'),
                headers: await _headers(),
                body: jsonEncode({'stock':int.tryParse(stockCtrl.text), 'prix':double.tryParse(prixCtrl.text)}),
              );
              final d = jsonDecode(r.body);
              if (mounted) {
                _snack(d['message']??'', d['succes']==true ? AppColors.success : AppColors.error);
                if (d['succes']==true) _charger(cat:_filtreCategorie);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor:const Color(0xFF8E24AA), foregroundColor:Colors.white),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content:Text(msg), backgroundColor:color,
             behavior:SnackBarBehavior.floating,
             shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10)),
             margin:const EdgeInsets.all(16)));

  Color _stockColor(int stock) {
    if (stock == 0) return AppColors.error;
    if (stock <= 10) return Colors.orange;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        title: const Text('Stock médicaments', style: TextStyle(color:Colors.white, fontSize:16, fontWeight:FontWeight.w600)),
        leading: IconButton(icon:const Icon(Icons.arrow_back_ios_new_rounded, color:Colors.white), onPressed:()=>Navigator.pop(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterMedicament,
        backgroundColor: const Color(0xFF8E24AA),
        icon: const Icon(Icons.add, color:Colors.white),
        label: const Text('Ajouter', style:TextStyle(color:Colors.white)),
      ),
      body: Column(children:[
        // Stats + recherche
        Container(
          padding: const EdgeInsets.fromLTRB(16,0,16,20),
          color: const Color(0xFF8E24AA),
          child: Column(children:[
            Row(mainAxisAlignment:MainAxisAlignment.spaceAround, children:[
              _statItem('Total',       '${_stats['total']??0}',       Icons.medication_outlined),
              _statItem('Disponibles', '${_stats['disponible']??0}',  Icons.check_circle_outline),
              _statItem('Faible',      '${_stats['faible']??0}',      Icons.warning_amber_outlined),
              _statItem('Rupture',     '${_stats['rupture']??0}',     Icons.cancel_outlined),
            ]),
            const SizedBox(height:12),
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => _charger(search:v, cat:_filtreCategorie),
              decoration: InputDecoration(
                hintText:'Rechercher un médicament…',
                prefixIcon:const Icon(Icons.search, size:20),
                filled:true, fillColor:Colors.white,
                border:OutlineInputBorder(borderRadius:BorderRadius.circular(12), borderSide:BorderSide.none),
                contentPadding:const EdgeInsets.symmetric(horizontal:16, vertical:10),
              ),
            ),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height:8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children:[
                  _chipCategorie('Tous', null),
                  ..._categories.map((c) => _chipCategorie(c, c)),
                ]),
              ),
            ],
          ]),
        ),
        Expanded(
          child: _isLoading
            ? const Center(child:CircularProgressIndicator())
            : _meds.isEmpty
              ? _vide('Aucun médicament', Icons.medication_liquid_outlined)
              : RefreshIndicator(
                  onRefresh: () => _charger(cat:_filtreCategorie),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16,12,16,100),
                    itemCount: _meds.length,
                    itemBuilder: (_,i) {
                      final m = _meds[i];
                      final stock = (m['stock'] as num?)?.toInt() ?? 0;
                      final sc    = _stockColor(stock);
                      return Container(
                        margin: const EdgeInsets.only(bottom:10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color:Colors.white,
                          borderRadius:BorderRadius.circular(14),
                          border:Border.all(color:sc.withOpacity(0.3)),
                          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.04), blurRadius:6)],
                        ),
                        child: Row(children:[
                          Container(
                            width:44, height:44,
                            decoration:BoxDecoration(color:const Color(0xFF8E24AA).withOpacity(0.1), borderRadius:BorderRadius.circular(12)),
                            child:const Icon(Icons.medication_outlined, color:Color(0xFF8E24AA), size:22),
                          ),
                          const SizedBox(width:12),
                          Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                            Text(m['nom']??'', style:const TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:AppColors.textPrimary)),
                            Text(m['categorie']??'', style:const TextStyle(fontSize:11, color:AppColors.textSecondary)),
                            Text('${m['prix']??0} FCFA', style:const TextStyle(fontSize:12, fontWeight:FontWeight.w600, color:Color(0xFF8E24AA))),
                          ])),
                          Column(crossAxisAlignment:CrossAxisAlignment.end, children:[
                            Container(
                              padding:const EdgeInsets.symmetric(horizontal:10, vertical:4),
                              decoration:BoxDecoration(color:sc.withOpacity(0.1), borderRadius:BorderRadius.circular(20)),
                              child:Text('$stock unités', style:TextStyle(fontSize:11, color:sc, fontWeight:FontWeight.w700)),
                            ),
                            const SizedBox(height:4),
                            GestureDetector(
                              onTap:() => _editStock(m),
                              child:const Text('Modifier', style:TextStyle(fontSize:11, color:Color(0xFF8E24AA), fontWeight:FontWeight.w600)),
                            ),
                          ]),
                        ]),
                      );
                    },
                  ),
                ),
        ),
      ]),
    );
  }

  Widget _chipCategorie(String label, String? val) => GestureDetector(
    onTap:() { setState(()=>_filtreCategorie=val); _charger(cat:val); },
    child:Container(
      margin:const EdgeInsets.only(right:8),
      padding:const EdgeInsets.symmetric(horizontal:12, vertical:6),
      decoration:BoxDecoration(
        color:(_filtreCategorie==val) ? Colors.white : Colors.white.withOpacity(0.2),
        borderRadius:BorderRadius.circular(20),
      ),
      child:Text(label, style:TextStyle(fontSize:12, fontWeight:FontWeight.w500,
          color:(_filtreCategorie==val) ? const Color(0xFF8E24AA) : Colors.white)),
    ),
  );

  Widget _statItem(String label, String val, IconData icon) => Column(children:[
    Icon(icon, color:Colors.white70, size:18),
    const SizedBox(height:2),
    Text(val, style:const TextStyle(color:Colors.white, fontSize:18, fontWeight:FontWeight.w700)),
    Text(label, style:const TextStyle(color:Colors.white70, fontSize:10)),
  ]);

  Widget _vide(String msg, IconData icon) => Center(child:Column(mainAxisAlignment:MainAxisAlignment.center, children:[
    Icon(icon, size:64, color:Colors.grey[300]),
    const SizedBox(height:16),
    Text(msg, style:const TextStyle(color:AppColors.textSecondary, fontSize:16)),
  ]));

  Widget _poignee() => Container(width:40, height:4,
    decoration:BoxDecoration(color:Colors.grey[300], borderRadius:BorderRadius.circular(2)));
}