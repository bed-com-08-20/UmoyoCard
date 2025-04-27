import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:umoyocard/screens/records/blood_pressure_screen.dart';

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

  // Save image locally
  Future<String> saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await image.copy(imagePath);
    return imagePath;
  }

  // Save blood pressure data to SharedPreferences
  Future<void> _saveBloodPressureData(String bpData) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingData = prefs.getStringList('bloodPressureReadings') ?? [];
    
    final newEntry = '${DateTime.now().toIso8601String()}|$bpData';
    existingData.add(newEntry);
    
    await prefs.setStringList('bloodPressureReadings', existingData);
    debugPrint('Blood pressure data saved successfully');
  }

  // Pick an image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      String savedPath = await saveImageLocally(imageFile);
      setState(() {
        _imageFile = File(savedPath);
        _isProcessing = true;
      });

      await _processOCR(_imageFile!);

      setState(() {
        _isProcessing = false;
        
      });
    }
  }

  // Check for blood pressure data and route accordingly
  void _checkForBloodPressure(String text) {
    if (text.contains("Blood Pressure Readings:")) {
      final bpData = text.replaceFirst("Blood Pressure Readings:", "").trim();
      if (bpData.isNotEmpty && !bpData.contains("No blood pressure")) {
        _saveBloodPressureData(bpData).then((_) {
          Navigator.pushReplacement(
            // ignore: use_build_context_synchronously
            context,
            MaterialPageRoute(
              builder: (context) => BloodPressureScreen.withData(bpData),
            ),
          );
        });
      }
    }
  }

  // Use Gemini API to process OCR and extract medical data
  Future<void> _processOCR(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
You are a skilled medical assistant. Carefully extract and correct all relevant medical information from the image of a health document.

Please follow these guidelines carefully:
- If a section is not present in the image, skip it.
- Focus on extracting exactly what is written, but make corrections to spelling, grammar, or formatting for clarity.
- Do not guess or hallucinate information; only extract what can be identified.
- Present the result in a clean, readable, and structured format using labeled sections or bullet points.
- Do NOT use Markdown (e.g., **bold** or `code` style).
- The structure should make sense to a healthcare worker or patient reading it.
- Do NOT include explanations, summaries, or irrelevant details—only the cleaned and structured medical data.

Always ensure the information is medically accurate and properly formatted for clarity and future digital record-keeping.

Return the data in this exact format:

Blood Pressure Readings:
[date if available] [reading1]
[date if available] [reading2]
[etc]

Other Medical Information:
- Date: [date]
- Condition: [condition]
- Medication: [medication]
- Dosage: [dosage]
- Instructions: [instructions]
- Doctor/Hospital: [doctor/hospital]
- Patient: [patient info]
- Symptoms: [symptoms]

If no blood pressure readings are found, return: "No blood pressure readings detected"
If no medical information is found, return: "No medical information detected"
''';

      final content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ]);

      final response = await _geminiModel.generateContent([content]);

      setState(() {
        _extractedText = response.text ?? "No text extracted or recognized.";
        _checkForBloodPressure(_extractedText);
      });
    } catch (e) {
      debugPrint("Gemini OCR Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to process image. Please try again.')),
      );
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
                  child: Center(
                    child: CircularProgressIndicator(),
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
                Image.file(_imageFile!, height: 150, fit: BoxFit.cover),
              ],
              if (_extractedText.isNotEmpty) ...[
                const SizedBox(height: 24.0),
                const Text(
                  "Extracted Medical Data",
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