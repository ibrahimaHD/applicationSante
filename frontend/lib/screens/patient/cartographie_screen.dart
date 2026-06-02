import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class CartographieScreen extends StatefulWidget {
  final UserModel user;
  const CartographieScreen({super.key, required this.user});

  @override
  State<CartographieScreen> createState() => _CartographieScreenState();
}

class _CartographieScreenState extends State<CartographieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MapController _mapController = MapController();

  // Centre de Bobo-Dioulasso
  static const LatLng _bobo = LatLng(11.1771, -4.2979);

  List<dynamic> _formations = [];
  List<dynamic> _pharmacies = [];
  List<String> _specialites = [];
  bool _isLoading = true;
  bool _modeHorsLigne = false;
  String? _filtreType;
  String? _filtreSpecialite;
  bool _gardeUniquement = false;

  final List<String> _types = ['Tous', 'CSPS', 'CMA', 'CHR', 'CHU', 'clinique', 'cabinet'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _charger();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      String formationUrl = '${AppConstants.baseUrl}/cartographie/formations';
      if (_filtreType != null && _filtreType != 'Tous') {
        formationUrl += '?type=$_filtreType';
      }
      if (_filtreSpecialite != null) {
        formationUrl += formationUrl.contains('?') ? '&specialite=$_filtreSpecialite' : '?specialite=$_filtreSpecialite';
      }

      String pharmacieUrl = '${AppConstants.baseUrl}/cartographie/pharmacies';
      if (_gardeUniquement) pharmacieUrl += '?garde=true';

      final results = await Future.wait([
        http.get(Uri.parse(formationUrl), headers: headers),
        http.get(Uri.parse(pharmacieUrl), headers: headers),
        http.get(Uri.parse('${AppConstants.baseUrl}/cartographie/specialites'), headers: headers),
      ]);

      if (results[0].statusCode == 200) {
        setState(() => _formations = jsonDecode(results[0].body)['formations'] ?? []);
      }
      if (results[1].statusCode == 200) {
        setState(() => _pharmacies = jsonDecode(results[1].body)['pharmacies'] ?? []);
      }
      if (results[2].statusCode == 200) {
        setState(() => _specialites = List<String>.from(jsonDecode(results[2].body)['specialites'] ?? []));
      }

      setState(() => _modeHorsLigne = false);
    } catch (e) {
      setState(() => _modeHorsLigne = true);
    }
    setState(() => _isLoading = false);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'CHU': return const Color(0xFFC62828);
      case 'CHR': return const Color(0xFFE53935);
      case 'CMA': return const Color(0xFF1E88E5);
      case 'CSPS': return const Color(0xFF00897B);
      case 'clinique': return const Color(0xFF8E24AA);
      case 'cabinet': return const Color(0xFFF4511E);
      default: return AppColors.primary;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'CHU':
      case 'CHR': return Icons.local_hospital;
      case 'CMA': return Icons.medical_services;
      case 'CSPS': return Icons.health_and_safety;
      case 'clinique': return Icons.business;
      case 'cabinet': return Icons.person;
      default: return Icons.place;
    }
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    for (final f in _formations) {
      if (f['latitude'] == null || f['longitude'] == null) continue;
      final color = _typeColor(f['type'] ?? '');
      markers.add(Marker(
        point: LatLng(double.parse(f['latitude'].toString()), double.parse(f['longitude'].toString())),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _afficherDetails(f, estFormation: true),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(_typeIcon(f['type'] ?? ''), color: Colors.white, size: 20),
          ),
        ),
      ));
    }

    for (final p in _pharmacies) {
      if (p['latitude'] == null || p['longitude'] == null) continue;
      final color = p['est_garde'] == true ? const Color(0xFF00ACC1) : const Color(0xFF26A69A);
      markers.add(Marker(
        point: LatLng(double.parse(p['latitude'].toString()), double.parse(p['longitude'].toString())),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () => _afficherDetails(p, estFormation: false),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)],
            ),
            child: const Icon(Icons.medication, color: Colors.white, size: 20),
          ),
        ),
      ));
    }

    return markers;
  }

  void _afficherDetails(Map<String, dynamic> item, {required bool estFormation}) {
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

          // Header
          Row(children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: estFormation ? _typeColor(item['type'] ?? '') : const Color(0xFF00ACC1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                estFormation ? _typeIcon(item['type'] ?? '') : Icons.medication,
                color: Colors.white, size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['nom'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              if (estFormation)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _typeColor(item['type'] ?? '').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item['type'] ?? '', style: TextStyle(fontSize: 11, color: _typeColor(item['type'] ?? ''), fontWeight: FontWeight.w600)),
                )
              else if (item['est_garde'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF00ACC1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text('Pharmacie de garde', style: TextStyle(fontSize: 11, color: Color(0xFF00ACC1), fontWeight: FontWeight.w600)),
                ),
            ])),
          ]),

          const Divider(height: 24),

          // Infos
          if (item['adresse'] != null) _infoRow(Icons.location_on_outlined, item['adresse']),
          if (item['telephone'] != null) _infoRow(Icons.phone_outlined, item['telephone']),
          if (item['horaires'] != null) _infoRow(Icons.access_time_outlined, item['horaires']),
          if (estFormation && item['tarif_consultation'] != null)
            _infoRow(Icons.payments_outlined, '${item['tarif_consultation']} FCFA'),
          if (estFormation && item['urgences'] == true)
            _infoRow(Icons.emergency_outlined, 'Urgences disponibles 24h/24', color: AppColors.error),

          // Spécialités
          if (estFormation && item['specialites'] != null && (item['specialites'] as List).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft,
                child: Text('Spécialités', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: (item['specialites'] as List).map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E88E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s['specialite'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF1E88E5))),
              )).toList(),
            ),
          ],

          const SizedBox(height: 16),

          // Bouton itinéraire
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                if (item['latitude'] != null) {
                  _mapController.move(
                    LatLng(double.parse(item['latitude'].toString()), double.parse(item['longitude'].toString())),
                    16,
                  );
                  _tabController.animateTo(0);
                }
              },
              icon: const Icon(Icons.directions_outlined, size: 18),
              label: const Text('Voir sur la carte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color ?? AppColors.textSecondary))),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text('Formations sanitaires',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_modeHorsLigne ? Icons.wifi_off : Icons.refresh, color: Colors.white),
            onPressed: _charger,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.map_outlined, size: 18), text: 'Carte'),
            Tab(icon: Icon(Icons.local_hospital_outlined, size: 18), text: 'Formations'),
            Tab(icon: Icon(Icons.medication_outlined, size: 18), text: 'Pharmacies'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // Mode hors ligne banner
              if (_modeHorsLigne)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.orange,
                  child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.wifi_off, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Mode hors ligne — données locales', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ]),
                ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── Onglet Carte ──────────────────────────────────
                    Stack(children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: const MapOptions(
                          initialCenter: _bobo,
                          initialZoom: 13,
                          minZoom: 10,
                          maxZoom: 18,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.laafiba.health',
                          ),
                          MarkerLayer(markers: _buildMarkers()),
                        ],
                      ),
                      // Légende
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                          ),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Légende', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            _legendeItem(const Color(0xFFC62828), 'CHU/CHR'),
                            _legendeItem(const Color(0xFF1E88E5), 'CMA'),
                            _legendeItem(const Color(0xFF00897B), 'CSPS'),
                            _legendeItem(const Color(0xFF8E24AA), 'Clinique'),
                            _legendeItem(const Color(0xFF00ACC1), 'Pharmacie'),
                          ]),
                        ),
                      ),
                    ]),

                    // ── Onglet Formations ─────────────────────────────
                    Column(children: [
                      // Filtres
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.white,
                        child: Column(children: [
                          // Filtre type
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _types.map((t) => GestureDetector(
                                onTap: () => setState(() {
                                  _filtreType = t == 'Tous' ? null : t;
                                  _charger();
                                }),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (_filtreType == t || (t == 'Tous' && _filtreType == null))
                                        ? const Color(0xFF1E88E5)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(t, style: TextStyle(
                                    fontSize: 12,
                                    color: (_filtreType == t || (t == 'Tous' && _filtreType == null))
                                        ? Colors.white : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  )),
                                ),
                              )).toList(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Filtre spécialité
                          if (_specialites.isNotEmpty)
                            DropdownButtonFormField<String>(
                              value: _filtreSpecialite,
                              onChanged: (v) => setState(() {
                                _filtreSpecialite = v;
                                _charger();
                              }),
                              decoration: InputDecoration(
                                hintText: 'Filtrer par spécialité',
                                prefixIcon: const Icon(Icons.search, size: 18),
                                filled: true,
                                fillColor: AppColors.inputFill,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Toutes les spécialités')),
                                ..._specialites.map((s) => DropdownMenuItem(value: s, child: Text(s))),
                              ],
                            ),
                        ]),
                      ),
                      Expanded(child: _buildListeFormations()),
                    ]),

                    // ── Onglet Pharmacies ─────────────────────────────
                    Column(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.white,
                        child: Row(children: [
                          const Text('Pharmacies de garde uniquement', style: TextStyle(fontSize: 13)),
                          const Spacer(),
                          Switch(
                            value: _gardeUniquement,
                            onChanged: (v) => setState(() {
                              _gardeUniquement = v;
                              _charger();
                            }),
                            activeColor: const Color(0xFF00ACC1),
                          ),
                        ]),
                      ),
                      Expanded(child: _buildListePharmacies()),
                    ]),
                  ],
                ),
              ),
            ]),
    );
  }

  Widget _buildListeFormations() {
    if (_formations.isEmpty) {
      return const Center(child: Text('Aucune formation trouvée', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _formations.length,
      itemBuilder: (context, index) {
        final f = _formations[index];
        final color = _typeColor(f['type'] ?? '');
        return GestureDetector(
          onTap: () => _afficherDetails(f, estFormation: true),
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
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(_typeIcon(f['type'] ?? ''), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f['nom'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(f['quartier'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                if (f['urgences'] == true)
                  const Text('Urgences 24h/24', style: TextStyle(fontSize: 11, color: AppColors.error, fontWeight: FontWeight.w500)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(f['type'] ?? '', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildListePharmacies() {
    if (_pharmacies.isEmpty) {
      return const Center(child: Text('Aucune pharmacie trouvée', style: TextStyle(color: AppColors.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pharmacies.length,
      itemBuilder: (context, index) {
        final p = _pharmacies[index];
        final garde = p['est_garde'] == true;
        final color = garde ? const Color(0xFF00ACC1) : const Color(0xFF26A69A);
        return GestureDetector(
          onTap: () => _afficherDetails(p, estFormation: false),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: garde ? Border.all(color: color.withOpacity(0.3)) : null,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.medication_outlined, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p['nom'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(p['quartier'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                if (p['horaires'] != null)
                  Text(p['horaires'], style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              if (garde)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Garde', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
        );
      },
    );
  }

  Widget _legendeItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}
