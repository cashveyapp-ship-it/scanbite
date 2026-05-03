import 'package:flutter/material.dart';
import '../models/nutrition_data.dart';
import '../utils/helpers.dart';

class NutritionCard extends StatelessWidget {
  final NutritionData nutritionData;

  const NutritionCard({Key? key, required this.nutritionData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Health Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Health Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Helpers.getHealthScoreColor(nutritionData.healthScore),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${nutritionData.healthScore}/100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Macronutrients
            _buildMacroRow('Calories', '${nutritionData.calories} kcal', Icons.local_fire_department),
            _buildMacroRow('Carbs', '${nutritionData.carbs.toStringAsFixed(1)}g', Icons.grain),
            _buildMacroRow('Protein', '${nutritionData.protein.toStringAsFixed(1)}g', Icons.fitness_center),
            _buildMacroRow('Fat', '${nutritionData.fat.toStringAsFixed(1)}g', Icons.opacity),
            _buildMacroRow('Sugar', '${nutritionData.sugar.toStringAsFixed(1)}g', Icons.cake),
            _buildMacroRow('Fiber', '${nutritionData.fiber.toStringAsFixed(1)}g', Icons.eco),

            const Divider(height: 24),

            // Diabetic Friendly
            Row(
              children: [
                Icon(
                  nutritionData.isDiabeticFriendly ? Icons.check_circle : Icons.warning,
                  color: nutritionData.isDiabeticFriendly ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  nutritionData.isDiabeticFriendly
                      ? 'blood sugar Friendly'
                      : 'Not blood sugar Friendly',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: nutritionData.isDiabeticFriendly ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),

            if (nutritionData.allergens.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Allergens',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: nutritionData.allergens.map((allergen) {
                  return Chip(
                    label: Text(allergen),
                    backgroundColor: Colors.red.shade100,
                    labelStyle: const TextStyle(color: Colors.red),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}