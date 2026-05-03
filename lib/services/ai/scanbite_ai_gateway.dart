import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ScanBiteAIGateway {
  // ✅ Change this if your Cloud Function is deployed to a different region
  static const String _region = 'us-central1';

  static HttpsCallable _callable({required Duration timeout}) {
    return FirebaseFunctions.instanceFor(region: _region).httpsCallable(
      'scanbiteOpenAI',
      options: HttpsCallableOptions(timeout: timeout),
    );
  }

  static Future<String> text({required String prompt}) async {
    final res = await _callable(timeout: const Duration(seconds: 60)).call({
      'mode': 'text',
      'prompt': prompt,
    });

    final data = Map<String, dynamic>.from(res.data as Map);
    if (data['ok'] == true) return (data['content'] ?? '').toString();
    throw Exception(data['error'] ?? 'AI request failed');
  }

  static Future<String> vision({
    required String prompt,
    required String imageBase64,
    String imageMime = 'image/jpeg',
  }) async {
    final res = await _callable(timeout: const Duration(seconds: 90)).call({
      'mode': 'vision',
      'prompt': prompt,
      'imageBase64': imageBase64,
      'imageMime': imageMime,
    });

    final data = Map<String, dynamic>.from(res.data as Map);
    if (data['ok'] == true) return (data['content'] ?? '').toString();
    throw Exception(data['error'] ?? 'AI request failed');
  }

  static String buildVisionPrompt(Map<String, dynamic>? userContext) {
    final b = StringBuffer();
    b.writeln('Return ONLY valid JSON with this structure:');
    b.writeln('{');
    b.writeln('  "foodName": "name of the dish",');
    b.writeln('  "servingSize": "e.g., 1 plate, 200g",');
    b.writeln('  "calories": number,');
    b.writeln('  "protein": number,');
    b.writeln('  "carbs": number,');
    b.writeln('  "fats": number,');
    b.writeln('  "fiber": number,');
    b.writeln('  "sugar": number,');
    b.writeln('  "sodium": number,');
    b.writeln('  "healthScore": number (0-100),');
    b.writeln('  "allergens": ["..."],');
    b.writeln('  "isBloodSugarFriendly": boolean,');
    b.writeln('  "ingredients": ["..."],');
    b.writeln('  "healthBenefits": ["..."],');
    b.writeln('  "healthRisks": ["..."],');
    b.writeln('  "mealType": "breakfast/lunch/dinner/snack",');
    b.writeln('  "aiInsights": "short practical advice"');
    b.writeln('}');
    b.writeln('Rules: JSON only. No markdown. Educational info only.');

    if (userContext != null) {
      b.writeln('');
      b.writeln('User context:');
      if (userContext['age'] != null) b.writeln('- age: ${userContext['age']}');
      if (userContext['goal'] != null) b.writeln('- goal: ${userContext['goal']}');
      if (userContext['dailyCalorieGoal'] != null) {
        b.writeln('- dailyCalorieGoal: ${userContext['dailyCalorieGoal']}');
      }
      final allergies = userContext['allergyList'];
      if (allergies is List && allergies.isNotEmpty) {
        b.writeln('- allergies: ${allergies.join(", ")}');
      }
      final restrictions = userContext['dietaryRestrictions'];
      if (restrictions is List && restrictions.isNotEmpty) {
        b.writeln('- dietaryRestrictions: ${restrictions.join(", ")}');
      }
    }

    return b.toString();
  }

  /// Compress image before encoding.
  /// Reduces payload from ~8MB raw to ~100–150KB — biggest speed win for the AI call.
  static Future<List<int>> _compressImage(File imageFile) async {
    try {
      final compressed = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        minWidth: 800,
        minHeight: 800,
        quality: 72,
        format: CompressFormat.jpeg,
      );

      if (compressed != null && compressed.isNotEmpty) {
        final originalKb = (await imageFile.length()) ~/ 1024;
        final compressedKb = compressed.length ~/ 1024;
        print('📦 Image: ${originalKb}KB → ${compressedKb}KB');
        return compressed;
      }
    } catch (e) {
      print('⚠️ Compression failed, using raw bytes: $e');
    }
    return await imageFile.readAsBytes();
  }

  static Future<Map<String, dynamic>> analyzeFoodImage({
    required File imageFile,
    required String prompt,
    Map<String, dynamic>? userContext,
  }) async {
    final bytes = await _compressImage(imageFile);
    final b64 = base64Encode(bytes);

    final content = await vision(
      prompt: prompt,
      imageBase64: b64,
      imageMime: 'image/jpeg',
    );

    final cleaned = content
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (match == null) throw Exception('AI returned non-JSON content');

    final map = Map<String, dynamic>.from(jsonDecode(match.group(0)!));

    final bsf = (map['isBloodSugarFriendly'] == true);
    map['isDiabeticFriendly'] = map['isDiabeticFriendly'] ?? bsf;

    return map;
  }
}