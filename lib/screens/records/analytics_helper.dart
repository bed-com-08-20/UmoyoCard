import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

const String _geminiApiKey = 'AIzaSyBKbJD5DGB1R9zzPWEmYRgStiwlFzcIB3Q';
final GenerativeModel _geminiModel = GenerativeModel(
  model: 'gemini-2.0-flash',
  apiKey: _geminiApiKey,
);

class HealthMetrics {
  final List<BloodPressureData> bloodPressureData;
  final List<BloodSugarData> bloodSugarData;
  final String bloodPressurePrediction;
  final String bloodPressureTip;
  final String bloodSugarPrediction;
  final String bloodSugarTip;

  HealthMetrics({
    required this.bloodPressureData,
    required this.bloodSugarData,
    required this.bloodPressurePrediction,
    required this.bloodPressureTip,
    required this.bloodSugarPrediction,
    required this.bloodSugarTip,
  });
}

class BloodPressureData {
  final DateTime date;
  final int systolic;
  final int diastolic;

  BloodPressureData({
    required this.date,
    required this.systolic,
    required this.diastolic,
  });
}

class BloodSugarData {
  final DateTime date;
  final double value;

  BloodSugarData({
    required this.date,
    required this.value,
  });
}
// Extracts health metrics from timeline data using AI
// [timelineData] The raw timeline text containing health information
// Returns a [HealthMetrics] object containing extracted data, predictions, and tips 
// Throws exceptions if the AI service fails or data parsing fails
Future<HealthMetrics> extractHealthMetrics(String timelineData) async {
  final prompt = '''
From this medical timeline, extract ALL blood pressure and blood sugar readings with their dates.
Return ONLY valid JSON in this exact format with no additional text:

{
  "bloodPressure": [
    {"date": "YYYY-MM-DD", "systolic": 120, "diastolic": 80},
    {"date": "YYYY-MM-DD", "systolic": 130, "diastolic": 85},
    ...
  ],
  "bloodSugar": [
    {"date": "YYYY-MM-DD", "value": 95.0},
    {"date": "YYYY-MM-DD", "value": 110.0},
    ...
  ],
  "bpPrediction": "brief prediction based on trends",
  "bpTip": "practical tip based on readings",
  "sugarPrediction": "brief prediction based on trends", 
  "sugarTip": "practical tip based on readings"
}

Important:
- Extract ALL numeric values after "blood pressure", "bp", "sugar", "glucose" etc.
- Return empty arrays if no data found
- Dates must match the timeline entries
- Values must be numbers
- Include predictions and tips based on the data

Timeline Data:
$timelineData
''';

  try {
    final content = [Content.text(prompt)];
    final response = await _geminiModel.generateContent(content);
    final jsonString = _cleanJsonResponse(response.text ?? '{}');
    print("Raw JSON response: $jsonString");
    final jsonData = jsonDecode(jsonString);

    return HealthMetrics(
      bloodPressureData: (jsonData['bloodPressure'] as List? ?? []).map((item) {
        return BloodPressureData(
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
        return BloodSugarData(
          date: DateTime.parse(item['date'].toString()),
          value: item['value'] is double
              ? item['value']
              : double.parse(item['value'].toString()),
        );
      }).toList(),
      bloodPressurePrediction:
          jsonData['bpPrediction']?.toString() ?? 'No prediction available',
      bloodPressureTip: jsonData['bpTip']?.toString() ?? 'No tip available',
      bloodSugarPrediction:
          jsonData['sugarPrediction']?.toString() ?? 'No prediction available',
      bloodSugarTip: jsonData['sugarTip']?.toString() ?? 'No tip available',
    );
  } catch (e) {
    print("Error extracting metrics: $e");
    return HealthMetrics(
      bloodPressureData: [],
      bloodSugarData: [],
      bloodPressurePrediction: 'Error processing data',
      bloodPressureTip: 'Check your timeline entries',
      bloodSugarPrediction: 'Error processing data',
      bloodSugarTip: 'Check your timeline entries',
    );
  }
}

String _cleanJsonResponse(String response) {
  response = response.replaceAll('```json', '').replaceAll('```', '');
  final startIndex = response.indexOf('{');
  if (startIndex > 0) {
    response = response.substring(startIndex);
  }
  final endIndex = response.lastIndexOf('}');
  if (endIndex < response.length - 1) {
    response = response.substring(0, endIndex + 1);
  }
  return response.trim();
}
// Fetches timeline data from shared preferences and formats it for display 
// [prefs] The SharedPreferences instance to read from 
// Returns a formatted string containing the timeline data or a message if no data exists
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
- When providing the analysis don't start with **okay** or anything. Just go straight to the sections and provide the the analysis
- When giving analysis DO NOT SAY "I". Just give the analysis
---
$timelineData
---

## Observed Trends
What patterns or habits do you notice from **my** health history?

## Future Considerations
Based on what you see, what should **I** keep an eye on?

## Quick Wellness Tip
What's one helpful tip that fits **my** situation?
''';

  try {
    final content = [Content.text(prompt)];
    final response = await _geminiModel.generateContent(content);
    return response.text ?? "No insights generated.";
  } catch (e) {
    return "Error during analysis: $e";
  }
}

Future<void> saveAnalysis(SharedPreferences prefs, String analysis) async {
  await prefs.setString('savedAnalysis', analysis);
}

Future<String?> loadSavedAnalysis(SharedPreferences prefs) async {
  return prefs.getString('savedAnalysis');
}

Future<String?> getLastTimelineHash(SharedPreferences prefs) async {
  return prefs.getString('lastTimelineHash');
}

Future<void> saveLastTimelineHash(SharedPreferences prefs, String hash) async {
  await prefs.setString('lastTimelineHash', hash);
}

String calculateHash(String data) {
  return sha256.convert(utf8.encode(data)).toString();
}
// Triggers analytics processing if timeline data has changed
// Checks if timeline data has changed by comparing hashes,
// and if so, runs analysis and saves results
Future<void> triggerAnalyticsProcessing() async {
  final prefs = await SharedPreferences.getInstance();
  final currentTimeline = await fetchAndFormatTimelineData(prefs);

  if (currentTimeline.startsWith("No medical history data found")) {
    await saveAnalysis(prefs, '');
    await saveLastTimelineHash(prefs, '');
    return;
  }

  final currentHash = calculateHash(currentTimeline);
  final lastHash = await getLastTimelineHash(prefs);

  if (lastHash != currentHash) {
    final analysisResult = await runPredictiveAnalysis(currentTimeline);
    await saveAnalysis(prefs, analysisResult);
    await saveLastTimelineHash(prefs, currentHash);
  }
}

// ================== NEW CACHING FUNCTIONS ================== //
// Saves health metrics to shared preferences 
// [prefs] The SharedPreferences instance to write to
// [metrics] The HealthMetrics object to save

Future<void> saveHealthMetrics(
    SharedPreferences prefs, HealthMetrics metrics) async {
  await prefs.setString(
      'savedHealthMetrics',
      jsonEncode({
        'bloodPressure': metrics.bloodPressureData
            .map((e) => {
                  'date': e.date.toIso8601String(),
                  'systolic': e.systolic,
                  'diastolic': e.diastolic,
                })
            .toList(),
        'bloodSugar': metrics.bloodSugarData
            .map((e) => {
                  'date': e.date.toIso8601String(),
                  'value': e.value,
                })
            .toList(),
        'bpPrediction': metrics.bloodPressurePrediction,
        'bpTip': metrics.bloodPressureTip,
        'sugarPrediction': metrics.bloodSugarPrediction,
        'sugarTip': metrics.bloodSugarTip,
      }));
}
// Loads saved health metrics from shared preferences 
// [prefs] The SharedPreferences instance to read from
// Returns a HealthMetrics object or null if none exists
Future<HealthMetrics?> loadSavedHealthMetrics(SharedPreferences prefs) async {
  final savedMetricsJson = prefs.getString('savedHealthMetrics');
  if (savedMetricsJson == null) return null;

  try {
    final jsonData = jsonDecode(savedMetricsJson);
    return HealthMetrics(
      bloodPressureData: (jsonData['bloodPressure'] as List? ?? []).map((item) {
        return BloodPressureData(
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
        return BloodSugarData(
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
    print("Error parsing saved health metrics: $e");
    return null;
  }
}

// Enhanced version of triggerAnalyticsProcessing that also saves metrics
//Triggers complete analytics processing including metrics extraction
// Checks if timeline data has changed, and if so, runs full analysis,
/// extracts metrics, and saves all results
Future<void> triggerCompleteAnalyticsProcessing() async {
  final prefs = await SharedPreferences.getInstance();
  final currentTimeline = await fetchAndFormatTimelineData(prefs);

  if (currentTimeline.startsWith("No medical history data found")) {
    await saveAnalysis(prefs, '');
    await saveLastTimelineHash(prefs, '');
    await saveHealthMetrics(
        prefs,
        HealthMetrics(
          bloodPressureData: [],
          bloodSugarData: [],
          bloodPressurePrediction: '',
          bloodPressureTip: '',
          bloodSugarPrediction: '',
          bloodSugarTip: '',
        ));
    return;
  }

  final currentHash = calculateHash(currentTimeline);
  final lastHash = await getLastTimelineHash(prefs);

  if (lastHash != currentHash) {
    final metrics = await extractHealthMetrics(currentTimeline);
    final analysisResult = await runPredictiveAnalysis(currentTimeline);

    await saveAnalysis(prefs, analysisResult);
    await saveHealthMetrics(prefs, metrics);
    await saveLastTimelineHash(prefs, currentHash);
  }
}
