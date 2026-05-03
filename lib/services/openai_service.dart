import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ai/scanbite_ai_gateway.dart';

class OpenAIService {
  /// -----------------------------
  /// FACTORY FALLBACK TIPS (used if AI fails)
  /// -----------------------------
  static const List<Map<String, String>> _factoryTips = [
    {
      'category': 'general',
      'tip':
      'Prioritize whole foods—fruits, vegetables, lean proteins—and scan meals to stay consistent.',
    },
    {
      'category': 'hydration',
      'tip': 'Drink water throughout the day—aim for a glass with every meal.',
    },
    {
      'category': 'portion',
      'tip': 'Use smaller plates and scan your meals to stay mindful of portion size.',
    },
    {
      'category': 'balance',
      'tip': 'Build balanced meals: protein + fiber + healthy fats for better energy.',
    },
    {
      'category': 'timing',
      'tip': 'Try to finish your last meal 2–3 hours before bed for better digestion.',
    },
    {
      'category': 'Blood Sugar',
      'tip':
      'If you’re managing blood sugar, prioritize fiber and protein, and watch added sugars.',
    },
  ];

  /// -----------------------------
  /// 1) Analyze food image (Vision) — NOW via Firebase Cloud Function (no key on device)
  /// -----------------------------
  Future<Map<String, dynamic>> analyzeFood(
      File imageFile, {
        Map<String, dynamic>? userContext,
      }) async {
    try {
      print('🔍 Starting AI analysis (via Firebase)...');

      // Read + encode image
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      print('📸 Image encoded, size: ${bytes.length} bytes');

      // Build prompt (unchanged)
      final prompt = _buildPrompt(userContext);

      print('💬 Sending request to Cloud Function (vision)...');

      // ✅ Call Firebase backend (vision)
      final content = await ScanBiteAIGateway.vision(
        prompt: prompt,
        imageBase64: base64Image,
        imageMime: 'image/jpeg',
      );

      print('✅ Raw response: $content');

      // Extract JSON from response (unchanged)
      final jsonData = _extractJson(content);

      print('✅ Parsed data keys: ${jsonData.keys}');
      return jsonData;
    } catch (e, stackTrace) {
      print('🔥 AI Service Error: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to analyze food: $e');
    }
  }

  /// Build personalized prompt based on user context
  String _buildPrompt(Map<String, dynamic>? userContext) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Analyze the food in this image and return a JSON object with the following structure:');
    buffer.writeln('{');
    buffer.writeln('  "foodName": "name of the dish",');
    buffer.writeln('  "servingSize": "e.g., 1 plate, 200g",');
    buffer.writeln('  "calories": number,');
    buffer.writeln('  "protein": number (grams),');
    buffer.writeln('  "carbs": number (grams),');
    buffer.writeln('  "fats": number (grams),');
    buffer.writeln('  "fiber": number (grams),');
    buffer.writeln('  "sugar": number (grams),');
    buffer.writeln('  "sodium": number (mg),');
    buffer.writeln('  "healthScore": number (0-100, higher is healthier),');
    buffer.writeln('  "allergens": ["list", "of", "allergens"],');
    buffer.writeln('  "isBloodSugarFriendly": boolean,');
    buffer.writeln('  "ingredients": ["main", "ingredients"],');
    buffer.writeln('  "healthBenefits": ["benefit1", "benefit2"],');
    buffer.writeln('  "healthRisks": ["risk1", "risk2"],');
    buffer.writeln('  "mealType": "breakfast/lunch/dinner/snack",');
    buffer.writeln('  "aiInsights": "personalized advice"');
    buffer.writeln('}');

