import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../models/food_scan.dart';
import '../utils/constants.dart';
import '../services/firebase_service.dart'; // ✅ ADD THIS
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _isLoading = true;
  String? _error;

  final FirebaseService _firebaseService = FirebaseService(); // ✅ reuse one instance

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScans();
    });
  }

  Future<void> _loadScans() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);

    if (authProvider.user != null) {
      print('📥 [HISTORY] Loading scans for user: ${authProvider.user!.uid}');

      setState(() {
        _error = null;
      });

      scanProvider.loadUserScans(authProvider.user!.uid);

      // Wait briefly for stream to connect, then stop loading
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Not logged in';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanProvider = Provider.of<ScanProvider>(context);
    final scans = scanProvider.scans;

    print('🖼️ [HISTORY UI] Building with ${scans.length} scans, loading: $_isLoading');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan History'),
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: Colors.black,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black,
                  size: 22,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadScans,
          ),
        ],
      ),
      body: scans.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadScans,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : scans.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No scans yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start scanning food to see your history',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async => _loadScans(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: scans.length + 1,
          itemBuilder: (context, index) {
            if (index == scans.length) {
              return const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 100),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Text(
                          'Nutrition estimates sourced from USDA FoodData Central and public nutrition databases.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Informational only — not medical advice.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            print(
              '🖼️ [HISTORY UI] Building card $index: ${scans[index].nutritionData.foodName}',
            );

            return _buildScanCard(scans[index], scanProvider);
          },
        ),
      ),
    );
  }
  Widget _buildScanCard(FoodScan scan, ScanProvider scanProvider) {
    final nutritionData = scan.nutritionData;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ResultScreen(scan: scan)),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // ✅ FIXED: Always resolve image URL (gs:// or scans/... or https://)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Builder(
                  builder: (context) {
                    final raw = (scan.imageUrl).trim();

                    // ✅ If Firestore stored a local file path, show it directly
                    if (raw.startsWith('/data/') || raw.startsWith('file://')) {
                      final filePath = raw.startsWith('file://') ? raw.replaceFirst('file://', '') : raw;
                      return Image.file(
                        File(filePath),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) {
                          print('❌ [HISTORY] Local image load error: $error path=$filePath');
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.restaurant, size: 40),
                          );
                        },
                      );
                    }

                    // ✅ Otherwise resolve cloud URLs
                    return FutureBuilder<String>(
                      future: _firebaseService.resolveImageUrl(raw),
                      builder: (context, snapshot) {
                        final resolvedUrl = (snapshot.data ?? '').trim();

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey.shade200,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }

                        if (resolvedUrl.isNotEmpty) {
                          return CachedNetworkImage(
                            imageUrl: resolvedUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey.shade200,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (context, url, error) {
                              print('❌ [HISTORY] Image load error: $error for url=$url');
                              return Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.restaurant, size: 40),
                              );
                            },
                          );
                        }

                        return Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.restaurant, size: 40, color: Colors.grey),
                        );
                      },
                    );
                  },
                ),
              ),


              const SizedBox(width: 16),

              // Food Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nutritionData.foodName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(scan.scannedAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.local_fire_department,
                          '${nutritionData.calories} cal',
                          AppConstants.accentColor,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.favorite,
                          nutritionData.healthScore.toString(),
                          _getHealthColor(nutritionData.healthScore),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Delete Button
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _confirmDelete(scan, scanProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FoodScan scan, ScanProvider scanProvider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Scan'),
        content: const Text('Are you sure you want to delete this scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await scanProvider.deleteScan(scan.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan deleted'),
              backgroundColor: AppConstants.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delete failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Color _getHealthColor(int score) {
    if (score >= 70) return AppConstants.successColor;
    if (score >= 40) return AppConstants.warningColor;
    return AppConstants.dangerColor;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}







