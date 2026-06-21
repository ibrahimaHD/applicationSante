import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/medicament_model.dart';
import '../services/pharmacie_service.dart';

class PharmacieProvider extends ChangeNotifier {
  static const _panierKey = 'pharmacie_panier';

  List<Medicament> _medicaments = [];
  List<Commande> _commandes = [];
  List<String> _categories = [];
  List<ArticlePanier> _panier = [];
  String? _filtreCategorie;
  String _recherche = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Medicament> get medicaments => _medicaments;
  List<Commande> get commandes => _commandes;
  List<String> get categories => _categories;
  List<ArticlePanier> get panier => _panier;
  String? get filtreCategorie => _filtreCategorie;
  String get recherche => _recherche;
  bool get isLoading => _isLoading;
  String? get error => _error;

  double get totalPanier =>
      _panier.fold(0, (sum, article) => sum + article.total);

  int get nombreArticlesPanier => _panier.length;

  PharmacieProvider() {
    _chargerPanierPersiste();
  }

  // ── Chargement des données ──────────────────────────────
  Future<void> chargerDonnees() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        PharmacieService.getMedicaments(
          search: _recherche.isNotEmpty ? _recherche : null,
          categorie: _filtreCategorie,
        ),
        PharmacieService.getCategories(),
        PharmacieService.getCommandes(),
      ]);

      _medicaments = results[0] as List<Medicament>;
      _categories = results[1] as List<String>;
      _commandes = results[2] as List<Commande>;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Erreur chargement: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Filtres ─────────────────────────────────────────────
  void setFiltreCategorie(String? categorie) {
    _filtreCategorie = categorie;
    chargerDonnees();
  }

  void setRecherche(String recherche) {
    _recherche = recherche;
    chargerDonnees();
  }

  // ── Panier ──────────────────────────────────────────────
  void ajouterAuPanier(Medicament medicament) {
    final index = _panier.indexWhere((a) => a.medicament.id == medicament.id);
    if (index >= 0) {
      _panier[index].quantite++;
    } else {
      _panier.add(ArticlePanier(medicament: medicament));
    }
    _sauvegarderPanier();
    notifyListeners();
  }

  void modifierQuantite(int medicamentId, int nouvelleQuantite) {
    final index = _panier.indexWhere((a) => a.medicament.id == medicamentId);
    if (index >= 0) {
      if (nouvelleQuantite <= 0) {
        _panier.removeAt(index);
      } else {
        _panier[index].quantite = nouvelleQuantite;
      }
      _sauvegarderPanier();
      notifyListeners();
    }
  }

  void viderPanier() {
    _panier.clear();
    _sauvegarderPanier();
    notifyListeners();
  }

  Future<void> _sauvegarderPanier() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _panier.map((a) => {
      'medicament': {
        'id': a.medicament.id,
        'nom': a.medicament.nom,
        'prix': a.medicament.prix,
        'stock': a.medicament.stock,
        'ordonnance_requise': a.medicament.ordonnanceRequise,
        'categorie': a.medicament.categorie,
      },
      'quantite': a.quantite,
    }).toList();
    await prefs.setString(_panierKey, jsonEncode(data));
  }

  Future<void> _chargerPanierPersiste() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_panierKey);
      if (data != null) {
        final list = jsonDecode(data) as List;
        _panier = list.map((item) {
          final med = Medicament.fromJson(item['medicament']);
          return ArticlePanier(
            medicament: med,
            quantite: item['quantite'] ?? 1,
          );
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur chargement panier: $e');
    }
  }

  // ── Commandes ───────────────────────────────────────────
  Future<Map<String, dynamic>> passerCommande({
    required String adresse,
    required String modePaiement,
    String? numeroMobile,
  }) async {
    try {
      final result = await PharmacieService.creerCommande(
        articles: _panier,
        adresseLivraison: adresse,
        modePaiement: modePaiement,
      );

      if (result['succes'] == true) {
        // Paiement mobile money si nécessaire
        if (modePaiement == 'mobile_money' && numeroMobile != null) {
          await PharmacieService.effectuerPaiement(
            commandeId: result['commande_id'],
            numeroMobile: numeroMobile,
          );
        }

        viderPanier();
        await chargerDonnees();
      }

      return result;
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }

  Future<Map<String, dynamic>> renouvelerCommande(int commandeId) async {
    try {
      final result = await PharmacieService.renouvelerCommande(commandeId);
      if (result['succes'] == true) {
        await chargerDonnees();
      }
      return result;
    } catch (e) {
      return {'succes': false, 'message': 'Erreur: $e'};
    }
  }

  Future<List<dynamic>> getSuiviCommande(int commandeId) async {
    return await PharmacieService.getSuiviCommande(commandeId);
  }
}