    if (userContext != null) {
      buffer.writeln('\nUser Profile:');

      if (userContext['age'] != null) {
        buffer.writeln('- Age: ${userContext['age']}');
      }

      if (userContext['goal'] != null) {
        buffer.writeln('- Goal: ${userContext['goal']}');
      }

      if (userContext['isBloodSugarFriendly'] == true) {
        buffer.writeln(
            '- IMPORTANT: User isBloodSugar. Check sugar content carefully.');
      }

      if (userContext['allergyList'] != null &&
          (userContext['allergyList'] as List).isNotEmpty) {
        buffer.writeln(
            '- Allergies: ${(userContext['allergyList'] as List).join(", ")}');
        buffer.writeln(
            '  IMPORTANT: Check for these allergens and warn in healthRisks if found.');
      }

      if (userContext['dietaryRestrictions'] != null &&
          (userContext['dietaryRestrictions'] as List).isNotEmpty) {
        buffer.writeln(
            '- Dietary restrictions: ${(userContext['dietaryRestrictions'] as List).join(", ")}');
      }

      if (userContext['dailyCalorieGoal'] != null) {
        buffer.writeln(
            '- Daily calorie goal: ${userContext['dailyCalorieGoal']} kcal');
      }

      buffer.writeln(
          '\nProvide personalized insights in the "aiInsights" field based on the user profile.');
    }

