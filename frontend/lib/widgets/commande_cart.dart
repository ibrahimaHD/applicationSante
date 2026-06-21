import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../constants/app_constants.dart';
import '../models/medicament_model.dart';

class CommandeCard extends StatelessWidget {
  final Commande commande;
  final VoidCallback onVoirSuivi;
  final VoidCallback onRenouveler;

  const CommandeCard({
    super.key,
    required this.commande,
    required this.onVoirSuivi,
    required this.onRenouveler,
  });

  Color _statutColor(String statut) {
    switch (statut) {
      case 'en_attente':
        return Colors.orange;
      case 'confirmee':
        return const Color(0xFF1E88E5);
      case 'en_preparation':
        return const Color(0xFF8E24AA);
      case 'en_livraison':
        return const Color(0xFFF4511E);
      case 'livree':
        return AppColors.success;
      case 'annulee':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _statutLabel(String statut) {
    switch (statut) {
      case 'en_attente':
        return 'En attente';
      case 'confirmee':
        return 'Confirmée';
      case 'en_preparation':
        return 'En préparation';
      case 'en_livraison':
        return 'En livraison';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return statut;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statutColor(commande.statut);
    final dateStr = commande.createdAt != null
        ? DateFormat('dd/MM/yyyy').format(commande.createdAt!)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Commande #${commande.id}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statutLabel(commande.statut),
                  style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${commande.montantTotal.toStringAsFixed(0)} FCFA',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          if (dateStr.isNotEmpty)
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          if (commande.articles.isNotEmpty) ...[
            const Divider(height: 16),
            ...commande.articles.take(3).map((a) => Text(
                  '• ${a['medicament_nom']} x${a['quantite']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                )),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onVoirSuivi,
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
                  onPressed: onRenouveler,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Renouveler', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}