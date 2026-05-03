import 'package:cloud_firestore/cloud_firestore.dart';
import 'nutrition_data.dart';

class FoodScan {
  final String id;
  final String userId;
  final String imageUrl;
  final NutritionData nutritionData;
  final DateTime scannedAt;

  FoodScan({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.nutritionData,
    required this.scannedAt,
  });

  // ADD THIS GETTER
  String get foodName => nutritionData.foodName;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'nutritionData': nutritionData.toMap(),
      'scannedAt': Timestamp.fromDate(scannedAt),
    };
  }

  factory FoodScan.fromMap(Map<String, dynamic> map, String id) {
    return FoodScan(
      id: id,
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      nutritionData: NutritionData.fromMap(map['nutritionData'] ?? {}),
      scannedAt: (map['scannedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}