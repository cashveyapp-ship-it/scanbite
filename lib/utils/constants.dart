import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'ScanBite';
  static const String appVersion = '1.0.0';
  static const String scanImagesPath = 'scan_images';

  // Colors - Apple Style Modern UI
  static const Color primaryColor = Color(0xFF34C759);
  static const Color secondaryColor = Color(0xFF30D158);

  static const Color accentColor = Color(0xFF32D74B);

  static const Color successColor = Color(0xFF34C759);
  static const Color dangerColor = Color(0xFFFF453A);
  static const Color warningColor = Color(0xFFFF9F0A);

  // Backgrounds
  static const Color backgroundColor = Color(0xFFF6F7F3);
  static const Color cardColor = Colors.white;
  static const Color surfaceColor = Color(0xFFFFFFFF);

  // Text
  static const Color primaryTextColor = Color(0xFF1C1C1E);
  static const Color secondaryTextColor = Color(0xFF8E8E93);

  // Borders/Shadows
  static const Color borderColor = Color(0xFFE5E5EA);
  static const Color shadowColor = Color(0x14000000);

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String scansCollection = 'scans';
  static const String subscriptionsCollection = 'subscriptions';

  // PRICING
  static const int freeScans = 5;
  static const int freeScansPerMonth = 5;
  static const double perScanPrice = 0.90;
  static const double monthlyPrice = 3.99;
  static const double yearlyPrice = 43.00;

  // FAMILY PLAN PRICING (NEW)
  static const double familyMonthlyPrice = 7.99;
  static const double familyYearlyPrice = 79.99;
  static const int familyMaxMembers = 5;
  static const double familyExtraMemberPrice = 1.00;

  // Calculated savings
  static const double yearlySavings = (monthlyPrice * 12) - yearlyPrice;
  static const String yearlySavingsText = '\$0';
  static const double familyYearlySavings = (familyMonthlyPrice * 12) - familyYearlyPrice; // $16.89

  // Limits
  static const int maxHistoryItems = 100;
  static const int maxImageSizeMB = 5;
}

