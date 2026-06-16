import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/app_constants.dart';
import '../../models/user_model.dart';

class GestionUtilisateursScreen extends StatefulWidget {
  final UserModel user;
  final String? filtreRole;

  const GestionUtilisateursScreen({
    super.key,
    required this.user,
    this.filtreRole,
  });

  @override
  State<GestionUtilisateursScreen> createState() =>
      _GestionUtilisateursScreenState();
}

class _GestionUtilisateursScreenState
    extends State<GestionUtilisateursScreen> {
  List<dynamic> _utilisateurs = [];
  List<dynamic> _filtres = [];
  bool _isLoading = true;
  String? _roleFiltreActif;
  final _searchController = TextEditingController();

  final List<String> _roles = [
    'tous', 'patient', 'medecin', 'pharmacien', 'livreur', 'admin'
  ];

  @override
  void initState() {
    super.initState();
    _roleFiltreActif = widget.filtreRole;
    _charger();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/utilisateurs'),
        headers: await _headers(),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _utilisateurs = data['utilisateurs'] ?? [];
          _appliquerFiltres();
        });
      }
    } catch (e) {
      debugPrint('Erreur: $e');
    }
    setState(() => _isLoading = false);
  }

  void _appliquerFiltres() {
    var liste = List.from(_utilisateurs);

    // Filtre rôle
    if (_roleFiltreActif != null && _roleFiltreActif != 'tous') {
      liste = liste.where((u) => u['role'] == _roleFiltreActif).toList();
    }

    // Filtre recherche
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      liste = liste.where((u) =>
        '${u['prenom']} ${u['nom']}'.toLowerCase().contains(query) ||
        (u['email'] ?? '').toLowerCase().contains(query)
      ).toList();
    }

    setState(() => _filtres = liste);
  }

  Future<void> _toggleActivation(int id, bool actuel) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/admin/utilisateurs/$id/activation'),
        headers: await _headers(),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? ''),
          backgroundColor:
              data['succes'] == true ? AppColors.success : AppColors.error,
        ));
        if (data['succes'] == true) _charger();
      }
    } catch (e) {
      debugPrint('Erreur toggle: $e');
    }
  }

  Future<void> _changerRole(int id, String roleActuel) async {
    String? nouveauRole;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Changer le rôle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['patient', 'medecin', 'pharmacien', 'livreur', 'admin']
              .map((r) => RadioListTile<String>(
                    title: Text(UserRole.getLabel(r)),
                    value: r,
                    groupValue: nouveauRole ?? roleActuel,
                    onChanged: (v) => setState(() => nouveauRole = v),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, nouveauRole),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (nouveauRole == null || nouveauRole == roleActuel) return;

    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/admin/utilisateurs/$id/role'),
        headers: await _headers(),
        body: jsonEncode({'role': nouveauRole}),
      );
      final data = jsonDecode(response.body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(data['message'] ?? ''),
          backgroundColor:
              data['succes'] == true ? AppColors.success : AppColors.error,
        ));
        if (data['succes'] == true) _charger();
      }
    } catch (e) {
      debugPrint('Erreur role: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF3949AB),
        title: const Text('Gestion utilisateurs',
            style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600)),
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
      body: Column(children: [
        // Header stats + filtres
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          color: const Color(0xFF3949AB),
          child: Column(children: [
            // Compteur
            Text(
              '${_filtres.length} utilisateur(s)',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            // Barre de recherche
            TextField(
              controller: _searchController,
              onChanged: (_) => _appliquerFiltres(),
              decoration: InputDecoration(
                hintText: 'Rechercher...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(height: 10),
            // Filtres rôles
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _roles.map((r) {
                  final actif = _roleFiltreActif == r ||
                      (_roleFiltreActif == null && r == 'tous');
                  return GestureDetector(
                    onTap: () {
                      setState(() => _roleFiltreActif = r == 'tous' ? null : r);
                      _appliquerFiltres();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: actif
                            ? Colors.white
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        r == 'tous' ? 'Tous' : UserRole.getLabel(r),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: actif
                              ? const Color(0xFF3949AB)
                              : Colors.white,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),

        // Liste
        _isLoading
            ? const Expanded(
                child: Center(child: CircularProgressIndicator()))
            : _filtres.isEmpty
                ? Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('Aucun utilisateur trouvé',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  )
                : Expanded(
                    child: RefreshIndicator(
                      onRefresh: _charger,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtres.length,
                        itemBuilder: (context, index) {
                          final u = _filtres[index];
                          final role = u['role'] ?? 'patient';
                          final color = UserRole.getRoleColor(role);
                          final actif = u['est_actif'] == true ||
                              u['est_actif'] == 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: actif
                                  ? null
                                  : Border.all(
                                      color: AppColors.error.withOpacity(0.3)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 6)
                              ],
                            ),
                            child: Row(children: [
                              // Avatar
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(actif ? 0.12 : 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${(u['prenom'] ?? 'U')[0]}${(u['nom'] ?? 'N')[0]}',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: actif
                                            ? color
                                            : color.withOpacity(0.4)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Infos
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                        '${u['prenom'] ?? ''} ${u['nom'] ?? ''}',
                                        style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: actif
                                                ? AppColors.textPrimary
                                                : AppColors.textSecondary),
                                      ),
                                    ),
                                    if (!actif)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.error
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('Désactivé',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: AppColors.error,
                                                fontWeight: FontWeight.w600)),
                                      ),
                                  ]),
                                  Text(u['email'] ?? '',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      UserRole.getLabel(role),
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ]),
                              ),
                              // Actions
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert,
                                    color: AppColors.textSecondary),
                                onSelected: (action) {
                                  final id = u['id'] is int
                                      ? u['id'] as int
                                      : int.parse(u['id'].toString());
                                  if (action == 'toggle') {
                                    _toggleActivation(id, actif);
                                  } else if (action == 'role') {
                                    _changerRole(id, role);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'toggle',
                                    child: Row(children: [
                                      Icon(
                                        actif
                                            ? Icons.block_outlined
                                            : Icons.check_circle_outline,
                                        size: 18,
                                        color: actif
                                            ? AppColors.error
                                            : AppColors.success,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(actif ? 'Désactiver' : 'Activer'),
                                    ]),
                                  ),
                                  if (widget.user.isSuperAdmin)
                                    const PopupMenuItem(
                                      value: 'role',
                                      child: Row(children: [
                                        Icon(Icons.manage_accounts_outlined,
                                            size: 18,
                                            color: AppColors.primary),
                                        SizedBox(width: 8),
                                        Text('Changer le rôle'),
                                      ]),
                                    ),
                                ],
                              ),
                            ]),
                          );
                        },
                      ),
                    ),
                  ),
      ]),
    );
  }
}