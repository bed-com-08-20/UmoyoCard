// analytics_helper.dart
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

// Note: API Key should ideally be loaded securely, not hardcoded.
// For this example, using the one provided.
const String _geminiApiKey = 'AIzaSyBjG13H2bbGtrQw_rHUyqRr82MS_6kp-A8';
final GenerativeModel _geminiModel = GenerativeModel(
  model: 'gemini-1.5-pro-latest',
  apiKey: _geminiApiKey,
);

/// Fetches and formats the timeline data from SharedPreferences.
Future<String> fetchAndFormatTimelineData(SharedPreferences prefs) async {
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
        // Handle date parse errors gracefully by using current date and noting the error
        datedEntries.add(
            MapEntry(DateTime.now(), savedTexts[i] + " (Date Parse Error)"));
      }
    } else {
      // Handle missing dates by using current date and noting the issue
      datedEntries
          .add(MapEntry(DateTime.now(), savedTexts[i] + " (Missing Date)"));
    }
  }

  // Sort entries by date, oldest first for the AI prompt
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

/// Runs the predictive analysis using the Generative AI model.
Future<String> runPredictiveAnalysis(String timelineData) async {
  if (_geminiApiKey == 'MISSING_API_KEY' || _geminiApiKey.isEmpty) {
    return "Error: API Key is missing. Cannot generate insights.";
  }

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
    return response.text ?? "No insights generated.";
  } catch (e) {
    print("Error generating analysis: $e"); // Log the error
    return "Error during analysis: $e"; // Return error message to be displayed
  }
}

/// Saves the analysis result to SharedPreferences.
Future<void> saveAnalysis(SharedPreferences prefs, String analysis) async {
  await prefs.setString('savedAnalysis', analysis);
}

/// Loads the analysis result from SharedPreferences.
Future<String?> loadSavedAnalysis(SharedPreferences prefs) async {
  return prefs.getString('savedAnalysis');
}

/// Gets the last stored hash of the timeline data.
Future<String?> getLastTimelineHash(SharedPreferences prefs) async {
  return prefs.getString('lastTimelineHash');
}

/// Saves the current hash of the timeline data.
Future<void> saveLastTimelineHash(SharedPreferences prefs, String hash) async {
  await prefs.setString('lastTimelineHash', hash);
}

/// Calculates the SHA256 hash of the timeline data string.
String calculateHash(String data) {
  return sha256.convert(utf8.encode(data)).toString();
}

/// Public function to trigger analytics processing if data has changed.
/// This is the function TimelineScreen will call after saving.
/// It runs asynchronously and doesn't directly update UI state.
Future<void> triggerAnalyticsProcessing() async {
  print("Attempting to trigger analytics processing...");
  final prefs = await SharedPreferences.getInstance();
  final currentTimeline = await fetchAndFormatTimelineData(prefs);

  if (currentTimeline.startsWith("No medical history data found")) {
    print("No data to analyze. Clearing saved analysis.");
    // Optionally clear saved analysis if data is gone
    await saveAnalysis(prefs, '');
    await saveLastTimelineHash(prefs, '');
    return; // No data, no analysis needed
  }

  final currentHash = calculateHash(currentTimeline);
  final lastHash = await getLastTimelineHash(prefs);

  if (lastHash != currentHash) {
    print("Timeline data changed. Running predictive analysis.");
    // Note: Analysis runs in the background (non-blocking)
    final analysisResult = await runPredictiveAnalysis(currentTimeline);
    await saveAnalysis(prefs, analysisResult);
    await saveLastTimelineHash(prefs, currentHash);
    print("Analytics processing complete and saved.");
  } else {
    print("Timeline data hash matches. No analysis needed.");
  }
}
