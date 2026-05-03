import 'package:flutter/material.dart';

class AppConstants {
  // App Info
  static const String appName = 'ScanBite';
  static const String appVersion = '1.0.0';
  static const String scanImagesPath = 'scan_images';

  // Colors
  static const Color primaryColor = Color(0xFF2E7D32);
  static const Color secondaryColor = Color(0xFF66BB6A);
  static const Color accentColor = Color(0xFFFF6F00);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color dangerColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);

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