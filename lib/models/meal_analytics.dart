class MealAnalytics {
  final int totalScans;
  final int totalCalories;
  final double avgHealthScore;
  final Map<String, int> mealDistribution;
  final List<CaloriesTrendPoint> caloriesTrend;
  final List<RiskScoreTrendPoint> riskScoreTrend;

  MealAnalytics({
    required this.totalScans,
    required this.totalCalories,
    required this.avgHealthScore,
    required this.mealDistribution,
    required this.caloriesTrend,
    required this.riskScoreTrend,
  });

  factory MealAnalytics.empty() {
    return MealAnalytics(
      totalScans: 0,
      totalCalories: 0,
      avgHealthScore: 0,
      mealDistribution: {},
      caloriesTrend: [],
      riskScoreTrend: [],
    );
  }
}

class CaloriesTrendPoint {
  final String date;
  final int calories;

  CaloriesTrendPoint({
    required this.date,
    required this.calories,
  });
}

class RiskScoreTrendPoint {
  final String date;
  final int score;

  RiskScoreTrendPoint({
    required this.date,
    required this.score,
  });
}