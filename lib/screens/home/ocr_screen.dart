import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:umoyocard/screens/records/blood_pressure_screen.dart';
import 'dart:convert';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  String _extractedText = '';
  File? _imageFile;
  bool _isProcessing = false;

  final String _geminiApiKey = 'AIzaSyBjG13H2bbGtrQw_rHUyqRr82MS_6kp-A8';
  late final GenerativeModel _geminiModel;

  @override
  void initState() {
    super.initState();
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-pro-latest',
      apiKey: _geminiApiKey,
    );
  }

  Future<String> saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await image.copy(imagePath);
    return imagePath;
  }

  Color _getColorForCategory(String category) {
    switch (category) {
      case "Normal":
        return Colors.green;
      case "Elevated":
        return Colors.blue;
      case "Hypertension Stage 1":
        return Colors.orange;
      case "Hypertension Stage 2":
        return Colors.black;
      case "Hypertensive Crisis":
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  Future<void> _saveBloodPressureData(String bpLine) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Parse date (optional) and BP reading
    final dateRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})');
    final readingRegex = RegExp(r'(\d{1,3})/(\d{1,3})\s*mmHg');
    
    final dateMatch = dateRegex.firstMatch(bpLine);
    final readingMatch = readingRegex.firstMatch(bpLine);
    
    if (readingMatch == null) {
      debugPrint("No valid BP reading found in line: $bpLine");
      return;
    }
    
    final systolic = int.tryParse(readingMatch.group(1)!) ?? 0;
    final diastolic = int.tryParse(readingMatch.group(2)!) ?? 0;
    
    // Default to current date if no date in the line
    DateTime recordDate = DateTime.now();
    if (dateMatch != null) {
      final dateParts = dateMatch.group(1)!.split('/');
      recordDate = DateTime(
        int.parse(dateParts[2].length == 2 ? '20${dateParts[2]}' : dateParts[2]),
        int.parse(dateParts[1]),
        int.parse(dateParts[0]),
      );
    }
    
    final category = _getCategory(systolic, diastolic);
    final color = _getColorForCategory(category);
    
    // Create and save the record
    final record = {
      'systolic': systolic,
      'diastolic': diastolic,
      'date': recordDate.toIso8601String(),
      'category': category,
      // ignore: deprecated_member_use
      'color': color.value,
    };
    
    // Get existing records and add new one
    final recordsJson = prefs.getStringList('blood_pressure_records') ?? [];
    recordsJson.add(jsonEncode(record));
    await prefs.setStringList('blood_pressure_records', recordsJson);
    debugPrint('Saved BP record: $record');
  }

  String _getCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return "Normal";
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return "Elevated";
    if ((systolic >= 130 && systolic < 140) ||  (diastolic >= 80 && diastolic < 90)) return "Hypertension Stage 1";
    if (systolic >= 140 || diastolic >= 90) return "Hypertension Stage 2";
    if (systolic > 180 || diastolic > 120) return "Hypertensive Crisis";
    return "Not in range";
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String savedPath = await saveImageLocally(imageFile);
      setState(() {
        _imageFile = File(savedPath);
        _isProcessing = true;
        _extractedText = '';
      });

      await _processOCR(_imageFile!);

      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _processOCR(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
You are a skilled medical assistant. Extract ALL blood pressure readings from this document.

Please follow these guidelines carefully:
- If a section is not present in the image, skip it.
- Focus on extracting exactly what is written, but make corrections to spelling, grammar, or formatting for clarity.
- Do not guess or hallucinate information; only extract what can be identified.
- Present the result in a clean, readable, and structured format using labeled sections or bullet points.
- Do NOT use Markdown (e.g., **bold** or code style).
- The structure should make sense to a healthcare worker or patient reading it.
- Do NOT include explanations, summaries, or irrelevant details—only the cleaned and structured medical data.

Return the blood pressure readings in this exact format:
[date if available in DD/MM/YYYY format] [systolic]/[diastolic] mmHg
[date if available] [systolic]/[diastolic] mmHg
...

Example outputs:
12/05/2023 120/80 mmHg
15/05/2023 130/85 mmHg
140/90 mmHg  (when no date is available)

If no blood pressure readings are found, return exactly: "No blood pressure readings detected"

Other Medical Information:
- Date: [date]
- Condition: [condition]
- Medication: [medication]
- Dosage: [dosage]
- Instructions: [instructions]
- Doctor/Hospital: [doctor/hospital]
- Patient: [patient info]
- Symptoms: [symptoms]

''';

      final content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ]);

      final response = await _geminiModel.generateContent([content]);
      final extractedText = response.text ?? "No text extracted or recognized.";
      
      setState(() {
        _extractedText = extractedText;
      });

      if (extractedText.contains("No blood pressure readings detected")) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No blood pressure readings found')),
        );
        return;
      }

      // Process each line separately
      final lines = extractedText.split('\n');
      int addedCount = 0;

      for (final line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;

        try {
          await _saveBloodPressureData(trimmedLine);
          addedCount++;
        } catch (e) {
          debugPrint("Failed to process line: $trimmedLine. Error: $e");
        }
      }

      if (addedCount > 0) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully added $addedCount blood pressure records')),
        );
        Navigator.pushReplacement(
          // ignore: use_build_context_synchronously
          context,
          MaterialPageRoute(
            builder: (context) => const BloodPressureScreen(),
          ),
        );
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No valid blood pressure readings found')),
        );
      }
    } catch (e) {
      debugPrint("Gemini OCR Error: $e");
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image. Please try again.')),
      );
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Medical Document Scan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Scan Your Medical Documents",
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Processing document..."),
                    ],
                  ),
                )
              else ...[
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Take Photo"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
                const SizedBox(height: 8.0),
                ElevatedButton.icon(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Upload from Gallery"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                ),
              ],
              if (_imageFile != null) ...[
                const SizedBox(height: 16.0),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.file(_imageFile!, fit: BoxFit.contain),
                ),
              ],
              if (_extractedText.isNotEmpty) ...[
                const SizedBox(height: 24.0),
                const Text(
                  "Extracted Data",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.grey.shade100,
                  ),
                  child: SelectableText(
                    _extractedText,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}