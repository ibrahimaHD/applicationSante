import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  List<dynamic> _validations = [];
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

  // Construit l'URL complète d'un document à partir du chemin relatif
  // renvoyé par le backend (ex: /uploads/documents/xxx.pdf)
  String _urlDocumentComplete(String cheminRelatif) {
    // AppConstants.baseUrl contient '/api' à la fin, il faut le retirer
    // pour accéder aux fichiers statiques servis à la racine du serveur.
    final racineServeur = AppConstants.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (cheminRelatif.startsWith('http')) return cheminRelatif;
    return '$racineServeur$cheminRelatif';
  }

  Future<void> _ouvrirDocument(String? cheminRelatif) async {
    if (cheminRelatif == null || cheminRelatif.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Aucun document disponible.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final url = _urlDocumentComplete(cheminRelatif);
    final uri = Uri.parse(url);

    try {
      final ouvert = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ouvert && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Impossible d\'ouvrir le document.'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'ouverture : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  Future<void> _charger() async {
    setState(() => _isLoading = true);
    try {
      final headers = await _headers();
      debugPrint('🔑 Headers envoyés: $headers');

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/utilisateurs'),
        headers: headers,
      );
      debugPrint('👥 /admin/utilisateurs → status: ${response.statusCode} | body: ${response.body}');

      final validationsResponse = await http.get(
        Uri.parse('${AppConstants.baseUrl}/admin/validations-professionnels'),
        headers: headers,
      );
      debugPrint('📋 /admin/validations-professionnels → status: ${validationsResponse.statusCode} | body: ${validationsResponse.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _utilisateurs = data['utilisateurs'] ?? [];
          _appliquerFiltres();
        });
      }
      if (validationsResponse.statusCode == 200) {
        final data = jsonDecode(validationsResponse.body);
        setState(() => _validations = data['demandes'] ?? []);
      }
    } catch (e) {
      debugPrint('❌ Erreur _charger: $e');
    }
    setState(() => _isLoading = false);
  }

  void _appliquerFiltres() {
    var liste = List.from(_utilisateurs);

    if (_roleFiltreActif != null && _roleFiltreActif != 'tous') {
      liste = liste.where((u) => u['role'] == _roleFiltreActif).toList();
    }

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

  Future<void> _supprimerUtilisateur(int id, String nomComplet) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text(
          'Voulez-vous vraiment supprimer définitivement le compte de "$nomComplet" ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/admin/utilisateurs/$id'),
        headers: await _headers(),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? ''),
        backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
      ));
      if (data['succes'] == true) _charger();
    } catch (e) {
      debugPrint('Erreur suppression: $e');
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

  Future<void> _traiterValidation(int id, bool approuver) async {
    String? raisonRejet;

    if (!approuver) {
      final controller = TextEditingController();
      raisonRejet = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Motif du rejet'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex: Diplôme illisible, numéro de licence invalide...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) return;
                Navigator.pop(context, controller.text.trim());
              },
              child: const Text('Rejeter'),
            ),
          ],
        ),
      );

      if (raisonRejet == null || raisonRejet.isEmpty) return; // annulé
    }

    try {
      final response = await http.patch(
        Uri.parse(
          '${AppConstants.baseUrl}/admin/validations-professionnels/$id/${approuver ? 'approuver' : 'rejeter'}',
        ),
        headers: await _headers(),
        body: approuver ? null : jsonEncode({'raison': raisonRejet}),
      );
      final data = jsonDecode(response.body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(data['message'] ?? ''),
        backgroundColor: data['succes'] == true ? AppColors.success : AppColors.error,
      ));
      if (data['succes'] == true) _charger();
    } catch (e) {
      debugPrint('Erreur validation: $e');
    }
  }

  bool _historiqueOuvert = false;

  Widget _buildHistoriqueValidations() {
    final traitees = _validations.where((v) => v['statut'] != 'en_attente').toList();
    if (traitees.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      InkWell(
        onTap: () => setState(() => _historiqueOuvert = !_historiqueOuvert),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(children: [
            const Icon(Icons.history, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              'Historique (${traitees.length})',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
            ),
            const Spacer(),
            Icon(
              _historiqueOuvert ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ]),
        ),
      ),
      if (_historiqueOuvert)
        ...traitees.map((v) {
          final approuve = v['statut'] == 'approuvee';
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: (approuve ? AppColors.success : AppColors.error).withOpacity(0.25),
              ),
            ),
            child: Row(children: [
              Icon(
                approuve ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 18,
                color: approuve ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    '${v['prenom'] ?? ''} ${v['nom'] ?? ''} — ${UserRole.getLabel(v['role'] ?? '')}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  if (!approuve && (v['raison_rejet'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Motif : ${v['raison_rejet']}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                ]),
              ),
              Text(
                approuve ? 'Approuvé' : 'Rejeté',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: approuve ? AppColors.success : AppColors.error,
                ),
              ),
            ]),
          );
        }),
      const SizedBox(height: 6),
    ]);
  }

  Widget _buildValidationsProfessionnels() {
    final enAttente = _validations.where((v) => v['statut'] == 'en_attente').toList();
    if (enAttente.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          const Icon(Icons.verified_user_outlined, size: 18, color: Color(0xFF3949AB)),
          const SizedBox(width: 8),
          Text(
            '${enAttente.length} validation(s) professionnelle(s)',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ]),
      ),
      SizedBox(
        height: 260,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: enAttente.length,
          itemBuilder: (context, index) {
            final v = enAttente[index];
            final id = v['id'] is int ? v['id'] as int : int.parse(v['id'].toString());
            final diplomeUrl = v['diplome_url'] as String?;
            final identiteUrl = v['document_identite_url'] as String?;

            return Container(
              width: 300,
              margin: const EdgeInsets.only(right: 10, bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3949AB).withOpacity(0.18)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${v['prenom'] ?? ''} ${v['nom'] ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(UserRole.getLabel(v['role'] ?? ''), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text('Licence: ${v['numero_licence'] ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                Text('Lieu: ${v['lieu_travail'] ?? '-'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 8),

                // ── Boutons de consultation des documents ──
                _boutonDocument(
                  label: 'Voir le diplôme',
                  disponible: diplomeUrl != null && diplomeUrl.isNotEmpty,
                  onTap: () => _ouvrirDocument(diplomeUrl),
                ),
                const SizedBox(height: 6),
                _boutonDocument(
                  label: 'Voir la pièce d\'identité',
                  disponible: identiteUrl != null && identiteUrl.isNotEmpty,
                  onTap: () => _ouvrirDocument(identiteUrl),
                ),

                const Spacer(),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _traiterValidation(id, false),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _traiterValidation(id, true),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Valider'),
                    ),
                  ),
                ]),
              ]),
            );
          },
        ),
      ),
    ]);
  }

  Widget _boutonDocument({
    required String label,
    required bool disponible,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: disponible ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: disponible
              ? const Color(0xFF3949AB).withOpacity(0.08)
              : AppColors.divider.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(
            disponible ? Icons.description_outlined : Icons.block_outlined,
            size: 16,
            color: disponible ? const Color(0xFF3949AB) : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              disponible ? label : '$label (indisponible)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: disponible ? const Color(0xFF3949AB) : AppColors.textSecondary,
              ),
            ),
          ),
          if (disponible)
            const Icon(Icons.open_in_new, size: 14, color: Color(0xFF3949AB)),
        ]),
      ),
    );
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
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          color: const Color(0xFF3949AB),
          child: Column(children: [
            Text(
              '${_filtres.length} utilisateur(s)',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
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

        _buildValidationsProfessionnels(),
        _buildHistoriqueValidations(),

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
                                  } else if (action == 'supprimer') {
                                    _supprimerUtilisateur(id, '${u['prenom'] ?? ''} ${u['nom'] ?? ''}');
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
                                  if (widget.user.isSuperAdmin)
                                    const PopupMenuItem(
                                      value: 'supprimer',
                                      child: Row(children: [
                                        Icon(Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.error),
                                        SizedBox(width: 8),
                                        Text('Supprimer',
                                            style: TextStyle(color: AppColors.error)),
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