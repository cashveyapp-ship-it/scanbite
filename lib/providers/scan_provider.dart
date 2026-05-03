import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

import '../models/food_scan.dart';
import '../services/firebase_service.dart';
import '../services/openai_service.dart';
import '../services/ai/scanbite_ai_gateway.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ScanProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final OpenAIService _openAIService = OpenAIService();

  List<FoodScan> _scans = [];
  bool _isLoading = false;
  String? _currentUserId;

  List<FoodScan> get scans => _scans;
  bool get isLoading => _isLoading;

  void loadUserScans(String userId) {
    print('🔐 [SCAN PROVIDER] Loading scans for user: $userId');

    if (_currentUserId != userId) {
      print('📝 [USER SWITCH] Loading scans for different user');
      _scans = [];
      _currentUserId = userId;
      notifyListeners();
    }

    _firebaseService.getUserScans(userId).listen(
          (scans) {
        print('🎯 [SCAN PROVIDER] Stream received ${scans.length} scans');

        _scans = scans.where((scan) {
          if (scan.userId != userId) {
            print('⚠️ [SECURITY ALERT] Blocking scan ${scan.id} - wrong user!');
            return false;
          }
          return true;
        }).toList();

        print('✅ [SCAN PROVIDER] Final count: ${_scans.length} scans');
        notifyListeners();
      },
      onError: (error) {
        print('❌ [SCAN PROVIDER] Stream error: $error');
        _scans = [];
        notifyListeners();
      },
    );
  }

  // ─────────────────────────────────────────────
  // BARCODE VALIDATION
  // ─────────────────────────────────────────────

  /// Returns true if the scanned string looks like a real product barcode.
  /// Rejects QR codes containing URLs, emails, plain text, Wi-Fi configs, etc.
  static bool isProductBarcode(String raw) {
    final trimmed = raw.trim();

    // Reject URLs (QR codes often encode URLs)
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('www.')) {
      return false;
    }

    // Reject other common QR payload types
    if (trimmed.startsWith('mailto:') ||
        trimmed.startsWith('tel:') ||
        trimmed.startsWith('WIFI:') ||
        trimmed.startsWith('geo:') ||
        trimmed.startsWith('BEGIN:VCARD') ||
        trimmed.startsWith('smsto:')) {
      return false;
    }

    // Reject if it contains spaces (product barcodes are purely numeric)
    if (trimmed.contains(' ')) return false;

    // Must be digits only
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) return false;

    // Valid product barcode lengths: UPC-A (12), EAN-13 (13), EAN-8 (8), UPC-E (6)
    return trimmed.length == 6 ||
        trimmed.length == 8 ||
        trimmed.length == 12 ||
        trimmed.length == 13 ||
        trimmed.length == 14; // GTIN-14 / ITF-14
  }

  // ─────────────────────────────────────────────
  // AI IMAGE ANALYSIS
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeFoodImage(
      File imageFile,
      Map<String, dynamic>? userContext,
      ) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prompt = ScanBiteAIGateway.buildVisionPrompt(userContext);

      final result = await ScanBiteAIGateway.analyzeFoodImage(
        imageFile: imageFile,
        prompt: prompt,
        userContext: userContext,
      );

      _isLoading = false;
      notifyListeners();
      return result;
    } on FirebaseFunctionsException catch (e) {
      _isLoading = false;
      notifyListeners();
      print('❌ Functions error: code=${e.code} message=${e.message} details=${e.details}');
      rethrow;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ─────────────────────────────────────────────
  // BARCODE ANALYSIS
  // ─────────────────────────────────────────────

  Future<Map<String, dynamic>> analyzeBarcode(String barcode) async {
    final trimmed = barcode.trim();

    // ✅ Reject QR codes / URLs / non-product codes up front
    if (!isProductBarcode(trimmed)) {
      print('⚠️ Scanned value is not a product barcode: $trimmed');
      throw Exception('qr_code'); // caught by camera_screen for friendly message
    }

    try {
      print('🔍 Looking up barcode: $trimmed');

      final productResponse = await http.get(
        Uri.parse(
            'https://world.openfoodfacts.org/api/v0/product/$trimmed.json'),
        headers: {'User-Agent': 'ScanBite/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (productResponse.statusCode != 200) {
        throw Exception('not_found');
      }

      final productData = jsonDecode(productResponse.body);

      if (productData['status'] != 1) {
        throw Exception('not_found');
      }

      final product = productData['product'];
      final productName =
      (product['product_name'] ?? '').toString().trim();

      if (productName.isEmpty) {
        throw Exception('not_found');
      }

      final imageUrl = product['image_url'] ??
          product['image_front_url'] ??
          product['image_front_small_url'] ??
          '';

      final nutriments = product['nutriments'] ?? {};
      final calories = ((nutriments['energy-kcal_100g'] ?? 0) as num).toInt();
      final protein = ((nutriments['proteins_100g'] ?? 0) as num).toDouble();
      final carbs =
      ((nutriments['carbohydrates_100g'] ?? 0) as num).toDouble();
      final fats = ((nutriments['fat_100g'] ?? 0) as num).toDouble();
      final fiber = ((nutriments['fiber_100g'] ?? 0) as num).toDouble();
      final sugar = ((nutriments['sugars_100g'] ?? 0) as num).toDouble();
      final sodium =
          ((nutriments['sodium_100g'] ?? 0) as num).toDouble() * 1000;

      final allergensList = (product['allergens_tags'] as List?)
          ?.map((e) => e
          .toString()
          .replaceAll('en:', '')
          .replaceAll('-', ' '))
          .toList() ??
          [];

      final ingredientsList = (product['ingredients_text_en'] ??
          product['ingredients_text'] ??
          'Not available')
          .toString()
          .split(',')
          .take(5)
          .map((s) => s.trim())
          .toList();

      print('✅ Product found: $productName');

      // AI health analysis (non-blocking fallback)
      Map<String, dynamic> aiAnalysis = {
        'healthScore': 50,
        'isBloodSugarFriendly': sugar < 10,
        'healthBenefits': ['Provides essential nutrients'],
        'healthRisks': ['Check allergen information'],
        'aiInsights': 'Nutrition information retrieved from product database',
      };

      try {
        final prompt = '''
Product: $productName
Nutrition per 100g:
- Calories: $calories kcal
- Protein: ${protein}g
- Carbs: ${carbs}g
- Fats: ${fats}g
- Fiber: ${fiber}g
- Sugar: ${sugar}g
- Sodium: ${sodium}mg
- Allergens: ${allergensList.join(', ')}

Provide health analysis in JSON format:
{
  "healthScore": number (0-100),
  "isBloodSugarFriendly": boolean,
  "healthBenefits": ["list of 2-3 benefits"],
  "healthRisks": ["list of 2-3 risks"],
  "aiInsights": "Brief 1-2 sentence insight"
}

Rules:
- Educational information only. Avoid medical claims.
- Keep insights short and practical.
- Return ONLY valid JSON (no markdown).
''';

        final content = await ScanBiteAIGateway.text(prompt: prompt);
        final cleaned =
        content.replaceAll('```json', '').replaceAll('```', '').trim();
        final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);

        if (jsonMatch != null) {
          aiAnalysis = jsonDecode(jsonMatch.group(0)!);
        }
      } catch (e) {
        print('⚠️ AI barcode analysis failed, using defaults: $e');
      }

      final bool bloodSugarFriendly =
          (aiAnalysis['isBloodSugarFriendly'] ?? (sugar < 10)) == true;

      return {
        'foodName': productName,
        'imageUrl': imageUrl,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fats': fats,
        'fiber': fiber,
        'sugar': sugar,
        'sodium': sodium,
        'healthScore': aiAnalysis['healthScore'] ?? 50,
        'allergens': allergensList,
        'isBloodSugarFriendly': bloodSugarFriendly,
        'isDiabeticFriendly': bloodSugarFriendly,
        'ingredients': ingredientsList,
        'healthBenefits':
        List<String>.from(aiAnalysis['healthBenefits'] ?? ['Provides nutrition']),
        'healthRisks':
        List<String>.from(aiAnalysis['healthRisks'] ?? ['Check serving size']),
        'mealType': 'snack',
        'servingSize': '100g',
        'aiInsights': aiAnalysis['aiInsights'] ??
            'Product information from Open Food Facts database',
      };
    } catch (e) {
      print('❌ Error in barcode analysis: $e');
      // Preserve sentinel codes so camera_screen can show the right message
      final msg = e.toString();
      if (msg.contains('qr_code')) rethrow;
      if (msg.contains('not_found')) throw Exception('not_found');
      throw Exception('not_found');
    }
  }

  // ─────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────

  Future<void> deleteScan(String scanId) async {
    try {
      await _firebaseService.deleteScan(scanId);
      _scans.removeWhere((scan) => scan.id == scanId);
      notifyListeners();
      print('✅ Scan deleted: $scanId');
    } catch (e) {
      print('❌ Error deleting scan: $e');
      rethrow;
    }
  }
}