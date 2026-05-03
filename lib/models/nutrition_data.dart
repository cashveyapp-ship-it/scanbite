class NutritionData {
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fats;
  final double fiber;
  final double sugar;
  final double sodium;
  final int healthScore;
  final List<String> allergens;
  final bool isDiabeticFriendly;
  final List<String> ingredients;
  final List<String> healthBenefits;
  final List<String> healthRisks;
  final String mealType;
  final String servingSize;
  final String aiInsights;

  NutritionData({
    required this.foodName,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fats,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.healthScore,
    required this.allergens,
    required this.isDiabeticFriendly,
    required this.ingredients,
    required this.healthBenefits,
    required this.healthRisks,
    required this.mealType,
    required this.servingSize,
    required this.aiInsights,
  });

  Map<String, dynamic> toMap() {
    return {
      'foodName': foodName,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'healthScore': healthScore,
      'allergens': allergens,
      'isDiabeticFriendly': isDiabeticFriendly,
      'ingredients': ingredients,
      'healthBenefits': healthBenefits,
      'healthRisks': healthRisks,
      'mealType': mealType,
      'servingSize': servingSize,
      'aiInsights': aiInsights,
    };
  }

  factory NutritionData.fromMap(Map<String, dynamic> map) {
    return NutritionData(
      foodName: map['foodName'] ?? 'Unknown Food',
      calories: map['calories'] ?? 0,
      protein: (map['protein'] ?? 0).toDouble(),
      carbs: (map['carbs'] ?? 0).toDouble(),
      fats: (map['fats'] ?? 0).toDouble(),
      fiber: (map['fiber'] ?? 0).toDouble(),
      sugar: (map['sugar'] ?? 0).toDouble(),
      sodium: (map['sodium'] ?? 0).toDouble(),
      healthScore: map['healthScore'] ?? 50,
      allergens: List<String>.from(map['allergens'] ?? const []),
      isDiabeticFriendly: map['isDiabeticFriendly'] ?? true,
      ingredients: List<String>.from(map['ingredients'] ?? const []),
      healthBenefits: List<String>.from(map['healthBenefits'] ?? const []),
      healthRisks: List<String>.from(map['healthRisks'] ?? const []),
      mealType: map['mealType'] ?? 'snack',
      servingSize: map['servingSize'] ?? 'Medium',
      aiInsights: map['aiInsights'] ?? '',
    );
  }

  double get fat => fats;
  String get analysis => aiInsights;
  String get recommendation => aiInsights;
}
