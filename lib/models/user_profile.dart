import 'package:cloud_firestore/cloud_firestore.dart';

enum UserGoal { loseWeight, maintainWeight, gainMuscle, healthFocused }
enum Gender { male, female, other, preferNotToSay }

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final bool onboardingCompleted;
  final UserGoal? goal;
  final List<String> dietaryRestrictions;
  final List<String> allergyList;
  final int? age;
  final Gender? gender;
  final double? height;
  final double? weight;
  final double? bmi;
  final double? dailyCalorieGoal;
  final String language;
  final bool isDiabetic;

  final bool isPremium;
  final int freeScansRemaining;
  final int scanCredits;
  final DateTime? subscriptionExpiryDate;

  final bool isFamilyPlanOwner;
  final String? familyCode;
  final String? familyPlanOwnerId;
  final List<String> familyMemberIds;
  final int totalFamilyMembers;

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    required this.onboardingCompleted,
    this.goal,
    this.dietaryRestrictions = const [],
    this.allergyList = const [],
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.bmi,
    this.dailyCalorieGoal,
    this.language = 'en',
    this.isDiabetic = false,
    this.isPremium = false,
    this.freeScansRemaining = 5,
    this.scanCredits = 0,
    this.subscriptionExpiryDate,
    this.isFamilyPlanOwner = false,
    this.familyCode,
    this.familyPlanOwnerId,
    this.familyMemberIds = const [],
    this.totalFamilyMembers = 1,
  });

  bool get isSubscriptionActive {
    if (!isPremium) return false;
    if (subscriptionExpiryDate == null) return false;
    return subscriptionExpiryDate!.isAfter(DateTime.now());
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? onboardingCompleted,
    UserGoal? goal,
    List<String>? dietaryRestrictions,
    List<String>? allergyList,
    int? age,
    Gender? gender,
    double? height,
    double? weight,
    double? bmi,
    double? dailyCalorieGoal,
    String? language,
    bool? isDiabetic,
    bool? isPremium,
    int? freeScansRemaining,
    int? scanCredits,
    DateTime? subscriptionExpiryDate,
    bool? isFamilyPlanOwner,
    String? familyCode,
    String? familyPlanOwnerId,
    List<String>? familyMemberIds,
    int? totalFamilyMembers,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      goal: goal ?? this.goal,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergyList: allergyList ?? this.allergyList,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      bmi: bmi ?? this.bmi,
      dailyCalorieGoal: dailyCalorieGoal ?? this.dailyCalorieGoal,
      language: language ?? this.language,
      isDiabetic: isDiabetic ?? this.isDiabetic,
      isPremium: isPremium ?? this.isPremium,
      freeScansRemaining: freeScansRemaining ?? this.freeScansRemaining,
      scanCredits: scanCredits ?? this.scanCredits,
      subscriptionExpiryDate:
      subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      isFamilyPlanOwner: isFamilyPlanOwner ?? this.isFamilyPlanOwner,
      familyCode: familyCode ?? this.familyCode,
      familyPlanOwnerId: familyPlanOwnerId ?? this.familyPlanOwnerId,
      familyMemberIds: familyMemberIds ?? this.familyMemberIds,
      totalFamilyMembers: totalFamilyMembers ?? this.totalFamilyMembers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'goal': goal?.name,
      'dietaryRestrictions': dietaryRestrictions,
      'allergyList': allergyList,
      'age': age,
      'gender': gender?.name,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'dailyCalorieGoal': dailyCalorieGoal,
      'language': language,
      'isDiabetic': isDiabetic,
      'isPremium': isPremium,
      'isSubscriptionActive': isSubscriptionActive,
      'freeScansRemaining': freeScansRemaining,
      'scanCredits': scanCredits,
      'subscriptionExpiryDate': subscriptionExpiryDate != null
          ? Timestamp.fromDate(subscriptionExpiryDate!)
          : null,
      'isFamilyPlanOwner': isFamilyPlanOwner,
      'familyCode': familyCode,
      'onboardingCompleted': onboardingCompleted,
      'familyPlanOwnerId': familyPlanOwnerId,
      'familyMemberIds': familyMemberIds,
      'totalFamilyMembers': totalFamilyMembers,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: (map['uid'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      displayName: (map['displayName'] ?? 'User') as String,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      onboardingCompleted: map['onboardingCompleted'] == true,
      goal: map['goal'] != null ? _parseGoal(map['goal']) : null,
      dietaryRestrictions: _parseStringList(map['dietaryRestrictions']),
      allergyList: _parseStringList(map['allergyList']),
      age: _asInt(map['age']),
      gender: map['gender'] != null ? _parseGender(map['gender']) : null,
      height: _asDouble(map['height']),
      weight: _asDouble(map['weight']),
      bmi: _asDouble(map['bmi']),
      dailyCalorieGoal: _asDouble(map['dailyCalorieGoal']),
      language: (map['language'] ?? 'en') as String,
      isDiabetic: map['isDiabetic'] == true,
      isPremium: map['isPremium'] == true,
      freeScansRemaining: _asInt(map['freeScansRemaining']) ?? 5,
      scanCredits: _asInt(map['scanCredits']) ?? 0,
      subscriptionExpiryDate:
      (map['subscriptionExpiryDate'] as Timestamp?)?.toDate(),
      isFamilyPlanOwner: map['isFamilyPlanOwner'] == true,
      familyCode: map['familyCode'] as String?,
      familyPlanOwnerId: map['familyPlanOwnerId'] as String?,
      familyMemberIds: List<String>.from(map['familyMemberIds'] ?? const []),
      totalFamilyMembers: _asInt(map['totalFamilyMembers']) ?? 1,
    );
  }

  Map<String, dynamic> toUpdateMap() {
    final map = <String, dynamic>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': Timestamp.fromDate(createdAt),
      'language': language,
      'isDiabetic': isDiabetic,
      'dietaryRestrictions': dietaryRestrictions,
      'allergyList': allergyList,
      'isPremium': isPremium,
      'freeScansRemaining': freeScansRemaining,
      'scanCredits': scanCredits,
      'onboardingCompleted': onboardingCompleted,
      'isFamilyPlanOwner': isFamilyPlanOwner,
      'familyCode': familyCode,
      'familyPlanOwnerId': familyPlanOwnerId,
      'familyMemberIds': familyMemberIds,
      'totalFamilyMembers': totalFamilyMembers,
    };

    if (goal != null) map['goal'] = goal!.name;
    if (age != null) map['age'] = age;
    if (gender != null) map['gender'] = gender!.name;
    if (height != null) map['height'] = height;
    if (weight != null) map['weight'] = weight;
    if (bmi != null) map['bmi'] = bmi;
    if (dailyCalorieGoal != null) map['dailyCalorieGoal'] = dailyCalorieGoal;
    if (subscriptionExpiryDate != null) {
      map['subscriptionExpiryDate'] = Timestamp.fromDate(subscriptionExpiryDate!);
    }

    return map;
  }

  Map<String, dynamic> toCacheMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'onboardingCompleted': onboardingCompleted,
      'goal': goal?.name,
      'dietaryRestrictions': dietaryRestrictions,
      'allergyList': allergyList,
      'age': age,
      'gender': gender?.name,
      'height': height,
      'weight': weight,
      'bmi': bmi,
      'dailyCalorieGoal': dailyCalorieGoal,
      'language': language,
      'isDiabetic': isDiabetic,
      'isPremium': isPremium,
      'freeScansRemaining': freeScansRemaining,
      'scanCredits': scanCredits,
      'subscriptionExpiryDate': subscriptionExpiryDate?.toIso8601String(),
      'isFamilyPlanOwner': isFamilyPlanOwner,
      'familyCode': familyCode,
      'familyPlanOwnerId': familyPlanOwnerId,
      'familyMemberIds': familyMemberIds,
      'totalFamilyMembers': totalFamilyMembers,
    };
  }

  factory UserProfile.fromCacheMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: (map['uid'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      displayName: (map['displayName'] ?? 'User') as String,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      onboardingCompleted: map['onboardingCompleted'] == true,
      goal: map['goal'] != null ? _parseGoal(map['goal']) : null,
      dietaryRestrictions: _parseStringList(map['dietaryRestrictions']),
      allergyList: _parseStringList(map['allergyList']),
      age: _asInt(map['age']),
      gender: map['gender'] != null ? _parseGender(map['gender']) : null,
      height: _asDouble(map['height']),
      weight: _asDouble(map['weight']),
      bmi: _asDouble(map['bmi']),
      dailyCalorieGoal: _asDouble(map['dailyCalorieGoal']),
      language: (map['language'] ?? 'en') as String,
      isDiabetic: map['isDiabetic'] == true,
      isPremium: map['isPremium'] == true,
      freeScansRemaining: _asInt(map['freeScansRemaining']) ?? 5,
      scanCredits: _asInt(map['scanCredits']) ?? 0,
      subscriptionExpiryDate: map['subscriptionExpiryDate'] != null
          ? DateTime.tryParse(map['subscriptionExpiryDate'].toString())
          : null,
      isFamilyPlanOwner: map['isFamilyPlanOwner'] == true,
      familyCode: map['familyCode'] as String?,
      familyPlanOwnerId: map['familyPlanOwnerId'] as String?,
      familyMemberIds: List<String>.from(map['familyMemberIds'] ?? const []),
      totalFamilyMembers: _asInt(map['totalFamilyMembers']) ?? 1,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return [];
  }

  static UserGoal? _parseGoal(dynamic value) {
    if (value == null) return null;
    try {
      return UserGoal.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }

  static Gender? _parseGender(dynamic value) {
    if (value == null) return null;
    try {
      return Gender.values.firstWhere((e) => e.name == value);
    } catch (_) {
      return null;
    }
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}