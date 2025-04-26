import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = false;
  String _analyticsResult = '';
  String _errorMessage = '';
  final String _geminiApiKey = 'AIzaSyBjG13H2bbGtrQw_rHUyqRr82MS_6kp-A8';

  late final GenerativeModel _geminiModel;

  @override
  void initState() {
    super.initState();
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-pro-latest',
      apiKey: _geminiApiKey,
    );
    _checkAndRunAnalysis();
  }

  Future<void> _checkAndRunAnalysis() async {
    final String currentTimeline = await _fetchAndFormatTimelineData();

    if (currentTimeline.startsWith("No medical history data found")) {
      setState(() => _errorMessage = currentTimeline);
      return;
    }

    final currentHash = sha256.convert(utf8.encode(currentTimeline)).toString();

    final prefs = await SharedPreferences.getInstance();
    final lastHash = prefs.getString('lastTimelineHash');

    if (lastHash != currentHash) {
      await _runPredictiveAnalysis(currentTimeline);
      await prefs.setString('lastTimelineHash', currentHash);
    } else {
      _loadSavedAnalysis();
    }
  }

  Future<void> _loadSavedAnalysis() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAnalysis = prefs.getString('savedAnalysis');
    if (savedAnalysis != null && savedAnalysis.isNotEmpty) {
      setState(() => _analyticsResult = savedAnalysis);
    }
  }

  Future<void> _saveAnalysis(String analysis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedAnalysis', analysis);
  }

  Future<String> _fetchAndFormatTimelineData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> savedTexts = prefs.getStringList('savedTexts') ?? [];
    List<String> savedDates = prefs.getStringList('savedDates') ?? [];

    if (savedTexts.isEmpty) {
      return "No medical history data found to analyze.";
    }

    List<MapEntry<DateTime, String>> datedEntries = [];
    for (int i = 0; i < savedTexts.length; i++) {
      if (i < savedDates.length) {
        try {
          DateTime date = DateTime.parse(savedDates[i]);
          datedEntries.add(MapEntry(date, savedTexts[i]));
        } catch (_) {
          datedEntries.add(
              MapEntry(DateTime.now(), savedTexts[i] + " (Date Parse Error)"));
        }
      } else {
        datedEntries
            .add(MapEntry(DateTime.now(), savedTexts[i] + " (Missing Date)"));
      }
    }

    datedEntries.sort((a, b) => a.key.compareTo(b.key));

    StringBuffer formattedData = StringBuffer();
    formattedData.writeln("Medical History Timeline (Oldest First):");
    for (var entry in datedEntries) {
      String formattedDate = DateFormat('yyyy-MM-dd').format(entry.key);
      formattedData.writeln("---");
      formattedData.writeln("Date: $formattedDate");
      formattedData.writeln("Details: ${entry.value.trim()}");
    }
    formattedData.writeln("---");

    return formattedData.toString();
  }

  Future<void> _runPredictiveAnalysis(String timelineData) async {
    if (_geminiApiKey == 'MISSING_API_KEY') {
      setState(() {
        _errorMessage = "API Key is missing. Cannot generate insights.";
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _analyticsResult = '';
      _errorMessage = '';
    });

    final String prompt = '''
You are a thoughtful and concise health assistant. Carefully read **my** medical timeline below.

**Your task:**
- Talk **directly to me**. Use words like **"you"**, **"your health"**, not "the user".
- Be **brief and clear**: 3–5 lines max per section.
- Use **friendly, simple language** I can easily understand.
- Do **not** give medical advice or conclusions — just point out trends and tips.
- Write in **Markdown format** with the headings below only.

Here is **my** health timeline:
---
$timelineData
---

## Observed Trends  
What patterns or habits do you notice from **my** health history?

## Future Considerations  
Based on what you see, what should **I** keep an eye on?

## Quick Wellness Tip  
What’s one helpful tip that fits **my** situation?
''';

    try {
      final content = [Content.text(prompt)];
      final response = await _geminiModel.generateContent(content);

      final resultText = response.text ?? "No insights generated.";

      setState(() {
        _analyticsResult = resultText;
        _isLoading = false;
      });

      await _saveAnalysis(resultText);
    } catch (e) {
      setState(() {
        _errorMessage = "Error during analysis: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Predictive Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                  ? Center(child: Text(_errorMessage))
                  : SingleChildScrollView(
                      child: MarkdownBody(
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
                    ),
        ),
      ),
    );
  }
}
