import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import 'settings_screen.dart';
import 'analytics_screen.dart';
import 'insights_screen.dart';
import 'history_screen.dart';
import 'auth/login_screen.dart';
import '../models/user_profile.dart';
import '../providers/scan_provider.dart';
import '../services/scan_export_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  int _todayRiskScore = 0;
  int _todayCalories = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user != null) {
      setState(() => _isLoading = true);
      await _loadTodayStats(authProvider.user!.uid);
    }
  }

  Future<void> _loadTodayStats(String userId) async {
    try {
      print('📊 Loading today stats for user: $userId');

      final stats = await _analyticsService.getTodayStats(userId);

      print('📊 Stats returned: $stats');

      if (mounted) {
        setState(() {
          _todayCalories = (stats['totalCalories'] as num).toInt();
          _todayRiskScore = (stats['avgRiskScore'] as num).toInt();
          _isLoading = false;
        });

        print('✅ Stats set - Calories: $_todayCalories, Risk: $_todayRiskScore');
      }
    } catch (e, stackTrace) {
      print('❌ Error loading stats: $e');
      print('❌ Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _todayCalories = 0;
          _todayRiskScore = 0;
          _isLoading = false;
        });
      }
    }
  }

  // ✅ BMI CALCULATION METHOD
  double? _calculateBMI(double? height, double? weight) {
    if (height == null || weight == null || height <= 0 || weight <= 0) {
      return null;
    }
    // BMI = weight (kg) / (height (m))^2
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  String _getInitial(String? name) {
    if (name == null || name.isEmpty) return 'U';
    return name.substring(0, 1).toUpperCase();
  }

  String _getPersonalInfoText(dynamic profile) {
    List<String> info = [];
    if (profile.age != null) info.add('${profile.age}y');
    if (profile.gender != null) info.add(_getGenderText(profile.gender!));
    if (profile.height != null) info.add('${profile.height!.toInt()}cm');
    if (profile.weight != null) info.add('${profile.weight!.toInt()}kg');
    return info.isEmpty ? 'Tap to add info' : info.join(' • ');
  }

  String _getGenderText(Gender gender) {
    switch (gender) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
      case Gender.preferNotToSay:
        return 'Prefer not to say';
    }
  }

  String _getGoalText(UserGoal? goal) {
    switch (goal) {
      case UserGoal.loseWeight:
        return 'Nutrition Goal';
      case UserGoal.maintainWeight:
        return 'Maintain Weight';
      case UserGoal.gainMuscle:
        return 'Gain Muscle';
      case UserGoal.healthFocused:
        return 'Balanced Nutrition';
      default:
        return 'Set your goal';
    }
  }

  Color _getRiskColor(int score) {
    if (score < 30) return AppConstants.successColor;
    if (score < 60) return AppConstants.warningColor;
    return AppConstants.dangerColor;
  }

  String _getRiskLabel(int score) {
    if (score < 30) return 'Balanced';
    if (score < 60) return 'Moderate';
    return 'High';
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) return 'Lower Range';
    if (bmi < 25) return 'Balanced';
    if (bmi < 30) return 'Above Average';
    return 'Higher Range';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Nutrition'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Export scan history',
            icon: const Icon(Icons.download_rounded),
            onPressed: () async {
              final authProvider = context.read<AuthProvider>();
              final scanProvider = context.read<ScanProvider>();

              await ScanExportService.exportScanHistoryCsv(
                context: context,
                scans: scanProvider.scans,
                userIdForFileName: authProvider.user?.uid,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),

        body: userProfile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Profile Header
              _buildProfileHeader(userProfile),
              const SizedBox(height: 24),

              // Today's Dashboard - ✅ FIXED TO ALWAYS SHOW BMI
              _buildTodayDashboard(userProfile),
              const SizedBox(height: 16),

              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 16),

              // Personal Settings
              _buildPersonalSettings(userProfile),
              const SizedBox(height: 16),

              // Health Settings
              _buildHealthSettings(userProfile),
              const SizedBox(height: 32),

              // Account Management Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Account Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Icon(
                          Icons.lock_reset,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your password'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showChangePasswordDialog(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: const Text('Delete Account'),
                      subtitle: const Text('Permanently delete your account'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _showDeleteAccountDialog(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Logout Button
              CustomButton(
                text: 'Logout',
                onPressed: () async {
                  await authProvider.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                },
                backgroundColor: Colors.red,
                icon: Icons.logout,
              ),

              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: const [
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

              const SizedBox(height: 80),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(dynamic profile) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: Text(
                _getInitial(profile.displayName),
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              profile.displayName ?? 'User',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.all_inclusive, color: AppConstants.primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Unlimited Scans',
                    style: TextStyle(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIXED: BMI CARD NOW ALWAYS APPEARS (shows "Set Info" if no height/weight)
  Widget _buildTodayDashboard(dynamic profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                    );
                  },
                  icon: const Icon(Icons.analytics, size: 16),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Calories',
                    '$_todayCalories',
                    '${profile.dailyCalorieGoal?.toInt() ?? "---"} goal',
                    Icons.local_fire_department,
                    AppConstants.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Nutrition Balance',
                    '$_todayRiskScore',
                    _getRiskLabel(_todayRiskScore),
                    Icons.health_and_safety,
                    _getRiskColor(_todayRiskScore),
                  ),
                ),
              ],
            ),
            // ✅ BMI ROW - ALWAYS SHOWS (prompts user if data missing)
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: profile.bmi != null
                      ? _buildStatCard(
                    'Body Metrics',
                    profile.bmi!.toStringAsFixed(1),
                    _getBMICategory(profile.bmi!),
                    Icons.monitor_weight,
                    AppConstants.primaryColor,
                  )
                      : _buildStatCard(
                    'Body Metrics',
                    '---',
                    'Set Info',
                    Icons.monitor_weight,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Goal',
                    _getGoalText(profile.goal),
                    '${profile.weight?.toInt() ?? "?"} kg',
                    Icons.flag,
                    AppConstants.secondaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Insights',
                    Icons.lightbulb,
                    AppConstants.accentColor,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InsightsScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'History',
                    Icons.history,
                    AppConstants.primaryColor,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HistoryScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    'Analytics',
                    Icons.bar_chart,
                    AppConstants.secondaryColor,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalSettings(dynamic profile) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Personal Settings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            title: const Text('Personal Info'),
            subtitle: Text(_getPersonalInfoText(profile)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showPersonalInfoDialog(profile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              child: Icon(Icons.track_changes, color: Colors.white, size: 20),
            ),
            title: const Text('My Goal'),
            subtitle: Text(_getGoalText(profile.goal)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showGoalDialog(profile),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthSettings(dynamic profile) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Nutrition Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              child: Icon(Icons.health_and_safety, color: Colors.white, size: 20),
            ),
            title: const Text('Sugar & Carb Estimates'),
            subtitle: const Text(
              'Displays estimated sugar and carbohydrate values from public nutrition databases.',
            ),
            value: profile.isDiabetic,
            activeColor: AppConstants.primaryColor,
            onChanged: (value) {
              authProvider.updateProfile(profile.copyWith(isDiabetic: value));
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              child: Icon(Icons.warning, color: Colors.white, size: 20),
            ),
            title: const Text('Ingredient Alerts'),
            subtitle: Text('${profile.allergyList.length} ingredient preference saved'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showAllergenDialog(profile),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: AppConstants.primaryColor,
              child: Icon(Icons.restaurant, color: Colors.white, size: 20),
            ),
            title: const Text('Food Preferences'),
            subtitle: Text('${profile.dietaryRestrictions.length} preference selected'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showDietaryDialog(profile),
          ),
        ],
      ),
    );
  }

  // ✅ FIXED: Prevents multiple saves, handles errors, forces UI refresh
  void _showPersonalInfoDialog(dynamic profile) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ageController = TextEditingController(text: profile.age?.toString() ?? '');
    final heightController = TextEditingController(text: profile.height?.toString() ?? '');
    final weightController = TextEditingController(text: profile.weight?.toString() ?? '');
    Gender? selectedGender = profile.gender;
    bool isSaving = false; // ✅ NEW: Track save state

    showDialog(
      context: context,
      barrierDismissible: false, // ✅ NEW: Prevent dismiss during save
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return WillPopScope(
              onWillPop: () async => !isSaving, // ✅ NEW: Prevent back during save
              child: AlertDialog(
                title: const Text('Personal Information'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        enabled: !isSaving, // ✅ NEW: Disable during save
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          hintText: 'e.g., 25',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Gender>(
                        value: selectedGender,
                        decoration: const InputDecoration(labelText: 'Gender'),
                        items: Gender.values
                            .map((g) => DropdownMenuItem(
                            value: g, child: Text(_getGenderText(g))))
                            .toList(),
                        onChanged: isSaving
                            ? null // ✅ NEW: Disable during save
                            : (v) => setDialogState(() => selectedGender = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        enabled: !isSaving, // ✅ NEW: Disable during save
                        decoration: const InputDecoration(
                          labelText: 'Height (cm)',
                          hintText: 'e.g., 175',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        enabled: !isSaving, // ✅ NEW: Disable during save
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          hintText: 'e.g., 70',
                        ),
                      ),
                      if (isSaving) // ✅ NEW: Show saving indicator
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Saving...'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null // ✅ NEW: Disable button during save
                        : () async {
                      // ✅ NEW: Prevent double-tap
                      if (isSaving) return;

                      setDialogState(() => isSaving = true);

                      try {
                        final age = int.tryParse(ageController.text);
                        final height = double.tryParse(heightController.text);
                        final weight = double.tryParse(weightController.text);
                        final bmi = _calculateBMI(height, weight);

                        print('💾 Saving personal info:');
                        print('   Age: $age, Gender: $selectedGender');
                        print('   Height: $height, Weight: $weight, BMI: $bmi');

                        // ✅ NEW: Add timeout to catch Firestore hangs
                        await authProvider.updateProfile(
                          profile.copyWith(
                            age: age,
                            gender: selectedGender,
                            height: height,
                            weight: weight,
                            bmi: bmi,
                          ),
                        ).timeout(
                          const Duration(seconds: 10),
                          onTimeout: () {
                            throw Exception('Save timed out - check internet');
                          },
                        );

                        print('✅ Profile update completed');

                        // ✅ NEW: Force reload from Firebase
                        await authProvider.loadUserProfile();

                        if (!mounted) return;

                        // ✅ Close dialog BEFORE showing snackbar
                        Navigator.of(dialogContext).pop();

                        // ✅ Force UI refresh
                        setState(() {});

                        // ✅ Show success
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Saved successfully!'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      } catch (e) {
                        print('❌ Save failed: $e');

                        // ✅ Re-enable button on error
                        setDialogState(() => isSaving = false);

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    },
                    child: isSaving
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  void _showGoalDialog(dynamic profile) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    UserGoal? selectedGoal = profile.goal;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Select Your Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: UserGoal.values.map((goal) {
                  return RadioListTile<UserGoal>(
                    title: Text(_getGoalText(goal)),
                    value: goal,
                    groupValue: selectedGoal,
                    onChanged: (v) => setDialogState(() => selectedGoal = v),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedGoal != null) {
                      await authProvider.updateProfile(
                        profile.copyWith(goal: selectedGoal),
                      );

                      // 🔑 Reload profile from Firestore to guarantee persistence
                      await authProvider.loadUserProfile();
                    }

                    if (!context.mounted) return;
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),

              ],
            );
          },
        );
      },
    );
  }

  void _showAllergenDialog(dynamic profile) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final allergens = [
      'Peanuts',
      'Tree Nuts',
      'Dairy',
      'Eggs',
      'Soy',
      'Wheat/Gluten',
      'Fish',
      'Shellfish'
    ];
    final selected = List<String>.from(profile.allergyList);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Select Allergens'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: allergens.map((a) {
                    return CheckboxListTile(
                      title: Text(a),
                      value: selected.contains(a),
                      onChanged: (v) =>
                          setDialogState(() => v! ? selected.add(a) : selected.remove(a)),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    authProvider.updateProfile(profile.copyWith(allergyList: selected));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDietaryDialog(dynamic profile) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final restrictions = [
      'Vegetarian',
      'Vegan',
      'Gluten-Free',
      'Dairy-Free',
      'Nut-Free',
      'Kosher',
      'Halal',
      'Low-Carb',
      'Keto',
      'Paleo'
    ];
    final selected = List<String>.from(profile.dietaryRestrictions);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Food Preferences'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: restrictions.map((r) {
                    return CheckboxListTile(
                      title: Text(r),
                      value: selected.contains(r),
                      onChanged: (v) =>
                          setDialogState(() => v! ? selected.add(r) : selected.remove(r)),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    authProvider.updateProfile(
                        profile.copyWith(dietaryRestrictions: selected));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: obscureCurrent,
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                              obscureCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () =>
                              setDialogState(() => obscureCurrent = !obscureCurrent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon:
                          Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setDialogState(() => obscureConfirm = !obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final current = currentPasswordController.text.trim();
                    final newPass = newPasswordController.text.trim();
                    final confirm = confirmPasswordController.text.trim();

                    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (newPass.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password must be at least 6 characters'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (newPass != confirm) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Passwords do not match'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.changePassword(current, newPass);

                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password changed successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (_, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Account'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This action cannot be undone. All your data will be permanently deleted.',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Enter your password to confirm:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setDialogState(() => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final password = passwordController.text.trim();

                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your password'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    try {
                      final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.deleteAccount(password);

                      if (!mounted) return;
                      Navigator.of(dialogContext).pop();

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                            (route) => false,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account deleted successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Delete Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}