import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../widgets/app_widgets.dart';
import '../providers/pharmacie_provider.dart';

class CommandeBottomSheet extends StatefulWidget {
  const CommandeBottomSheet({super.key});

  @override
  State<CommandeBottomSheet> createState() => _CommandeBottomSheetState();
}

class _CommandeBottomSheetState extends State<CommandeBottomSheet> {
  final _adresseController = TextEditingController();
  final _numeroController = TextEditingController();
  String _modePaiement = 'mobile_money';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _adresseController.dispose();
    _numeroController.dispose();
    super.dispose();
  }

  Future<void> _confirmerCommande() async {
    if (_adresseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir une adresse de livraison'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_modePaiement == 'mobile_money' && _numeroController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir votre numéro Mobile Money'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final provider = context.read<PharmacieProvider>();
    final result = await provider.passerCommande(
      adresse: _adresseController.text.trim(),
      modePaiement: _modePaiement,
      numeroMobile: _modePaiement == 'mobile_money' ? _numeroController.text.trim() : null,
    );

    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? ''),
        backgroundColor: result['succes'] == true ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PharmacieProvider>(
      builder: (context, provider, _) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
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
              const Text('Finaliser la commande', style: AppTextStyles.heading2),
              const SizedBox(height: 16),

              // Résumé panier
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ...provider.panier.map((p) => Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${p.medicament.nom} x${p.quantite}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '${p.total.toStringAsFixed(0)} FCFA',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Total',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text(
                          '${provider.totalPanier.toStringAsFixed(0)} FCFA',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              AppTextField(
                label: 'Adresse de livraison *',
                hint: 'Secteur X, Quartier...',
                prefixIcon: Icons.location_on_outlined,
                controller: _adresseController,
              ),
              const SizedBox(height: 12),

              // Mode paiement
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Mode de paiement', style: AppTextStyles.label),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _ModePaiementButton(
                      icon: Icons.phone_android,
                      label: 'Mobile Money',
                      isSelected: _modePaiement == 'mobile_money',
                      onTap: () => setState(() => _modePaiement = 'mobile_money'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModePaiementButton(
                      icon: Icons.payments_outlined,
                      label: 'Espèces',
                      isSelected: _modePaiement == 'especes',
                      onTap: () => setState(() => _modePaiement = 'especes'),
                    ),
                  ),
                ],
              ),

              if (_modePaiement == 'mobile_money') ...[
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Numéro Mobile Money',
                  hint: '+226 XX XX XX XX',
                  prefixIcon: Icons.phone_outlined,
                  controller: _numeroController,
                  keyboardType: TextInputType.phone,
                ),
              ],

              const SizedBox(height: 20),
              _isSubmitting
                  ? const SizedBox(
                      height: 50,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : AppButton(
                      text: 'Confirmer — ${provider.totalPanier.toStringAsFixed(0)} FCFA',
                      icon: Icons.shopping_cart_checkout,
                      color: AppColors.primary,
                      onPressed: _confirmerCommande,
                    ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModePaiementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModePaiementButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            Text(label, style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}