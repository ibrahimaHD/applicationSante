import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';
import '../models/medicament_model.dart';

class PanierItem extends StatelessWidget {
  final ArticlePanier article;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const PanierItem({
    super.key,
    required this.article,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.medication_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.medicament.nom,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${article.medicament.prix.toStringAsFixed(0)} FCFA / unité',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: () => onQuantityChanged(article.quantite - 1),
                color: AppColors.error,
              ),
              Text(
                '${article.quantite}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => onQuantityChanged(article.quantite + 1),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}