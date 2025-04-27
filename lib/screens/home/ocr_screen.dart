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

  Future<String> saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await image.copy(imagePath);
    return imagePath;
  }

  Future<List<Map<String, dynamic>>> _getExistingBloodPressureData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingData = prefs.getStringList('bloodPressureReadings') ?? [];
    return existingData.map((entry) {
      final parts = entry.split('|');
      return {
        'date': parts[0],
        'reading': parts[1],
        'timestamp': parts[2],
      };
    }).toList();
  }

  Future<void> _saveBloodPressureData(String bpData) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> existingData = prefs.getStringList('bloodPressureReadings') ?? [];
    final existingRecords = await _getExistingBloodPressureData();
    
    // Parse the new reading (assuming format: "120/80 mmHg" or "Date: 01/01/23 - 120/80 mmHg")
    final newReading = _parseBloodPressureReading(bpData);
    
    // Check if this reading already exists
    final isDuplicate = existingRecords.any((record) => 
        record['reading'] == newReading['reading'] && 
        (newReading['date'] == null || record['date'] == newReading['date']));
    
    if (!isDuplicate) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final newEntry = '${newReading['date'] ?? DateTime.now().toIso8601String()}|${newReading['reading']}|$timestamp';
      existingData.add(newEntry);
      
      await prefs.setStringList('bloodPressureReadings', existingData);
      debugPrint('New blood pressure data saved successfully');
    } else {
      debugPrint('Duplicate blood pressure reading detected - not saving');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This blood pressure reading already exists in your records')),
      );
    }
  }

  Map<String, dynamic> _parseBloodPressureReading(String bpData) {
    // Try to extract date and reading from the string
    final dateRegex = RegExp(r'(\d{1,2}/\d{1,2}/\d{2,4})');
    final readingRegex = RegExp(r'(\d{2,3}/\d{2,3})\s*(mmHg)?');
    
    final dateMatch = dateRegex.firstMatch(bpData);
    final readingMatch = readingRegex.firstMatch(bpData);
    
    return {
      'date': dateMatch?.group(1),
      'reading': readingMatch?.group(1) ?? bpData.trim(),
    };
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
      });

      await _processOCR(_imageFile!);

      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _checkForBloodPressure(String text) {
    if (text.contains("Blood Pressure Readings:")) {
      final bpData = text.replaceFirst("Blood Pressure Readings:", "").trim();
      if (bpData.isNotEmpty && !bpData.contains("No blood pressure")) {
        _saveBloodPressureData(bpData).then((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BloodPressureScreen.withData(bpData),
            ),
          );
        });
      }
    }
  }

  Future<void> _processOCR(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
You are a skilled medical assistant. Carefully extract and correct all relevant medical information from the image of a health document.

Please follow these guidelines carefully:
- Extract blood pressure readings with high precision
- If multiple readings exist, list them all with dates if available
- Format blood pressure as: [date if available] [systolic/diastolic] mmHg
- Example: "01/01/23 120/80 mmHg" or "120/80 mmHg" if no date
- For multiple readings: "01/01/23 120/80 mmHg, 02/01/23 118/78 mmHg"
- If a section is not present in the image, skip it
- Focus on extracting exactly what is written
- Make corrections only to obvious errors in spelling or formatting
- Do not guess or hallucinate information
- Present the result in a clean, structured format
- Do NOT use Markdown
- The structure should be clear and consistent

Return the data in this exact format:

Blood Pressure Readings:
[date if available] [reading1], [date if available] [reading2], etc.

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