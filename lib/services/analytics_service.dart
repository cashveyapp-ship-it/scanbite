import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meal_analytics.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get meal analytics for a user over a period of days
  Future<MealAnalytics> getMealAnalytics(String userId, {int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      print('Loading analytics for user: $userId, last $days days');

      final snapshot = await _firestore
          .collection('scans')
          .where('userId', isEqualTo: userId)
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('scannedAt', descending: false)
          .get();

      print('Found ${snapshot.docs.length} scans');

      if (snapshot.docs.isEmpty) {
        return MealAnalytics.empty();
      }

      int totalScans = 0;
      int totalCalories = 0;
      double totalHealthScore = 0;
      Map<String, int> mealDistribution = {};
      List<CaloriesTrendPoint> caloriesTrend = [];
      List<RiskScoreTrendPoint> riskScoreTrend = [];

      // Group scans by date
      Map<String, List<Map<String, dynamic>>> scansByDate = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final nutrition = data['nutritionData'] as Map<String, dynamic>?;

        // Skip scans without nutrition data
        if (nutrition == null) continue;

        final scannedAt = (data['scannedAt'] as Timestamp).toDate();
        final dateKey = '${scannedAt.year}-${scannedAt.month}-${scannedAt.day}';

        if (!scansByDate.containsKey(dateKey)) {
          scansByDate[dateKey] = [];
        }
        scansByDate[dateKey]!.add(data);

        // Accumulate totals
        totalScans++;
        totalCalories += (nutrition['calories'] ?? 0) as int;
        totalHealthScore += (nutrition['healthScore'] ?? 0) as int;

        // Count meal types
        final mealType = nutrition['mealType'] ?? 'snack';
        mealDistribution[mealType] = (mealDistribution[mealType] ?? 0) + 1;
      }

      // Calculate trends
      scansByDate.forEach((dateKey, scans) {
        int dayCalories = 0;
        int dayRiskScore = 0;
        int scanCount = 0;

        for (var scan in scans) {
          final nutrition = scan['nutritionData'] as Map<String, dynamic>?;
          if (nutrition != null) {
            dayCalories += (nutrition['calories'] ?? 0) as int;
            final healthScore = (nutrition['healthScore'] ?? 50) as int;
            dayRiskScore += (100 - healthScore);
            scanCount++;
          }
        }

        final avgRiskScore = scanCount > 0 ? dayRiskScore ~/ scanCount : 0;

        caloriesTrend.add(CaloriesTrendPoint(
          date: dateKey,
          calories: dayCalories,
        ));

        riskScoreTrend.add(RiskScoreTrendPoint(
          date: dateKey,
          score: avgRiskScore,
        ));
      });

      final avgHealthScore = totalScans > 0 ? totalHealthScore / totalScans : 0;

      print('Analytics calculated:');
      print('- Total Scans: $totalScans');
      print('- Total Calories: $totalCalories');
      print('- Avg Health Score: $avgHealthScore');

      return MealAnalytics(
        totalScans: totalScans,
        totalCalories: totalCalories,
        avgHealthScore: avgHealthScore.toDouble(),
        mealDistribution: mealDistribution,
        caloriesTrend: caloriesTrend,
        riskScoreTrend: riskScoreTrend,
      );
    } catch (e) {
      print('Error getting meal analytics: $e');
      return MealAnalytics.empty();
    }
  }

  /// Get today's stats - FIXED VERSION
  Future<Map<String, dynamic>> getTodayStats(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      print('📊 [ANALYTICS] Loading today stats for: $userId');
      print('📊 [ANALYTICS] Start of day: $startOfDay');

      final snapshot = await _firestore
          .collection('scans')
          .where('userId', isEqualTo: userId)
          .where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      print('📊 [ANALYTICS] Found ${snapshot.docs.length} scans today');

      int totalCalories = 0;
      int totalRiskScore = 0;
      int validScanCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final nutrition = data['nutritionData'] as Map<String, dynamic>?;

        if (nutrition == null) {
          print('⚠️ [ANALYTICS] Scan ${doc.id} has NO nutritionData - skipping');
          continue;
        }

        // Extract calories safely
        final caloriesRaw = nutrition['calories'];
        final healthScoreRaw = nutrition['healthScore'];

        if (caloriesRaw == null || healthScoreRaw == null) {
          print('⚠️ [ANALYTICS] Scan ${doc.id} missing calories or healthScore');
          continue;
        }

        // Convert to int safely
        final calories = (caloriesRaw is int)
            ? caloriesRaw
            : (caloriesRaw is double)
            ? caloriesRaw.toInt()
            : int.tryParse(caloriesRaw.toString()) ?? 0;

        final healthScore = (healthScoreRaw is int)
            ? healthScoreRaw
            : (healthScoreRaw is double)
            ? healthScoreRaw.toInt()
            : int.tryParse(healthScoreRaw.toString()) ?? 50;

        totalCalories += calories;
        totalRiskScore += (100 - healthScore);
        validScanCount++;

        print('📊 [ANALYTICS] ✅ ${nutrition['foodName']} - ${calories}cal, health: $healthScore');
      }

      final avgRiskScore = validScanCount > 0 ? totalRiskScore ~/ validScanCount : 0;

      print('📊 [ANALYTICS] ========== FINAL ==========');
      print('📊 [ANALYTICS] Valid Scans: $validScanCount');
      print('📊 [ANALYTICS] Total Calories: $totalCalories');
      print('📊 [ANALYTICS] Avg Risk Score: $avgRiskScore');
      print('📊 [ANALYTICS] ============================');

      return {
        'scanCount': validScanCount,
        'totalCalories': totalCalories,
        'avgRiskScore': avgRiskScore,
      };
    } catch (e, stackTrace) {
      print('❌ [ANALYTICS] Error: $e');
      print('❌ [ANALYTICS] Stack: $stackTrace');
      return {
        'scanCount': 0,
        'totalCalories': 0,
        'avgRiskScore': 0,
      };
    }
  }

  /// Generate daily tip based on user's recent meals
  Future<String> generateDailyTip(String userId) async {
    try {
      final analytics = await getMealAnalytics(userId, days: 7);

      if (analytics.totalScans == 0) {
        return 'Start scanning your meals to get personalized insights!';
      }

      if (analytics.avgHealthScore >= 70) {
        return 'Great job! Your meals show strong nutrition scores this week. Keep up the good work!';
      } else if (analytics.avgHealthScore >= 50) {
        return 'You\'re doing well! Try adding more vegetables and lean proteins to support your nutrition score.';
      } else {
        return 'Consider choosing more balanced options. Focus on whole foods, fruits, and vegetables for general nutrition awareness.';
      }
    } catch (e) {
      print('Error generating daily tip: $e');
      return 'Keep scanning meals to track your nutrition journey!';
    }
  }
}