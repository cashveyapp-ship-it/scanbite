import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../services/analytics_service.dart';
import '../models/meal_analytics.dart';
import '../utils/constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  MealAnalytics? _analytics;
  bool _isLoading = true;
  int _selectedDays = 7;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        final analytics = await _analyticsService.getMealAnalytics(
          authProvider.user!.uid,
          days: _selectedDays,
        );

        if (mounted) {
          setState(() {
            _analytics = analytics;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'User not logged in';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            onSelected: (days) {
              setState(() {
                _selectedDays = days;
              });
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _analytics == null || _analytics!.totalScans == 0
          ? _buildEmptyState()
          : _buildAnalyticsContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red.shade300),
            const SizedBox(height: 16),
            const Text(
              'Unable to load analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Please try again later',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAnalytics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start scanning meals to see your analytics dashboard with beautiful charts and insights!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, size: 48, color: AppConstants.primaryColor),
                  const SizedBox(height: 12),
                  const Text(
                    'Your analytics will include:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildFeatureItem('📊 Calorie trends over time'),
                  _buildFeatureItem('🎯 Nutrition awareness scoring'),
                  _buildFeatureItem('🥗 Meal distribution charts'),
                  _buildFeatureItem('💪 Nutrition breakdown'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    return RefreshIndicator(
      onRefresh: _loadAnalytics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Showing last $_selectedDays days',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildCaloriesTrendChart(),
            const SizedBox(height: 24),
            _buildRiskScoreTrendChart(),
            const SizedBox(height: 24),
            _buildMealDistributionChart(),
            const SizedBox(height: 24),
            _buildNutritionBreakdown(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            'Total Scans',
            '${_analytics!.totalScans}',
            Icons.scanner,
            AppConstants.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Total Calories',
            '${_analytics!.totalCalories}',
            Icons.local_fire_department,
            AppConstants.accentColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            'Avg Nutrition',
            '${_analytics!.avgHealthScore.toInt()}',
            Icons.favorite,
            AppConstants.successColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaloriesTrendChart() {
    if (_analytics!.caloriesTrend.isEmpty) {
      return _buildEmptyChart('No calorie data', 'Scan meals to see trends');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, color: AppConstants.primaryColor),
                const SizedBox(width: 8),
                const Text('Calories Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _analytics!.caloriesTrend.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.calories.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppConstants.primaryColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppConstants.primaryColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskScoreTrendChart() {
    if (_analytics!.riskScoreTrend.isEmpty) {
      return _buildEmptyChart('No nutrition score data', 'Scan meals to view nutrition score trends');
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppConstants.dangerColor),
                const SizedBox(width: 8),
                const Text('Nutrition Score Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _analytics!.riskScoreTrend.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value.score.toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppConstants.dangerColor,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppConstants.dangerColor.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealDistributionChart() {
    if (_analytics!.mealDistribution.isEmpty) {
      return _buildEmptyChart('No meal data', 'Distribution will appear after scans');
    }

    final colors = {
      'breakfast': Colors.orange,
      'lunch': Colors.blue,
      'dinner': Colors.green,
      'snack': Colors.purple,
    };

    final total = _analytics!.mealDistribution.values.fold(0, (sum, count) => sum + count);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: AppConstants.accentColor),
                const SizedBox(width: 8),
                const Text('Meal Distribution', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _analytics!.mealDistribution.entries.map((entry) {
                    final percentage = (entry.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '$percentage%',
                      color: colors[entry.key] ?? Colors.grey,
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _analytics!.mealDistribution.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[entry.key] ?? Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${entry.key[0].toUpperCase()}${entry.key.substring(1)}: ${entry.value}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionBreakdown() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.donut_small, color: AppConstants.secondaryColor),
                const SizedBox(width: 8),
                const Text('Nutrition Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildNutrientBar('Protein', 0.3, AppConstants.successColor),
            _buildNutrientBar('Carbs', 0.5, AppConstants.accentColor),
            _buildNutrientBar('Fats', 0.2, AppConstants.warningColor),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              Text('${(value * 100).toInt()}%', style: TextStyle(fontSize: 14, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey.shade600)),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}


