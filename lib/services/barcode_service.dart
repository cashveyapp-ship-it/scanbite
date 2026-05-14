import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/nutrition_data.dart';

class BarcodeService {
  // Using OpenFoodFacts API (free and open source)
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v0';

  Future<NutritionData?> getNutritionFromBarcode(String barcode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/product/$barcode.json'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final nutriments = product['nutriments'] ?? {};

          // ✅ FIXED: Build NutritionData using your existing model fields
          return NutritionData(
            foodName: product['product_name']?.toString().trim().isNotEmpty == true
                ? product['product_name'].toString().trim()
                : 'Unknown Food',

            calories: (nutriments['energy-kcal_100g'] ?? 0).toInt(),
            carbs: (nutriments['carbohydrates_100g'] ?? 0).toDouble(),
            protein: (nutriments['proteins_100g'] ?? 0).toDouble(),

            // Your model uses "fats"
            fats: (nutriments['fat_100g'] ?? 0).toDouble(),

            sugar: (nutriments['sugars_100g'] ?? 0).toDouble(),
            fiber: (nutriments['fiber_100g'] ?? 0).toDouble(),

            // Sodium key varies; OpenFoodFacts often uses sodium_100g
            sodium: (nutriments['sodium_100g'] ?? 0).toDouble(),

            allergens: _extractAllergens(product['allergens_tags'] ?? []),
            isDiabeticFriendly: (nutriments['sugars_100g'] ?? 0) < 5,
            healthScore: _calculateHealthScore(nutriments),

            ingredients: _extractIngredients(product['ingredients_text'] ?? ''),
            aiInsights: _buildAiInsights(product, nutriments),
            // Required by your model but not guaranteed by OpenFoodFacts
            healthBenefits: const [],
            healthRisks: const [],

            // Optional defaults (you can improve later)
            mealType: 'snack',

            // OpenFoodFacts nutriments are generally per 100g
            servingSize: '100g',

            // Your model expects aiInsights (we generate a good default)
          );
        }
      }
      return null;
    } catch (e) {
      print('Barcode lookup error: $e');
      return null;
    }
  }

  List<String> _extractAllergens(List<dynamic> allergenTags) {
    final commonAllergens = {
      'gluten': 'Gluten',
      'milk': 'Dairy',
      'eggs': 'Eggs',
      'peanuts': 'Peanuts',
      'nuts': 'Tree Nuts',
      'soy': 'Soy',
      'fish': 'Fish',
      'shellfish': 'Shellfish',
    };

    List<String> allergens = [];
    for (var tag in allergenTags) {
      final tagStr = tag.toString().toLowerCase();
      commonAllergens.forEach((key, value) {
        if (tagStr.contains(key)) {
          allergens.add(value);
        }
      });
    }
    return allergens.toSet().toList();
  }

  List<String> _extractIngredients(String ingredientsText) {
    if (ingredientsText.isEmpty) return [];
    return ingredientsText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  int _calculateHealthScore(Map<String, dynamic> nutriments) {
    int score = 100;

    // Penalize high sugar
    if ((nutriments['sugars_100g'] ?? 0) > 10) score -= 20;

    // Penalize high fat
    if ((nutriments['fat_100g'] ?? 0) > 20) score -= 15;

    // Reward high protein
    if ((nutriments['proteins_100g'] ?? 0) > 10) score += 10;

    // Reward high fiber
    if ((nutriments['fiber_100g'] ?? 0) > 5) score += 10;

    return score.clamp(0, 100);
  }

  // ✅ Used for aiInsights in your NutritionData model
  String _buildAiInsights(
      Map<String, dynamic> product,
      Map<String, dynamic> nutriments,
      ) {
    final name = (product['product_name'] ?? 'This product').toString();
    final sugar = (nutriments['sugars_100g'] ?? 0).toDouble();
    final fat = (nutriments['fat_100g'] ?? 0).toDouble();
    final protein = (nutriments['proteins_100g'] ?? 0).toDouble();

    if (sugar > 10 && fat > 20) {
      return '$name is high in sugar and fat. Consider smaller portions or occasional use.';
    } else if (protein > 10) {
      return '$name is a good protein source and may help with satiety.';
    } else if (sugar <= 5) {
      return '$name is relatively low in sugar, which can be a better option for blood sugar.';
    } else {
      return '$name has a mixed nutrition profile. Balance it with whole foods across your day.';
    }
  }
}
