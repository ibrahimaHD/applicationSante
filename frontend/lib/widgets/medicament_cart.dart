import 'package:flutter/material.dart';
import '../../../constants/app_constants.dart';

class MedicamentCard extends StatelessWidget {
  final Medicament medicament;
  final VoidCallback onAddToCart;

  const MedicamentCard({
    super.key,
    required this.medicament,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final estEnRupture = medicament.stock == 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Icon(Icons.medication_outlined, color: AppColors.primary, size: 36),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            medicament.nom,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (medicament.categorie != null) ...[
            const SizedBox(height: 2),
            Text(
              medicament.categorie!,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          if (medicament.ordonnanceRequise)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Ordonnance',
                style: TextStyle(fontSize: 9, color: Colors.orange, fontWeight: FontWeight.w600),
              ),
            ),
          const Spacer(),
          Row(
            children: [
              Text(
                '${medicament.prix.toStringAsFixed(0)} F',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: estEnRupture ? null : onAddToCart,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: estEnRupture ? Colors.grey : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    estEnRupture ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 16,
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