    return buffer.toString();
  }

  /// Extract JSON from AI response (removes markdown formatting)
  Map<String, dynamic> _extractJson(String content) {
    try {
      print('🔍 Extracting JSON from response...');

      // Remove all markdown code blocks
      String cleaned = content.trim();
      cleaned = cleaned.replaceAll('```json', '');
      cleaned = cleaned.replaceAll('```', '');
      cleaned = cleaned.trim();

      final previewLen = cleaned.length > 200 ? 200 : cleaned.length;
      print(
          '📝 Cleaned content (first $previewLen chars): ${cleaned.substring(0, previewLen)}');

      // Use regex to find JSON object (handles nested objects)
      final jsonMatch =
      RegExp(r'\{(?:[^{}]|(?:\{[^{}]*\}))*\}', dotAll: true)
          .firstMatch(cleaned);

      if (jsonMatch == null) {
        print('❌ No JSON object found in response');
        print('Full content: $content');
        throw Exception('No valid JSON found in AI response');
      }

      final jsonString = jsonMatch.group(0)!;
      print('✅ JSON extracted (${jsonString.length} chars)');

      final parsed = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate required fields
      if (!parsed.containsKey('foodName') || !parsed.containsKey('calories')) {
        print('⚠️ Missing required fields, adding defaults...');
        parsed['foodName'] = parsed['foodName'] ?? 'Unknown Food';
        parsed['calories'] = parsed['calories'] ?? 0;
      }

      print('✅ JSON parsed successfully: ${parsed['foodName']}');
      return parsed;
    } catch (e, stackTrace) {
      print('❌ JSON extraction error: $e');
      print('Stack trace: $stackTrace');
      print('Full content was: $content');

      // Return fallback data instead of throwing
      print('⚠️ Returning fallback nutrition data');
      return {
        'foodName': 'Unknown Food',
        'servingSize': '1 serving',
        'calories': 200,
        'protein': 10.0,
        'carbs': 25.0,
        'fats': 8.0,
        'fiber': 3.0,
        'sugar': 5.0,
        'sodium': 150.0,
        'healthScore': 50,
        'allergens': [],
        'isBloodSugarFriendly': true,
        'ingredients': ['Unable to analyze'],
        'healthBenefits': ['Provides energy'],
        'healthRisks': [
          'AI analysis failed - please try again with a clearer photo'
        ],
        'mealType': 'snack',
        'aiInsights':
        'Image analysis encountered an error. Please try again or use a different photo.',
      };
    }
  }

  /// -----------------------------
  /// 2) Barcode analysis (Open Food Facts) — unchanged
  /// -----------------------------
  Future<Map<String, dynamic>?> analyzeBarcode(String barcode) async {
    try {
      print('🔍 Analyzing barcode: $barcode');

      final response = await http.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
      );

      if (response.statusCode != 200) {
        print('❌ Product not found');
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 1) {
        print('❌ Invalid product');
        return null;
      }

      final product = data['product'];
      final nutriments = product['nutriments'];

      double parseValue(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        return double.tryParse(value.toString()) ?? 0.0;
      }

      return {
        'foodName': product['product_name'] ?? 'Unknown Product',
        'servingSize': product['quantity'] ?? '100g',
        'calories': parseValue(nutriments['energy-kcal_100g']),
        'protein': parseValue(nutriments['proteins_100g']),
        'carbs': parseValue(nutriments['carbohydrates_100g']),
        'fats': parseValue(nutriments['fat_100g']),
        'fiber': parseValue(nutriments['fiber_100g']),
        'sugar': parseValue(nutriments['sugars_100g']),
        'sodium': parseValue(nutriments['sodium_100g']),
        'healthScore': 50,
        'allergens': product['allergens_tags'] ?? [],
        'isBloodSugarFriendly': parseValue(nutriments['sugars_100g']) < 5,
        'ingredients': product['ingredients_text']?.split(',') ?? [],
        'healthBenefits': [],
        'healthRisks': [],
        'mealType': 'snack',
        'aiInsights': 'Product information from barcode scan',
      };
    } catch (e) {
      print('❌ Barcode analysis error: $e');
      return null;
    }
  }

  /// -----------------------------
  /// 3) Personalized DAILY TIP (AI) — NOW via Firebase Cloud Function + fallback
  /// -----------------------------
  Future<Map<String, String>> generatePersonalizedDailyTip({
    required Map<String, dynamic> userContext,
  }) async {
    try {
      final prompt = _buildDailyTipPrompt(userContext);

      // ✅ Call Firebase backend (text)
      final content = await ScanBiteAIGateway.text(prompt: prompt);

      if (content.trim().isEmpty) {
        return _pickFactoryTip(userContext);
      }

      // Expect:
      // {"tip":"...","category":"..."}
      final cleaned =
      content.replaceAll('```json', '').replaceAll('```', '').trim();

      final map = jsonDecode(cleaned);

      final tip =
      (map is Map && map['tip'] != null) ? map['tip'].toString() : '';
      final category = (map is Map && map['category'] != null)
          ? map['category'].toString()
          : 'general';

      if (tip.trim().isEmpty) {
        return _pickFactoryTip(userContext);
      }

      return {'tip': tip.trim(), 'category': category.trim()};
    } catch (e) {
      print('❌ Daily tip generation failed: $e');
      return _pickFactoryTip(userContext);
    }
  }

  String _buildDailyTipPrompt(Map<String, dynamic> userContext) {
    final sb = StringBuffer();
    sb.writeln('Generate ONE short daily nutrition tip personalized to this user.');
    sb.writeln(
        'Return JSON only: {"tip":"...","category":"general|hydration|portion|balance|timing|diabetic"}');
    sb.writeln('');
    sb.writeln('User context:');

    if (userContext['age'] != null) sb.writeln('- age: ${userContext['age']}');
    if (userContext['goal'] != null) sb.writeln('- goal: ${userContext['goal']}');
    if (userContext['bmi'] != null) sb.writeln('- bmi: ${userContext['bmi']}');
    if (userContext['isBloodSugarFriendly'] == true) sb.writeln('- BloodSugarFriendly  : true');

    final allergyList = userContext['allergyList'];
    if (allergyList is List && allergyList.isNotEmpty) {
      sb.writeln('- allergies: ${allergyList.join(", ")}');
    }

    final restrictions = userContext['dietaryRestrictions'];
    if (restrictions is List && restrictions.isNotEmpty) {
      sb.writeln('- dietaryRestrictions: ${restrictions.join(", ")}');
    }

    final calGoal = userContext['dailyCalorieGoal'];
    if (calGoal != null) sb.writeln('- dailyCalorieGoal: $calGoal');

    sb.writeln('');
    sb.writeln('Rules:');
    sb.writeln('- Keep tip under 180 characters if possible.');
    sb.writeln('- Avoid medical claims. If diabetic, focus on sugar/fiber/protein balance.');
    sb.writeln('- Make it practical for today.');

    return sb.toString();
  }

  Map<String, String> _pickFactoryTip(Map<String, dynamic> userContext) {
    // If diabetic -> prefer diabetic tip
    if (userContext['isBloodSugarFriendly'] == true) {
      final diabetic = _factoryTips.firstWhere(
            (t) => t['category'] == 'diabetic',
        orElse: () => _factoryTips.first,
      );
      return {
        'tip': diabetic['tip'] ?? _factoryTips.first['tip']!,
        'category': diabetic['category'] ?? 'general',
      };
    }

    // Otherwise choose a stable "daily" one based on date
    final idx = DateTime.now().day % _factoryTips.length;
    final chosen = _factoryTips[idx];
    return {
      'tip': chosen['tip'] ?? _factoryTips.first['tip']!,
      'category': chosen['category'] ?? 'general',
    };
  }

  /// -----------------------------
  /// 4) Risk Score logic (unchanged)
  /// -----------------------------
  Map<String, dynamic> calculateRiskScore(Map<String, dynamic> nutritionData) {
    final calories = nutritionData['calories'] ?? 0;
    final sugar = nutritionData['sugar'] ?? 0;
    final sodium = nutritionData['sodium'] ?? 0;
    final fats = nutritionData['fats'] ?? 0;

    final calorieRisk = _calculateCalorieRisk(calories.toDouble());
    final sugarRisk = _calculateSugarRisk(sugar.toDouble());
    final sodiumRisk = _calculateSodiumRisk(sodium.toDouble());
    final fatRisk = _calculateFatRisk(fats.toDouble());

    final overallRisk = (calorieRisk + sugarRisk + sodiumRisk + fatRisk) / 4;

    return {
      'overallRisk': overallRisk.round(),
      'calorieRisk': calorieRisk.round(),
      'sugarRisk': sugarRisk.round(),
      'sodiumRisk': sodiumRisk.round(),
      'fatRisk': fatRisk.round(),
      'level': overallRisk < 30
          ? 'low'
          : overallRisk < 60
          ? 'medium'
          : 'high',
      'recommendations': _generateRecommendations(
        calorieRisk,
        sugarRisk,
        sodiumRisk,
        fatRisk,
      ),
    };
  }

  double _calculateCalorieRisk(double calories) {
    if (calories < 200) return 10;
    if (calories < 400) return 25;
    if (calories < 600) return 50;
    if (calories < 800) return 75;
    return 90;
  }

  double _calculateSugarRisk(double sugar) {
    if (sugar < 5) return 10;
    if (sugar < 10) return 30;
    if (sugar < 20) return 60;
    if (sugar < 30) return 80;
    return 95;
  }

  double _calculateSodiumRisk(double sodium) {
    if (sodium < 200) return 10;
    if (sodium < 400) return 30;
    if (sodium < 600) return 60;
    if (sodium < 800) return 80;
    return 95;
  }

  double _calculateFatRisk(double fats) {
    if (fats < 10) return 10;
    if (fats < 20) return 30;
    if (fats < 30) return 60;
    if (fats < 40) return 80;
    return 95;
  }

  List<String> _generateRecommendations(
      double calorieRisk,
      double sugarRisk,
      double sodiumRisk,
      double fatRisk,
      ) {
    final recommendations = <String>[];

    if (calorieRisk > 60) recommendations.add('Consider smaller portions');
    if (sugarRisk > 60) recommendations.add('High sugar content - limit intake');
    if (sodiumRisk > 60) recommendations.add('High sodium - drink plenty of water');
    if (fatRisk > 60) recommendations.add('Balance with lean protein and vegetables');

    if (recommendations.isEmpty) recommendations.add('Great balanced meal!');
    return recommendations;
  }
}