import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/scan_provider.dart';
import '../services/firebase_service.dart';
import '../models/food_scan.dart';
import '../models/nutrition_data.dart';
import '../utils/constants.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedScanMode = 0;
  MobileScannerController? _barcodeScannerController;
  bool _isSwitchingMode = false;
  bool _isProcessingBarcode = false; // âœ… prevent duplicate detections

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _barcodeScannerController = MobileScannerController();
  }

  Future<void> _initializeCamera() async {
    try {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        return;
      }

      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // âœ… SPEED: medium resolution â€” enough detail for AI, far smaller image
        final controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await controller.initialize();

        if (!mounted) {
          await controller.dispose();
          return;
        }

        await _cameraController?.dispose();

        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _disposeCamera() async {
    try {
      if (_cameraController != null) {
        await _cameraController!.dispose();
      }
    } catch (e) {
      print('Error disposing camera: $e');
    } finally {
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    }
  }

  Future<void> _switchMode(int newMode) async {
    if (_isSwitchingMode) return;
    if (newMode == _selectedScanMode) return;

    _isSwitchingMode = true;

    try {
      final prevMode = _selectedScanMode;
      if (mounted) setState(() => _selectedScanMode = newMode);

      if (prevMode == 0 && newMode != 0) await _disposeCamera();

      if (newMode == 1) {
        try {
          await _barcodeScannerController?.start();
        } catch (e) {
          print('Barcode scanner start error: $e');
        }
      }

      if (prevMode == 1 && newMode != 1) {
        try {
          await _barcodeScannerController?.stop();
        } catch (e) {
          print('Barcode scanner stop error: $e');
        }
      }

      if (newMode == 0) await _initializeCamera();
    } finally {
      _isSwitchingMode = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _barcodeScannerController?.dispose();
    super.dispose();
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CAMERA SCAN
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _captureAndAnalyze() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _showError('Camera not ready');
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();
      if (!mounted) return;
      await _analyzeAndShowResult(image.path, isCamera: true);
    } catch (e) {
      print('Error capturing image: $e');
      if (mounted) _showError('Error capturing image');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // GALLERY SCAN
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image == null) return;
      if (!mounted) return;
      await _analyzeAndShowResult(image.path, isCamera: false);
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) _showError('Error picking image');
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // CORE ANALYSIS â€” optimized for speed
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _analyzeAndShowResult(String imagePath,
      {required bool isCamera}) async {
    // Single loading dialog â€” never replaced mid-flow
    _showLoadingDialog('Analyzing food...');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);

      if (authProvider.user == null) throw Exception('User not logged in');

      final userProfile = authProvider.userProfile;
      final userContext = userProfile != null
          ? {
              'age': userProfile.age,
              'goal': userProfile.goal?.name,
              'isDiabetic': userProfile.isDiabetic,
              'allergyList': userProfile.allergyList,
              'dietaryRestrictions': userProfile.dietaryRestrictions,
              'dailyCalorieGoal': userProfile.dailyCalorieGoal,
            }
          : null;

      final imageFile = File(imagePath);

      // âœ… SPEED: run AI analysis and image upload IN PARALLEL.
      // Previously upload ran AFTER AI finished, adding up to 15s.
      // Now both complete simultaneously â€” we only wait for the slower one.
      final results = await Future.wait([
        scanProvider.analyzeFoodImage(imageFile, userContext),
        _firebaseService
            .uploadScanImage(imageFile, authProvider.user!.uid)
            .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            print('âš ï¸ Upload timed out â€” using local path');
            return imagePath;
          },
        ).catchError((e) {
          print('âš ï¸ Upload failed â€” using local path: $e');
          return imagePath;
        }),
      ]);

      if (!mounted) return;

      final aiResult = results[0] as Map<String, dynamic>;
      final imageUrl = results[1] as String;

      final scan = _createScanFromResult(
        aiResult,
        imageUrl,
        authProvider.user!.uid,
      );

      // Consume scan (non-blocking â€” errors are swallowed in provider)
      authProvider.consumeOneScanIfNeeded().catchError((e) {
        print('âš ï¸ consumeOneScanIfNeeded: $e');
      });

      // Save in background â€” no reload after save
      _saveInBackground(scan, scanProvider);

      if (!mounted) return;

      // âœ… Single pop â€” straight to results, no intermediate dialog
      Navigator.pop(context);

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultScreen(scan: scan)),
      );
    } catch (e) {
      print('âŒ Analysis error: $e');
      if (mounted) {
        Navigator.pop(context);
        _showError('Analysis failed. Please try again.');
      }
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // BARCODE SCAN
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _handleBarcodeDetection(String barcode) async {
    if (_isProcessingBarcode) return; // âœ… ignore duplicates while processing
    _isProcessingBarcode = true;

    _barcodeScannerController?.stop();
    if (!mounted) return;

    _showLoadingDialog('Looking up product...');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final scanProvider = Provider.of<ScanProvider>(context, listen: false);

      if (authProvider.user == null) throw Exception('User not logged in');

      final result = await scanProvider.analyzeBarcode(barcode);

      if (!mounted) return;

      final imageUrl = result['imageUrl'] ?? '';

      final scan = _createScanFromResult(
        result,
        imageUrl,
        authProvider.user!.uid,
      );

      _saveInBackground(scan, scanProvider);

      if (!mounted) return;

      Navigator.pop(context);

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ResultScreen(scan: scan)),
      );
    } catch (e) {
      print('âŒ Barcode error: $e');
      if (mounted) {
        Navigator.pop(context);
        final msg = e.toString();
        if (msg.contains('qr_code')) {
          _showError(
              'That looks like a QR code, not a product barcode.\n\nPoint the scanner at the barcode on the product packaging (the striped lines with numbers underneath).');
        } else if (msg.contains('not_found')) {
          _showError(
              'Product not found in our database.\n\nTry the Camera tab to let AI identify it from a photo instead.');
        } else {
          _showError('Barcode scan failed. Please try again.');
        }
      }
    } finally {
      _isProcessingBarcode = false; // âœ… allow next scan
    }
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // HELPERS
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  FoodScan _createScanFromResult(
    Map<String, dynamic> result,
    String imageUrl,
    String userId,
  ) {
    final nutritionData = NutritionData(
      foodName: result['foodName'] ?? 'Unknown Food',
      calories: result['calories'] ?? 0,
      protein: (result['protein'] ?? 0).toDouble(),
      carbs: (result['carbs'] ?? 0).toDouble(),
      fats: (result['fats'] ?? 0).toDouble(),
      fiber: (result['fiber'] ?? 0).toDouble(),
      sugar: (result['sugar'] ?? 0).toDouble(),
      sodium: (result['sodium'] ?? 0).toDouble(),
      healthScore: result['healthScore'] ?? 50,
      allergens: List<String>.from(result['allergens'] ?? []),
      isDiabeticFriendly: result['isDiabeticFriendly'] ?? true,
      ingredients: List<String>.from(result['ingredients'] ?? []),
      healthBenefits: List<String>.from(result['healthBenefits'] ?? []),
      healthRisks: List<String>.from(result['healthRisks'] ?? []),
      mealType: result['mealType'] ?? 'snack',
      servingSize: result['servingSize'] ?? 'Medium',
      aiInsights: result['aiInsights'] ?? 'No insights available',
    );

    return FoodScan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      imageUrl: imageUrl,
      nutritionData: nutritionData,
      scannedAt: DateTime.now(),
    );
  }

  void _saveInBackground(FoodScan scan, ScanProvider scanProvider) {
    // âœ… No loadUserScans after save â€” real-time stream handles the update
    _firebaseService.saveScan(scan).then((_) {
      print('âœ… Scan saved to cloud');
    }).catchError((e) {
      print('âš ï¸ Save failed (will sync later): $e');
    });
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(message, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // UI
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Food'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildModeButton(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    isSelected: _selectedScanMode == 0,
                    onTap: () => _switchMode(0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeButton(
                    icon: Icons.qr_code_scanner,
                    label: 'Barcode',
                    isSelected: _selectedScanMode == 1,
                    onTap: () => _switchMode(1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildModeButton(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    isSelected: _selectedScanMode == 2,
                    onTap: () => _switchMode(2),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _selectedScanMode == 0
                ? _buildCameraView()
                : _selectedScanMode == 1
                    ? _buildBarcodeView()
                    : _buildGalleryView(),
          ),
          if (_selectedScanMode == 0)
            Container(
              padding: const EdgeInsets.all(64.0),
              color: Colors.black,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndAnalyze,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppConstants.primaryColor, width: 4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildBarcodeView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _barcodeScannerController,
          onDetect: (capture) {
            final barcodes = capture.barcodes;
            if (barcodes.isNotEmpty) {
              final barcode = barcodes.first.rawValue;
              if (barcode != null && barcode.isNotEmpty) {
                _handleBarcodeDetection(barcode);
              }
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: AppConstants.primaryColor, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const Positioned(
          bottom: 80,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'Position barcode in frame',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryView() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 100, color: Colors.grey.shade700),
            const SizedBox(height: 24),
            const Text(
              'Select Image from Gallery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Choose Image'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
