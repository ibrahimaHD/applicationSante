import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../widgets/app_widgets.dart';

class PharmacieScreen extends StatefulWidget {
  final UserModel user;
  const PharmacieScreen({super.key, required this.user});

  @override
  State<PharmacieScreen> createState() => _PharmacieScreenState();
}

class _PharmacieScreenState extends State<PharmacieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _medicaments = [];
  List<dynamic> _commandes = [];
  List<dynamic> _pharmacies = [];
  List<String> _categories = [];
  List<Map<String, dynamic>> _panier = [];
  bool _isLoading = true;
  String? _filtreCategorie;
  int? _filtrePharmacieId;
  String _recherche = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'};
  }

  double _prix(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _headers();
      String url = '${AppConstants.baseUrl}/pharmacie/medicaments';
      if (_filtreCategorie != null) url += '?categorie=$_filtreCategorie';
      if (_recherche.isNotEmpty) url += url.contains('?') ? '&search=$_recherche' : '?search=$_recherche';
      if (_filtrePharmacieId != null) url += url.contains('?') ? '&pharmacie_id=$_filtrePharmacieId' : '?pharmacie_id=$_filtrePharmacieId';

      final results = await Future.wait([
        http.get(Uri.parse(url), headers: headers),
        http.get(Uri.parse('${AppConstants.baseUrl}/pharmacie/medicaments/categories'), headers: headers),
        http.get(Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes'), headers: headers),
        http.get(Uri.parse('${AppConstants.baseUrl}/pharmacie/pharmacies'), headers: headers),
      ]);

      if (results[0].statusCode == 200) setState(() => _medicaments = jsonDecode(results[0].body)['medicaments'] ?? []);
      if (results[1].statusCode == 200) setState(() => _categories = List<String>.from(jsonDecode(results[1].body)['categories'] ?? []));
      if (results[2].statusCode == 200) setState(() => _commandes = jsonDecode(results[2].body)['commandes'] ?? []);
      if (results[3].statusCode == 200) setState(() => _pharmacies = jsonDecode(results[3].body)['pharmacies'] ?? []);
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  void _ajouterAuPanier(Map<String, dynamic> medicament) {
    final pharmacieId = medicament['pharmacie_id'];
    if (_panier.isNotEmpty && _panier.first['pharmacie_id'] != pharmacieId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez commander dans une seule pharmacie à la fois.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final index = _panier.indexWhere((p) => p['medicament_id'] == medicament['id']);
    if (index >= 0) {
      setState(() => _panier[index]['quantite']++);
    } else {
      setState(() => _panier.add({
        'medicament_id': medicament['id'],
        'pharmacie_id': pharmacieId,
        'pharmacie_nom': medicament['pharmacie_nom'],
        'nom': medicament['nom'],
        'prix': _prix(medicament['prix']),
        'quantite': 1,
        'ordonnance_requise': medicament['ordonnance_requise'],
      }));
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${medicament['nom']} ajouté au panier'),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 1),
    ));
  }

  double get _totalPanier => _panier.fold(0, (sum, p) => sum + (_prix(p['prix']) * (p['quantite'] as int)));

  Widget _operatorChoice(String label, String value, String selected, ValueChanged<String> onChanged) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8E24AA).withOpacity(0.08) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF8E24AA) : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? const Color(0xFF8E24AA) : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _passerCommande() async {
    if (_panier.isEmpty) return;

    final adresseController = TextEditingController();
    String modePaiement = 'mobile_money';
    String operateurPaiement = 'orange_money';
    final numeroController = TextEditingController();

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
              Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Finaliser la commande', style: AppTextStyles.heading2),
              const SizedBox(height: 16),

              // Résumé panier
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  ..._panier.map((p) => Row(children: [
                    Expanded(child: Text('${p['nom']} x${p['quantite']}', style: const TextStyle(fontSize: 13))),
                    Text('${(_prix(p['prix']) * (p['quantite'] as int)).toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ])),
                  const Divider(),
                  Row(children: [
                    const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text('${_totalPanier.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                  ]),
                ]),
              ),

              const SizedBox(height: 12),
              AppTextField(label: 'Adresse de livraison *', hint: 'Secteur X, Quartier...', prefixIcon: Icons.location_on_outlined, controller: adresseController),
              const SizedBox(height: 12),

              // Mode paiement
              const Align(alignment: Alignment.centerLeft, child: Text('Mode de paiement', style: AppTextStyles.label)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => setStateModal(() => modePaiement = 'mobile_money'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: modePaiement == 'mobile_money' ? AppColors.primary : AppColors.divider, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(children: [
                      Icon(Icons.phone_android, color: modePaiement == 'mobile_money' ? AppColors.primary : AppColors.textSecondary),
                      const Text('Mobile Money', style: TextStyle(fontSize: 11)),
                    ]),
                  ),
                )),
                const SizedBox(width: 8),
                Expanded(child: GestureDetector(
                  onTap: () => setStateModal(() => modePaiement = 'especes'),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: modePaiement == 'especes' ? AppColors.primary : AppColors.divider, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(children: [
                      Icon(Icons.payments_outlined, color: modePaiement == 'especes' ? AppColors.primary : AppColors.textSecondary),
                      const Text('Espèces', style: TextStyle(fontSize: 11)),
                    ]),
                  ),
                )),
              ]),

              if (modePaiement == 'mobile_money') ...[
                const SizedBox(height: 12),
                const Align(alignment: Alignment.centerLeft, child: Text('Opérateur', style: AppTextStyles.label)),
                const SizedBox(height: 6),
                Row(children: [
                  Expanded(child: _operatorChoice('Orange', 'orange_money', operateurPaiement, (v) => setStateModal(() => operateurPaiement = v))),
                  const SizedBox(width: 6),
                  Expanded(child: _operatorChoice('Moov', 'moov_money', operateurPaiement, (v) => setStateModal(() => operateurPaiement = v))),
                  const SizedBox(width: 6),
                  Expanded(child: _operatorChoice('Coris', 'coris_money', operateurPaiement, (v) => setStateModal(() => operateurPaiement = v))),
                ]),
                const SizedBox(height: 12),
                AppTextField(label: 'Numéro Mobile Money', hint: '+226 XX XX XX XX', prefixIcon: Icons.phone_outlined, controller: numeroController, keyboardType: TextInputType.phone),
              ],

              const SizedBox(height: 20),
              AppButton(
                text: 'Confirmer la commande — ${_totalPanier.toStringAsFixed(0)} FCFA',
                icon: Icons.shopping_cart_checkout,
                onPressed: () async {
                  if (adresseController.text.isEmpty) return;
                  Navigator.pop(context);

                  final articles = _panier.map((p) => {
                    'medicament_id': p['medicament_id'],
                    'quantite': p['quantite'],
                  }).toList();

                  final response = await http.post(
                    Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes'),
                    headers: await _headers(),
                    body: jsonEncode({
                      'articles': articles,
                      'adresse_livraison': adresseController.text,
                      'mode_paiement': modePaiement,
                    }),
                  );

                  final data = jsonDecode(response.body);
                  if (mounted) {
                    if (data['succes'] == true) {
                      setState(() => _panier.clear());
                      _charger();
                      _tabController.animateTo(1);

                      // Paiement mobile si sélectionné
                      if (modePaiement == 'mobile_money' && numeroController.text.isNotEmpty) {
                        await http.post(
                          Uri.parse('${AppConstants.baseUrl}/pharmacie/paiement'),
                          headers: await _headers(),
                          body: jsonEncode({
                            'commande_id': data['commande_id'],
                            'numero_mobile': numeroController.text,
                            'operateur': operateurPaiement,
                          }),
                        );
                      }
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(data['message'] ?? ''),
                      backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
                    ));
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

  Future<void> _voirSuivi(int commandeId) async {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes/$commandeId/suivi'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    final suivi = data['suivi'] as List? ?? [];

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Suivi de livraison', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          if (suivi.isEmpty)
            const Text('Aucun suivi disponible', style: TextStyle(color: AppColors.textSecondary))
          else
            ...suivi.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isLast = i == suivi.length - 1;
              return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Column(children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: isLast ? AppColors.success : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(isLast ? Icons.check : Icons.circle, color: Colors.white, size: 14),
                  ),
                  if (!isLast) Container(width: 2, height: 40, color: AppColors.divider),
                ]),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s['statut'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  if (s['description'] != null)
                    Text(s['description'], style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                ])),
              ]);
            }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Color _statutColor(String statut) {
    switch (statut) {
      case 'en_attente': return Colors.orange;
      case 'confirmee': return const Color(0xFF1E88E5);
      case 'en_preparation': return const Color(0xFF8E24AA);
      case 'en_livraison': return const Color(0xFFF4511E);
      case 'livree': return AppColors.success;
      case 'annulee': return AppColors.error;
      default: return AppColors.textSecondary;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'confirmee': return 'Confirmée';
      case 'en_preparation': return 'En préparation';
      case 'en_livraison': return 'En livraison';
      case 'livree': return 'Livrée';
      case 'annulee': return 'Annulée';
      default: return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF8E24AA),
        title: const Text('Pharmacie en ligne',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
              onPressed: _panier.isEmpty ? null : _passerCommande,
            ),
            if (_panier.isNotEmpty)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 18, height: 18,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Center(child: Text('${_panier.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700))),
                ),
              ),
          ]),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Catalogue'),
            Tab(text: 'Commandes'),
            Tab(text: 'Panier'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // ── Catalogue ─────────────────────────────────────────
                Column(children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white,
                    child: Column(children: [
                      // Recherche
                      TextField(
                        controller: _searchController,
                        onChanged: (v) { _recherche = v; _charger(); },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un médicament...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filtres pharmacies partenaires
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            {'id': null, 'nom': 'Toutes les pharmacies'},
                            ..._pharmacies,
                          ].map((p) {
                            final id = p['id'];
                            final selected = id == null ? _filtrePharmacieId == null : _filtrePharmacieId == id;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _filtrePharmacieId = id as int?;
                                _charger();
                              }),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: selected ? AppColors.primary : Colors.white,
                                  border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.local_pharmacy_outlined, size: 14, color: selected ? Colors.white : AppColors.textSecondary),
                                  const SizedBox(width: 5),
                                  Text(
                                    p['nom']?.toString() ?? '',
                                    style: TextStyle(fontSize: 12, color: selected ? Colors.white : AppColors.textSecondary),
                                  ),
                                ]),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Filtres catégories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: ['Tous', ..._categories].map((c) => GestureDetector(
                            onTap: () => setState(() {
                              _filtreCategorie = c == 'Tous' ? null : c;
                              _charger();
                            }),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: (_filtreCategorie == c || (c == 'Tous' && _filtreCategorie == null))
                                    ? const Color(0xFF8E24AA) : Colors.grey[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(c, style: TextStyle(
                                fontSize: 12,
                                color: (_filtreCategorie == c || (c == 'Tous' && _filtreCategorie == null))
                                    ? Colors.white : AppColors.textSecondary,
                              )),
                            ),
                          )).toList(),
                        ),
                      ),
                    ]),
                  ),
                  Expanded(
                    child: _medicaments.isEmpty
                        ? const Center(child: Text('Aucun médicament trouvé', style: TextStyle(color: AppColors.textSecondary)))
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, childAspectRatio: 0.66, crossAxisSpacing: 12, mainAxisSpacing: 12,
                            ),
                            itemCount: _medicaments.length,
                            itemBuilder: (context, index) {
                              final m = _medicaments[index];
                              final ordonnance = m['ordonnance_requise'] == true || m['ordonnance_requise'] == 1;
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                                ),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Container(
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF8E24AA).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(child: Icon(Icons.medication_outlined, color: Color(0xFF8E24AA), size: 36)),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(m['nom'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(m['categorie'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.local_pharmacy_outlined, size: 12, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        m['pharmacie_nom'] ?? 'Pharmacie partenaire',
                                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ]),
                                  if ((m['pharmacie_quartier'] ?? '').toString().isNotEmpty)
                                    Text(
                                      m['pharmacie_quartier'].toString(),
                                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  if (ordonnance)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                      child: const Text('Ordonnance', style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w600)),
                                    ),
                                  const Spacer(),
                                  Row(children: [
                                    Text('${m['prix']} F', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => _ajouterAuPanier(m),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Color(0xFF8E24AA), shape: BoxShape.circle),
                                        child: const Icon(Icons.add, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ]),
                                ]),
                              );
                            },
                          ),
                  ),
                ]),

                // ── Commandes ─────────────────────────────────────────
                RefreshIndicator(
                  onRefresh: _charger,
                  child: _commandes.isEmpty
                      ? ListView(children: const [
                          SizedBox(height: 10),
                          Center(child: Column(children: [
                            Icon(Icons.shopping_bag_outlined, size: 4, color: Colors.grey),
                            SizedBox(height: 5),
                            Text('Aucune commande', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          ])),
                        ])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _commandes.length,
                          itemBuilder: (context, index) {
                            final c = _commandes[index];
                            final statut = c['statut'] ?? 'en_attente';
                            final color = _statutColor(statut);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: color.withOpacity(0.3)),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text('Commande #${c['id']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                    child: Text(_statutLabel(statut), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                                  ),
                                ]),
                                const SizedBox(height: 8),
                                Text('${c['montant_total']} FCFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                Text(c['created_at']?.toString().substring(0, 10) ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                // Articles
                                if (c['articles'] != null) ...[
                                  const Divider(height: 16),
                                  ...(c['articles'] as List).take(3).map((a) => Text(
                                    '• ${a['medicament_nom']} x${a['quantite']}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  )),
                                ],
                                const SizedBox(height: 12),
                                Row(children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _voirSuivi(c['id']),
                                      icon: const Icon(Icons.local_shipping_outlined, size: 16),
                                      label: const Text('Suivi', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: color,
                                        side: BorderSide(color: color),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () async {
                                        final response = await http.post(
                                          Uri.parse('${AppConstants.baseUrl}/pharmacie/commandes/${c['id']}/renouveler'),
                                          headers: await _headers(),
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
                                      icon: const Icon(Icons.refresh, size: 16),
                                      label: const Text('Renouveler', style: TextStyle(fontSize: 12)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF8E24AA),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ]),
                              ]),
                            );
                          },
                        ),
                ),

                // ── Panier ────────────────────────────────────────────
                _panier.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        const Text('Votre panier est vide', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('Ajoutez des médicaments depuis le catalogue', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => _tabController.animateTo(0),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E24AA), foregroundColor: Colors.white),
                          child: const Text('Voir le catalogue'),
                        ),
                      ]))
                    : Column(children: [
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _panier.length,
                            itemBuilder: (context, index) {
                              final p = _panier[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                                ),
                                child: Row(children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(color: const Color(0xFF8E24AA).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                    child: const Icon(Icons.medication_outlined, color: Color(0xFF8E24AA), size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p['nom'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    if ((p['pharmacie_nom'] ?? '').toString().isNotEmpty)
                                      Text(
                                        p['pharmacie_nom'],
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    Text('${p['prix']} FCFA / unité', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ])),
                                  Row(children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => setState(() {
                                        if (p['quantite'] > 1) p['quantite']--;
                                        else _panier.removeAt(index);
                                      }),
                                      color: AppColors.error,
                                    ),
                                    Text('${p['quantite']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20),
                                      onPressed: () => setState(() => p['quantite']++),
                                      color: AppColors.success,
                                    ),
                                  ]),
                                ]),
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.white,
                          child: Column(children: [
                            Row(children: [
                              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const Spacer(),
                              Text('${_totalPanier.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                            ]),
                            const SizedBox(height: 12),
                            AppButton(
                              text: 'Commander — ${_totalPanier.toStringAsFixed(0)} FCFA',
                              icon: Icons.shopping_cart_checkout,
                              color: const Color(0xFF8E24AA),
                              onPressed: _passerCommande,
                            ),
                          ]),
                        ),
                      ]),
              ],
            ),
    );
  }
}
