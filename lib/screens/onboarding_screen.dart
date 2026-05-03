import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // User data
  UserGoal? _selectedGoal;
  List<String> _selectedRestrictions = [];
  int? _age;
  Gender? _selectedGender;
  double? _height;
  double? _weight;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentProfile = authProvider.userProfile;

    if (currentProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No user profile found')),
      );
      return;
    }

    // ✅ FIX: Ensure we have a valid UID for Firestore doc path
    final fallbackUid = authProvider.user?.uid ?? '';
    final uidToUse = currentProfile.uid.trim().isNotEmpty
        ? currentProfile.uid.trim()
        : fallbackUid.trim();

    if (uidToUse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No logged-in user UID found. Please sign in again.'),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Calculate BMI if height and weight are provided
      double? bmi;
      if (_height != null && _weight != null && _height! > 0) {
        final heightInMeters = _height! / 100;
        bmi = _weight! / (heightInMeters * heightInMeters);
      }

      // Calculate daily calorie goal based on user data
      double? calorieGoal;
      if (_age != null &&
          _weight != null &&
          _height != null &&
          _selectedGender != null) {
        calorieGoal = _calculateCalorieGoal(
          age: _age!,
          weight: _weight!,
          height: _height!,
          gender: _selectedGender!,
          goal: _selectedGoal,
        );
      }

      // Update profile with all onboarding data
      final updatedProfile = currentProfile.copyWith(
        // ✅ FIX: force uid in case currentProfile.uid was empty
        uid: uidToUse,

        goal: _selectedGoal,
        dietaryRestrictions: _selectedRestrictions,
        age: _age,
        gender: _selectedGender,
        height: _height,
        weight: _weight,
        bmi: bmi,
        dailyCalorieGoal: calorieGoal,
        onboardingCompleted: true,
      );

      print('Saving onboarding data to Firestore...');
      print('UID: ${updatedProfile.uid}'); // ✅ FIX: confirm non-empty
      print('Goal: ${_selectedGoal?.name}');
      print('Restrictions: $_selectedRestrictions');
      print('Age: $_age, Gender: ${_selectedGender?.name}');
      print('Height: $_height, Weight: $_weight');
      print('BMI: $bmi, Calorie Goal: $calorieGoal');

      await authProvider.updateProfile(updatedProfile);

      if (!mounted) return;

      // Close loading
      Navigator.pop(context);

      print('Onboarding complete! Navigating to home...');

      // Navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      print('Error completing onboarding: $e');

      if (!mounted) return;

      // Close loading
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    }
  }

  double _calculateCalorieGoal({
    required int age,
    required double weight,
    required double height,
    required Gender gender,
    UserGoal? goal,
  }) {
    // Mifflin-St Jeor Equation for BMR
    double bmr;
    if (gender == Gender.male) {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // Activity multiplier (assuming moderate activity)
    double tdee = bmr * 1.55;

    // Adjust based on goal
    switch (goal) {
      case UserGoal.loseWeight:
        return tdee - 500; // 500 calorie deficit
      case UserGoal.gainMuscle:
        return tdee + 300; // 300 calorie surplus
      case UserGoal.maintainWeight:
      case UserGoal.healthFocused:
      default:
        return tdee;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentPage + 1) / 4,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildGoalPage(),
                _buildDietaryPage(),
                _buildPersonalInfoPage(),
                _buildBodyMetricsPage(),
              ],
            ),
          ),

          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_currentPage > 0)
                  TextButton(
                    onPressed: _previousPage,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _canProceed() ? _nextPage : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: Text(_currentPage == 3 ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return _selectedGoal != null;
      case 1:
        return true; // Dietary restrictions are optional
      case 2:
        return _age != null && _selectedGender != null;
      case 3:
        return _height != null && _weight != null;
      default:
        return false;
    }
  }

  Widget _buildGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your primary goal?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...UserGoal.values.map((goal) => _buildGoalCard(goal)),
        ],
      ),
    );
  }

  Widget _buildGoalCard(UserGoal goal) {
    final isSelected = _selectedGoal == goal;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppConstants.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: ListTile(
        onTap: () => setState(() => _selectedGoal = goal),
        title: Text(_getGoalText(goal)),
        leading: Icon(
          _getGoalIcon(goal),
          color: isSelected ? AppConstants.primaryColor : Colors.grey,
        ),
        trailing:
        isSelected ? Icon(Icons.check_circle, color: AppConstants.primaryColor) : null,
      ),
    );
  }

  Widget _buildDietaryPage() {
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
      'Paleo',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Any dietary restrictions?',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all that apply (optional)',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: restrictions.map((restriction) {
              final isSelected = _selectedRestrictions.contains(restriction);
              return FilterChip(
                label: Text(restriction),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedRestrictions.add(restriction);
                    } else {
                      _selectedRestrictions.remove(restriction);
                    }
                  });
                },
                selectedColor: AppConstants.primaryColor.withOpacity(0.3),
                checkmarkColor: AppConstants.primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about yourself',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Age',
              hintText: 'Enter your age (e.g., 25)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) {
              setState(() {
                _age = int.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Gender>(
            decoration: const InputDecoration(
              labelText: 'Gender',
              border: OutlineInputBorder(),
            ),
            value: _selectedGender,
            items: Gender.values.map((gender) {
              return DropdownMenuItem(
                value: gender,
                child: Text(_getGenderText(gender)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMetricsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Metrics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Height (cm)',
              hintText: 'e.g., 175',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _height = double.tryParse(value);
              });
            },
          ),
          const SizedBox(height: 16),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              hintText: 'e.g., 70',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {
                _weight = double.tryParse(value);
              });
            },
          ),
        ],
      ),
    );
  }

  String _getGoalText(UserGoal goal) {
    switch (goal) {
      case UserGoal.loseWeight:
        return 'Lose Weight';
      case UserGoal.maintainWeight:
        return 'Maintain Weight';
      case UserGoal.gainMuscle:
        return 'Gain Muscle';
      case UserGoal.healthFocused:
        return 'Stay Healthy';
    }
  }

  IconData _getGoalIcon(UserGoal goal) {
    switch (goal) {
      case UserGoal.loseWeight:
        return Icons.trending_down;
      case UserGoal.maintainWeight:
        return Icons.monitor_weight;
      case UserGoal.gainMuscle:
        return Icons.fitness_center;
      case UserGoal.healthFocused:
        return Icons.favorite;
    }
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
}
