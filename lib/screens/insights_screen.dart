import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';
import '../models/user_profile.dart';
import '../services/openai_service.dart';
import '../providers/scan_provider.dart';
import '../services/scan_export_service.dart';


class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final OpenAIService _openAIService = OpenAIService();

  bool _loadingTip = true;
  String _dailyTip = '';
  String _dailyTipCategory = 'general';

  @override
  void initState() {
    super.initState();
    _loadDailyTip();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final uid = auth.user?.uid;
      if (uid != null) {
        context.read<ScanProvider>().loadUserScans(uid);
      }
    });
  }

  Future<void> _loadDailyTip() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProfile = authProvider.userProfile;

      final userContext = _buildUserContext(userProfile);

      // If user is null (not loaded yet), show default tip (no crash)
      if (userProfile == null) {
        if (mounted) {
          setState(() {
            _dailyTip =
            'Welcome! Start scanning your meals to receive personalized nutrition insights powered by AI.';
            _dailyTipCategory = 'general';
            _loadingTip = false;
          });
        }
        return;
      }

      final result = await _openAIService.generatePersonalizedDailyTip(
        userContext: userContext,
      );

      if (!mounted) return;
      setState(() {
        _dailyTip = result['tip'] ?? '';
        _dailyTipCategory = result['category'] ?? 'general';
        _loadingTip = false;
      });
    } catch (e) {
      // Even if something breaks here, do NOT crash UI
      if (!mounted) return;
      setState(() {
        _dailyTip =
        'Start scanning your meals to get AI-powered insights tailored to your nutrition goals and dietary preferences!';
        _dailyTipCategory = 'general';
        _loadingTip = false;
      });
    }
  }

  Map<String, dynamic> _buildUserContext(UserProfile? profile) {
    if (profile == null) return {};

    // Convert goal enum to a readable string for the AI
    String? goal;
    if (profile.goal != null) {
      switch (profile.goal!) {
        case UserGoal.loseWeight:
          goal = 'lose_weight';
          break;
        case UserGoal.maintainWeight:
          goal = 'maintain_weight';
          break;
        case UserGoal.gainMuscle:
          goal = 'gain_muscle';
          break;
        case UserGoal.healthFocused:
          goal = 'health_focused';
          break;
      }
    }

    return {
      'age': profile.age,
      'goal': goal,
      'bmi': profile.bmi,
      'isDiabetic': profile.isDiabetic,
      'allergyList': profile.allergyList,
      'dietaryRestrictions': profile.dietaryRestrictions,
      'dailyCalorieGoal': profile.dailyCalorieGoal,
      'language': profile.language,
    };
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Export scan history',
            icon: const Icon(Icons.download_rounded),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final scanProvider = context.read<ScanProvider>();

              final uid = authProvider.user?.uid;
              if (uid == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please sign in to export your scan history.')),
                );
                return;
              }

              if (scanProvider.scans.isEmpty) {
                // Attempt a reload once (safe)
                scanProvider.loadUserScans(uid);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Loading scan history… try export again in a moment.')),
                );
                return;
              }

              await ScanExportService.exportScanHistoryCsv(
                context: context,
                scans: scanProvider.scans,
                userIdForFileName: uid,
              );
            },

          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _loadingTip = true);
              _loadDailyTip();
            },
            tooltip: 'Refresh Tip',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _loadingTip = true);
          await _loadDailyTip();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Daily Tip Card (NOW AI-POWERED WITH FALLBACK)
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppConstants.accentColor, Colors.orange.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb, color: Colors.white, size: 32),
                          SizedBox(width: 12),
                          Text(
                            'Today\'s AI Tip',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Optional small category label
                      if (!_loadingTip && _dailyTipCategory.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _dailyTipCategory.replaceAll('_', ' ').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      if (_loadingTip)
                        const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Generating your personalized tip...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          _dailyTip.isNotEmpty
                              ? _dailyTip
                              : _getFallbackTip(userProfile),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Personalized Recommendations
              const Text(
                'Personalized for You',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              _buildInsightCard(
                'Start Your Journey',
                'Begin scanning your meals to get personalized AI insights based on your eating habits!',
                Icons.qr_code_scanner,
                AppConstants.primaryColor,
              ),

              if (userProfile?.goal == UserGoal.loseWeight)
                _buildInsightCard(
                  'Weight Management Tip',
                  'Focus on high-protein, low-calorie foods. Scan your meals to track your progress!',
                  Icons.trending_down,
                  Colors.blue,
                ),

              if (userProfile?.goal == UserGoal.gainMuscle)
                _buildInsightCard(
                  'Fitness Support ',
                  'Aim for 1.6-2.2g of protein per kg of body weight. Track it with meal scans!',
                  Icons.fitness_center,
                  Colors.purple,
                ),

              _buildInsightCard(
                'Hydration Reminder',
                'Drink at least 8 glasses of water daily to boost metabolism and energy.',
                Icons.water_drop,
                Colors.blue,
              ),

              _buildInsightCard(
                'Meal Timing',
                'Try eating your last meal 3 hours before bed for general wellness and routine awareness.',
                Icons.schedule,
                Colors.purple,
              ),

              _buildInsightCard(
                'Nutrient Balance',
                'Include colorful vegetables in every meal for a wide range of vitamins and minerals.',
                Icons.eco,
                Colors.green,
              ),

              if (userProfile?.isDiabetic == true)
                _buildInsightCard(
                  'Sugar & Carb Information',
                  'Review carbohydrate and sugar content for informational purposes only. Always consult a qualified healthcare professional.',
                  Icons.info_outline,
                  Colors.red,
                ),

              _buildInsightCard(
                'Portion Control',
                'Use smaller plates and scan your portions to maintain awareness of serving sizes.',
                Icons.restaurant,
                Colors.orange,
              ),

              const SizedBox(height: 16),

              Center(
                child: Text(
                  'Educational information only. Not medical advice.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),


              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Extra-safe fallback (UI-only) in case tip string is empty
  String _getFallbackTip(UserProfile? userProfile) {
    if (userProfile == null) {
      return 'Welcome! Start scanning your meals to receive personalized nutrition insights powered by AI.';
    }

    if (userProfile.goal == UserGoal.loseWeight) {
      return 'Focus on creating a calorie deficit by choosing nutrient-dense, low-calorie foods. Scan your meals to track your progress toward your weight loss goal!';
    }

    if (userProfile.goal == UserGoal.gainMuscle) {
      return 'To build muscle effectively, ensure you\'re eating in a calorie surplus with adequate protein. Scan your meals to verify you\'re hitting your daily protein target!';
    }

    if (userProfile.goal == UserGoal.healthFocused) {
      return 'Prioritize whole foods, fruits, vegetables, and lean proteins. Use meal scanning to ensure you\'re getting balanced nutrition every day!';
    }

    return 'Start scanning your meals to get AI-powered insights tailored to your nutrition goals and dietary preferences!';
  }

  Widget _buildInsightCard(
      String title,
      String description,
      IconData icon,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
      ),
    );
  }
}
