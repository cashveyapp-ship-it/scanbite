import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/food_scan.dart';

class ScanExportService {
  static Future<void> exportScanHistoryCsv({
    required BuildContext context,
    required List<FoodScan> scans,
    String? userIdForFileName,
  }) async {
    try {
      debugPrint('📤 Export requested. scans=${scans.length}');

      if (scans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No scan history to export yet.')),
        );
        return;
      }

      final ordered = [...scans]..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
      final csv = _buildCsv(ordered);

      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final safeUser =
      (userIdForFileName ?? 'user').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');

      final path = '${dir.path}/scan_history_${safeUser}_$timestamp.csv';
      final file = File(path);

      await file.writeAsString(csv, flush: true);

      final exists = await file.exists();
      final size = exists ? await file.length() : 0;

      debugPrint('✅ Export file written: $path exists=$exists size=$size bytes');

      if (!exists || size == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export failed: file not created.')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export ready (${(size / 1024).toStringAsFixed(1)} KB). Choose Email to send.'),
        ),
      );

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/csv', name: file.uri.pathSegments.last)],
        subject: 'ScanBite - Scan History Export',
        text: 'Attached is your ScanBite nutrition history export.',
      );
    } catch (e, st) {
      debugPrint('❌ Export failed: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  static T? _tryRead<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }

  static String _csvCell(Object? value) {
    final text = (value ?? '').toString();
    final needsQuotes =
        text.contains(',') || text.contains('"') || text.contains('\n') || text.contains('\r');
    final escaped = text.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  static String _joinList(dynamic list) {
    try {
      if (list == null) return '';
      if (list is List) return list.map((e) => e.toString()).join('|');
      return list.toString();
    } catch (_) {
      return '';
    }
  }

  static String _buildCsv(List<FoodScan> scans) {
    final header = [
      'scanId',
      'scannedAt',
      'userId',
      'foodName',
      'calories',
      'protein',
      'carbs',
      'fats',
      'fiber',
      'sugar',
      'sodium_mg',
      'healthScore',
      'isDiabeticFriendly',
      'allergens',
      'ingredients',
      'imageUrl',
    ];

    final lines = <String>[header.join(',')];

    for (final scan in scans) {
      final n = scan.nutritionData as dynamic;

      final calories = _tryRead(() => n.calories) ?? _tryRead(() => n.kcal) ?? _tryRead(() => n.energyKcal);
      final protein = _tryRead(() => n.protein);
      final carbs = _tryRead(() => n.carbs) ?? _tryRead(() => n.carbohydrates);
      final fats = _tryRead(() => n.fats) ?? _tryRead(() => n.fat);
      final fiber = _tryRead(() => n.fiber);
      final sugar = _tryRead(() => n.sugar) ?? _tryRead(() => n.sugars);
      final sodium = _tryRead(() => n.sodium);

      final healthScore = _tryRead(() => n.healthScore) ?? _tryRead(() => n.score);

      final isDiabeticFriendly =
          _tryRead(() => n.isDiabeticFriendly) ?? _tryRead(() => n.diabeticFriendly);

      final allergens = _tryRead(() => n.allergens) ?? _tryRead(() => n.allergensList);
      final ingredients = _tryRead(() => n.ingredients) ?? _tryRead(() => n.ingredientsList);

      final row = [
        _csvCell(scan.id),
        _csvCell(scan.scannedAt.toIso8601String()),
        _csvCell(scan.userId),
        _csvCell(scan.nutritionData.foodName),
        _csvCell(calories),
        _csvCell(protein),
        _csvCell(carbs),
        _csvCell(fats),
        _csvCell(fiber),
        _csvCell(sugar),
        _csvCell(sodium),
        _csvCell(healthScore),
        _csvCell(isDiabeticFriendly),
        _csvCell(_joinList(allergens)),
        _csvCell(_joinList(ingredients)),
        _csvCell(scan.imageUrl),
      ];

      lines.add(row.join(','));
    }

    return lines.join('\n');
  }
}
