import 'package:flutter/material.dart';
import '../models/food_scan.dart';
import '../utils/constants.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'camera_screen.dart';

class ResultScreen extends StatelessWidget {
  final FoodScan scan;

  const ResultScreen({Key? key, required this.scan}) : super(key: key);

  // 👇 ADD THIS HERE
  void _showNutritionSourcesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nutrition Sources & Disclaimer'),
        content: const SingleChildScrollView(
          child: Text(
            'Nutritional information is estimated using AI analysis and publicly available food data sources, including USDA FoodData Central and FDA nutrition guidance.\n\n'
                'ScanBite provides general nutrition insights for informational and educational purposes only. Results may not be exact and should not be considered medical advice, diagnosis, or treatment guidance.\n\n'
                'For medical, allergy, diet, or health-related concerns, please consult a qualified healthcare professional.\n\n'
                'Sources:\n'
                '• USDA FoodData Central: https://fdc.nal.usda.gov/\n'
                '• FDA Nutrition Facts and Labeling Guidance: https://www.fda.gov/food',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final nutrition = scan.nutritionData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Results'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),

      // ✅ Sticky Scan Another button
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, -3),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.camera_alt),
            label: const Text(
              'Scan Another',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CameraScreen(),
                ),
              );
            },
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildFoodImage(),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nutrition.foodName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(scan.scannedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nutrition.servingSize,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),

                  _buildHealthScoreCard(nutrition.healthScore),
                  const SizedBox(height: 16),

                  _buildNutritionCard(nutrition),
                  const SizedBox(height: 16),

                  if (nutrition.aiInsights.isNotEmpty)
                    _buildAIInsightsCard(nutrition.aiInsights),

                  if (nutrition.healthBenefits.isNotEmpty)
                    _buildListCard(
                      'Nutrition Insights',
                      nutrition.healthBenefits,
                      AppConstants.successColor,
                      Icons.check_circle,
                    ),

                  if (nutrition.healthRisks.isNotEmpty)
                    _buildListCard(
                      'Nutrition Considerations',
                      nutrition.healthRisks,
                      AppConstants.dangerColor,
                      Icons.warning,
                    ),

                  if (nutrition.allergens.isNotEmpty)
                    _buildAllergenCard(nutrition.allergens),

                  if (nutrition.ingredients.isNotEmpty)
                    _buildIngredientsCard(nutrition.ingredients),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade100,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Not medical advice',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Nutrition values are AI-generated estimates and may vary. Sources include USDA FoodData Central and FDA nutrition guidance.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        TextButton.icon(
                          onPressed: () => _showNutritionSourcesDialog(context),
                          icon: const Icon(
                            Icons.info_outline,
                            size: 18,
                          ),
                          label: const Text(
                            'View Nutrition Sources',
                          ),
                        ),
                      ],
                    ),
                  ),


                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodImage() {
    if (scan.imageUrl.isEmpty) {
      return Container(
        height: 250,
        color: Colors.grey[300],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.qr_code, size: 80, color: Colors.grey),
              SizedBox(height: 8),
              Text('Barcode Scan', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    final isNetworkImage = scan.imageUrl.startsWith('http');

    return Hero(
      tag: 'food_image_${scan.id}',
      child: Container(
        height: 250,
        width: double.infinity,
        color: Colors.grey[300],
        child: isNetworkImage
            ? Image.network(
          scan.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        )
            : Image.file(
          File(scan.imageUrl),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorImage();
          },
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 80, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image not available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthScoreCard(int healthScore) {
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (healthScore >= 70) {
      scoreColor = AppConstants.successColor;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.check_circle;
    } else if (healthScore >= 50) {
      scoreColor = AppConstants.warningColor;
      scoreLabel = 'Good';
      scoreIcon = Icons.warning;
    } else {
      scoreColor = AppConstants.dangerColor;
      scoreLabel = 'Poor';
      scoreIcon = Icons.error;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scoreColor.withOpacity(0.2), scoreColor.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: scoreColor, shape: BoxShape.circle),
              child: Icon(scoreIcon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AI Nutrition Score',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scoreLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$healthScore/100',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(nutrition) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nutrition Facts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            _buildNutrientRow('Calories', '${nutrition.calories} kcal', AppConstants.accentColor),
            const SizedBox(height: 12),
            _buildNutrientRow('Protein', '${nutrition.protein.toStringAsFixed(1)}g', AppConstants.primaryColor),
            const SizedBox(height: 12),
            _buildNutrientRow('Carbs', '${nutrition.carbs.toStringAsFixed(1)}g', AppConstants.warningColor),
            const SizedBox(height: 12),
            _buildNutrientRow('Fats', '${nutrition.fats.toStringAsFixed(1)}g', AppConstants.dangerColor),
            const SizedBox(height: 12),
            _buildNutrientRow('Fiber', '${nutrition.fiber.toStringAsFixed(1)}g', AppConstants.successColor),
            const SizedBox(height: 12),
            _buildNutrientRow('Sugar', '${nutrition.sugar.toStringAsFixed(1)}g', Colors.pink),
            const SizedBox(height: 12),
            _buildNutrientRow('Sodium', '${nutrition.sodium.toStringAsFixed(0)}mg', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildAIInsightsCard(String insights) {
    return Card(
      elevation: 2,
      color: AppConstants.primaryColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.lightbulb, color: AppConstants.primaryColor),
              const SizedBox(width: 8),
              const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            Text(insights, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(String title, List<String> items, Color color, IconData icon) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.circle, size: 6, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(item, style: const TextStyle(fontSize: 14))),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildAllergenCard(List<String> allergens) {
    return Card(
      elevation: 2,
      color: AppConstants.dangerColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.warning, color: AppConstants.dangerColor),
            const SizedBox(width: 8),
            const Text('Allergen Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergens.map((allergen) {
              return Chip(
                label: Text(allergen),
                backgroundColor: AppConstants.dangerColor.withOpacity(0.2),
                labelStyle: TextStyle(color: AppConstants.dangerColor),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  Widget _buildIngredientsCard(List<String> ingredients) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Row(children: [
            Icon(Icons.list, color: AppConstants.primaryColor),
            SizedBox(width: 8),
            Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text(ingredients.join(', '), style: const TextStyle(fontSize: 14)),
        ]),
      ),
    );
  }
}
