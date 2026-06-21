import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/app_widgets.dart';
import '../providers/pharmacie_provider.dart';
import '../widgets/medicament_card.dart';
import '../widgets/commande_card.dart';
import '../widgets/panier_view.dart';
import '../widgets/commande_bottom_sheet.dart';

class PharmacieScreen extends StatefulWidget {
  const PharmacieScreen({super.key});

  @override
  State<PharmacieScreen> createState() => _PharmacieScreenState();
}

class _PharmacieScreenState extends State<PharmacieScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PharmacieProvider>().chargerDonnees();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Pharmacie en ligne',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Consumer<PharmacieProvider>(
            builder: (context, provider, _) => Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  onPressed: provider.panier.isEmpty
                      ? null
                      : () => _tabController.animateTo(2),
                ),
                if (provider.nombreArticlesPanier > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${provider.nombreArticlesPanier}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
      body: Consumer<PharmacieProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.medicaments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null && provider.medicaments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erreur: ${provider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.chargerDonnees(),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _CatalogueTab(searchController: _searchController),
              const _CommandesTab(),
              const _PanierTab(),
            ],
          );
        },
      ),
    );
  }
}

// ── Onglet Catalogue ────────────────────────────────────────────────
class _CatalogueTab extends StatefulWidget {
  final TextEditingController searchController;
  const _CatalogueTab({required this.searchController});

  @override
  State<_CatalogueTab> createState() => _CatalogueTabState();
}

class _CatalogueTabState extends State<_CatalogueTab> {
  // Debounce pour la recherche
  DateTime? _lastSearch;

  void _onSearchChanged(String value) {
    final now = DateTime.now();
    if (_lastSearch != null && now.difference(_lastSearch!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastSearch = now;
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && widget.searchController.text == value) {
        context.read<PharmacieProvider>().setRecherche(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacieProvider>(
      builder: (context, provider, _) => Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: widget.searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un médicament...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: AppColors.inputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Tous', ...provider.categories].map((c) {
                      final isSelected = (provider.filtreCategorie == null && c == 'Tous') ||
                          provider.filtreCategorie == c;
                      return GestureDetector(
                        onTap: () => provider.setFiltreCategorie(c == 'Tous' ? null : c),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            c,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.medicaments.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun médicament trouvé',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: provider.chargerDonnees,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: provider.medicaments.length,
                      itemBuilder: (context, index) {
                        final medicament = provider.medicaments[index];
                        return MedicamentCard(
                          medicament: medicament,
                          onAddToCart: () {
                            if (medicament.ordonnanceRequise) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Ce médicament nécessite une ordonnance'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }
                            provider.ajouterAuPanier(medicament);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${medicament.nom} ajouté au panier'),
                                backgroundColor: AppColors.success,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Onglet Commandes ────────────────────────────────────────────────
class _CommandesTab extends StatelessWidget {
  const _CommandesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacieProvider>(
      builder: (context, provider, _) {
        if (provider.commandes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Aucune commande',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.chargerDonnees,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.commandes.length,
            itemBuilder: (context, index) {
              final commande = provider.commandes[index];
              return CommandeCard(
                commande: commande,
                onVoirSuivi: () async {
                  final suivi = await provider.getSuiviCommande(commande.id);
                  if (context.mounted) {
                    _afficherSuivi(context, suivi);
                  }
                },
                onRenouveler: () async {
                  final confirmer = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Renouveler la commande ?'),
                      content: const Text(
                        'Cela créera une nouvelle commande identique avec les mêmes médicaments.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Renouveler', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );

                  if (confirmer != true) return;

                  final result = await provider.renouvelerCommande(commande.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? ''),
                        backgroundColor: result['succes'] == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    );
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  void _afficherSuivi(BuildContext context, List<dynamic> suivi) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Suivi de livraison', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            if (suivi.isEmpty)
              const Text(
                'Aucun suivi disponible',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              ...suivi.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final isLast = i == suivi.length - 1;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isLast ? AppColors.success : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isLast ? Icons.check : Icons.circle,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                        if (!isLast)
                          Container(width: 2, height: 40, color: AppColors.divider),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['statut'] ?? '',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          if (s['description'] != null)
                            Text(
                              s['description'],
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Onglet Panier ───────────────────────────────────────────────────
class _PanierTab extends StatelessWidget {
  const _PanierTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacieProvider>(
      builder: (context, provider, _) {
        if (provider.panier.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Votre panier est vide',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Voir le catalogue'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.panier.length,
                itemBuilder: (context, index) {
                  final article = provider.panier[index];
                  return PanierItem(
                    article: article,
                    onQuantityChanged: (newQty) {
                      provider.modifierQuantite(article.medicament.id, newQty);
                    },
                    onRemove: () {
                      provider.modifierQuantite(article.medicament.id, 0);
                    },
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${provider.totalPanier.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Commander — ${provider.totalPanier.toStringAsFixed(0)} FCFA',
                    icon: Icons.shopping_cart_checkout,
                    color: AppColors.primary,
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const CommandeBottomSheet(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}