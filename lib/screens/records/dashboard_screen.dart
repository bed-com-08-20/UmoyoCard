import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:umoyocard/screens/records/analytics_helper.dart'
    as analytics_helper;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

/// A screen that displays health metrics analytics and predictions.
/// 
/// This screen shows visual charts for blood pressure and blood sugar data,
/// along with predictive analysis and health tips based on the user's medical history.
/// Data is cached locally and updated periodically.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// The state class for DashboardScreen.
/// 
/// Manages the loading, caching, and display of health analytics data,
/// including blood pressure and blood sugar metrics.
class _DashboardScreenState extends State<DashboardScreen> {
  String _analyticsResult = '';
  String _errorMessage = '';
  analytics_helper.HealthMetrics? _healthMetrics;
  bool _hasData = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeWithCachedData();
  }

  /// Initializes the screen with cached data from SharedPreferences.
  /// 
  /// Loads previously saved analysis results and health metrics from local storage.
  /// If cached data exists, it will be displayed immediately while fresh data
  /// is fetched in the background.
  Future<void> _initializeWithCachedData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load cached analysis text
    final savedResult = prefs.getString('savedAnalysis');

    // Load cached health metrics
    final savedMetricsJson = prefs.getString('savedHealthMetrics');
    if (savedMetricsJson != null) {
      try {
        final jsonData = jsonDecode(savedMetricsJson);
        _healthMetrics = analytics_helper.HealthMetrics(
          bloodPressureData:
              (jsonData['bloodPressure'] as List? ?? []).map((item) {
            return analytics_helper.BloodPressureData(
              date: DateTime.parse(item['date'].toString()),
              systolic: item['systolic'] is int
                  ? item['systolic']
                  : int.parse(item['systolic'].toString()),
              diastolic: item['diastolic'] is int
                  ? item['diastolic']
                  : int.parse(item['diastolic'].toString()),
            );
          }).toList(),
          bloodSugarData: (jsonData['bloodSugar'] as List? ?? []).map((item) {
            return analytics_helper.BloodSugarData(
              date: DateTime.parse(item['date'].toString()),
              value: item['value'] is double
                  ? item['value']
                  : double.parse(item['value'].toString()),
            );
          }).toList(),
          bloodPressurePrediction: jsonData['bpPrediction']?.toString() ?? '',
          bloodPressureTip: jsonData['bpTip']?.toString() ?? '',
          bloodSugarPrediction: jsonData['sugarPrediction']?.toString() ?? '',
          bloodSugarTip: jsonData['sugarTip']?.toString() ?? '',
        );
      } catch (e) {
        print("Error parsing cached metrics: $e");
      }
    }

    // Check if we have any timeline data
    final hasTimelineData =
        prefs.getStringList('savedTexts')?.isNotEmpty ?? false;

    setState(() {
      _hasData = hasTimelineData;
      _analyticsResult = savedResult ?? '';
    });

    // Check for updates in background without blocking UI
    _checkForUpdates();
  }

  /// Checks for new data updates in the background.
  /// 
  /// Compares the current timeline data hash with the last saved hash to determine
  /// if new data processing is needed. If new data is found, it triggers processNewData.
  Future<void> _checkForUpdates() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentTimeline =
          await analytics_helper.fetchAndFormatTimelineData(prefs);

      if (currentTimeline.startsWith("No medical history data found")) {
        return;
      }

      final currentHash = analytics_helper.calculateHash(currentTimeline);
      final lastHash = prefs.getString('lastTimelineHash');

      if (lastHash != currentHash) {
        // New data available - process in background
        await _processNewData(prefs, currentTimeline, currentHash);
      }
    } catch (e) {
      print("Background update check failed: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Processes new timeline data and updates the cache.
  /// 
  /// Parameters:
  /// - prefs: SharedPreferences instance for local storage
  /// - timelineData: The raw timeline data string to process
  /// - currentHash: The hash of the current timeline data for change detection
  /// 
  /// Extracts health metrics, runs predictive analysis, and updates the UI with results.
  Future<void> _processNewData(
      SharedPreferences prefs, String timelineData, String currentHash) async {
    try {
      // Process new data
      final newMetrics =
          await analytics_helper.extractHealthMetrics(timelineData);
      final analysisResult =
          await analytics_helper.runPredictiveAnalysis(timelineData);

      // Save to cache
      await prefs.setString('savedAnalysis', analysisResult);
      await prefs.setString('lastTimelineHash', currentHash);
      await prefs.setString(
          'savedHealthMetrics',
          jsonEncode({
            'bloodPressure': newMetrics.bloodPressureData
                .map((e) => {
                      'date': e.date.toIso8601String(),
                      'systolic': e.systolic,
                      'diastolic': e.diastolic,
                    })
                .toList(),
            'bloodSugar': newMetrics.bloodSugarData
                .map((e) => {
                      'date': e.date.toIso8601String(),
                      'value': e.value,
                    })
                .toList(),
            'bpPrediction': newMetrics.bloodPressurePrediction,
            'bpTip': newMetrics.bloodPressureTip,
            'sugarPrediction': newMetrics.bloodSugarPrediction,
            'sugarTip': newMetrics.bloodSugarTip,
          }));

      // Update UI if still mounted
      if (mounted) {
        setState(() {
          _healthMetrics = newMetrics;
          _analyticsResult = analysisResult;
          _hasData = true;
        });
      }
    } catch (e) {
      print("Error processing new data: $e");
    }
  }


/// Builds the blood pressure card widget with chart and analysis.
  /// 
  /// Returns:
  /// - A Card widget displaying blood pressure trends over time,
  ///   with systolic and diastolic values plotted on a line chart.
  /// - If no data is available, returns a placeholder card.
  Widget _buildBloodPressureCard() {
    if (!_hasData || _healthMetrics == null) {
      return _buildPlaceholderCard('🩸 Blood Pressure', 'No data available');
    }

    final bpData = _healthMetrics!.bloodPressureData;
    if (bpData.isEmpty) {
      return _buildPlaceholderCard(
          '🩸 Blood Pressure', 'No blood pressure data');
    }

    final maxSystolic = bpData.fold(
        0, (max, item) => item.systolic > max ? item.systolic : max);
    final maxDiastolic = bpData.fold(
        0, (max, item) => item.diastolic > max ? item.diastolic : max);
    final maxY = (maxSystolic > maxDiastolic ? maxSystolic : maxDiastolic) + 20;

    return Card(
      color: Color(0xFFE6F4EA),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🩸 Blood Pressure',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (bpData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxY.toDouble(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < bpData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd')
                                    .format(bpData[value.toInt()].date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: bpData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.systolic.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: bpData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.diastolic.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(width: 12, height: 12, color: Colors.red),
                const SizedBox(width: 4),
                const Text('Systolic'),
                const SizedBox(width: 16),
                Container(width: 12, height: 12, color: Colors.blue),
                const SizedBox(width: 4),
                const Text('Diastolic'),
              ],
            ),
            const SizedBox(height: 12),
            if (_healthMetrics!.bloodPressurePrediction.isNotEmpty) ...[
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Prediction: ',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    TextSpan(
                      text: _healthMetrics!.bloodPressurePrediction,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Tip: ',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    TextSpan(
                      text: _healthMetrics!.bloodPressureTip,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds the blood sugar card widget with chart and analysis.
  /// 
  /// Returns:
  /// - A [Card] widget displaying blood sugar trends over time on a line chart.
  /// - If no data is available, returns a placeholder card.
  Widget _buildBloodSugarCard() {
    if (!_hasData || _healthMetrics == null) {
      return _buildPlaceholderCard('🍬 Blood Sugar', 'No data available');
    }

    final sugarData = _healthMetrics!.bloodSugarData;
    if (sugarData.isEmpty) {
      return _buildPlaceholderCard('🍬 Blood Sugar', 'No blood sugar data');
    }

    final maxValue = sugarData.fold(
            0.0, (max, item) => item.value > max ? item.value : max) +
        20;

    return Card(
      color: Color(0xFFE6F4EA),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🍬 Blood Sugar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (sugarData.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxValue,
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < sugarData.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat('MM/dd')
                                    .format(sugarData[value.toInt()].date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(),
                              style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(),
                    topTitles: const AxisTitles(),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: sugarData.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value.value,
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.purple,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.purple.withOpacity(0.2),
                      ),
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_healthMetrics!.bloodSugarPrediction.isNotEmpty) ...[
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Prediction: ',
                      style: const TextStyle(
                          color: Colors.teal,
                          fontSize: 14,
                          decoration: TextDecoration.none),
                    ),
                    TextSpan(
                      text: _healthMetrics!.bloodSugarPrediction,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: 'Tip: ',
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    TextSpan(
                      text: _healthMetrics!.bloodSugarTip,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.normal,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a placeholder card when no data is available.
  /// 
  /// Parameters:
  /// - title: The title to display on the card
  /// - message: The message to show in the card body
  /// 
  /// Returns:
  /// - A Card widget with the given title and message
  Widget _buildPlaceholderCard(String title, String message) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Center(child: Text(message)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Predictive Analytics",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : !_hasData
                  ? const Center(
                      child: Text('No medical history data found to analyze.'))
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildBloodPressureCard(),
                          const SizedBox(height: 16),
                          _buildBloodSugarCard(),
                          const SizedBox(height: 16),
                          if (_analyticsResult.isNotEmpty)
                            MarkdownBody(
                              data: _analyticsResult,
                              styleSheet: MarkdownStyleSheet(
                                h2: const TextStyle(
                                  color: Colors.teal,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                p: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}
