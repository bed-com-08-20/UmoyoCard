import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:umoyocard/screens/records/analytics_helper.dart'
    as analytics_helper;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true; // Start as true to indicate loading saved data
  String _analyticsResult = '';
  String _errorMessage = '';

  // Remove _geminiApiKey and _geminiModel as the helper manages them

  @override
  void initState() {
    super.initState();
    // Removed direct Gemini model initialization
    _loadAndCheckAnalysis(); // Call a method to load saved data and trigger background check
  }

  Future<void> _loadAndCheckAnalysis() async {
    setState(() {
      _isLoading = true;
      _analyticsResult = '';
      _errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Load the pre-calculated result from the helper
      final savedResult = await analytics_helper.loadSavedAnalysis(prefs);

      if (savedResult != null && savedResult.isNotEmpty) {
        print("Loaded saved analysis result.");
        setState(() {
          _analyticsResult = savedResult;
          _isLoading = false; // Data loaded, stop loading indicator
        });
      } else {
        print("No saved analysis found. Triggering initial processing.");
        // If no saved result, it might be the first run or data was cleared.
        // Show loading while we wait for the first analysis.

        // Use helper functions to fetch, run, and save
        final currentTimeline =
            await analytics_helper.fetchAndFormatTimelineData(prefs);

        if (currentTimeline.startsWith("No medical history data found")) {
          setState(() {
            _errorMessage = currentTimeline;
            _isLoading = false;
          });
          return;
        }

        final analysisResult =
            await analytics_helper.runPredictiveAnalysis(currentTimeline);
        await analytics_helper.saveAnalysis(prefs, analysisResult);
        final currentHash = analytics_helper.calculateHash(currentTimeline);
        await analytics_helper.saveLastTimelineHash(prefs, currentHash);

        setState(() {
          _analyticsResult = analysisResult;
          _isLoading = false;
        });
      }

      // --- ADD THIS LINE (Optional but recommended as fallback) ---
      // Trigger the processing check in the background just in case,
      // but don't wait for it. The UI already has the loaded result.
      analytics_helper.triggerAnalyticsProcessing().catchError((e) {
        print("Background analytics trigger failed: $e");
        // Handle error if needed, maybe update error state?
      });
      // -----------------------------------------------------------
    } catch (e) {
      print("Error loading/checking analysis: $e");
      setState(() {
        _errorMessage = "Error loading analytics: $e";
        _isLoading = false;
      });
    }
  }

  // Removed the individual _fetchAndFormatTimelineData, _runPredictiveAnalysis,
  // _loadSavedAnalysis, _saveAnalysis, _checkAndRunAnalysis methods
  // as their logic is now in analytics_helper.dart

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          // Added const
          "Predictive Analytics",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Added const
          child: _isLoading
              ? const Center(child: CircularProgressIndicator()) // Added const
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : _analyticsResult
                          .isEmpty // Show message if no result and no error
                      ? const Center(
                          child: Text(
                              'No analysis available yet. Add some timeline data!')) // Added const
                      : SingleChildScrollView(
                          child: MarkdownBody(
                            data: _analyticsResult,
                            styleSheet: MarkdownStyleSheet(
                              h2: const TextStyle(
                                // Added const
                                color: Colors.teal,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              p: const TextStyle(
                                // Added const
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
        ),
      ),
    );
  }
}
