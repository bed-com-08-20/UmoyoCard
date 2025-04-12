import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});
  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController clinicController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();

  File? _imageFile;
  bool _isProcessing = false;

  // Save record to SharedPreferences (the timeline storage)
  Future<void> _saveRecord() async {
    if (dateController.text.isEmpty ||
        clinicController.text.isEmpty ||
        diagnosisController.text.isEmpty ||
        treatmentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields!')),
      );
      return;
    }

    String savedText = '''
Date: ${dateController.text}
Clinic: ${clinicController.text}
Diagnosis: ${diagnosisController.text}
Treatment: ${treatmentController.text}
''';

    final prefs = await SharedPreferences.getInstance();

    // Get existing lists or initialize if null
    List<String> savedTexts = prefs.getStringList('savedTexts') ?? [];
    List<String> savedImages = prefs.getStringList('savedImages') ?? [];

    savedTexts.add(savedText);
    if (_imageFile != null) {
      savedImages.add(_imageFile!.path);
    }

    await prefs.setStringList('savedTexts', savedTexts);
    await prefs.setStringList('savedImages', savedImages);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health record saved successfully!')),
    );
    // Optionally clear the fields
    dateController.clear();
    clinicController.clear();
    diagnosisController.clear();
    treatmentController.clear();
    setState(() {
      _imageFile = null;
    });
    Navigator.of(context).pop();
  }

  // Save image locally
  Future<String> saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await image.copy(imagePath);
    return imagePath;
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

  // Process OCR using Google ML Kit with enhanced extraction
  Future<void> _processOCR(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final textRecognizer =
          TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);

      String extractedText = recognizedText.text;
      debugPrint("Full OCR Text: $extractedText");

      // Enhanced extraction with multiple patterns and fallbacks
      setState(() {
        dateController.text = _extractDate(extractedText);
        clinicController.text = _extractClinic(extractedText);
        diagnosisController.text = _extractDiagnosis(extractedText);
        treatmentController.text = _extractTreatment(extractedText);
      });

      textRecognizer.close();
    } catch (e) {
      debugPrint("OCR Processing Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Failed to process image. Please try again or enter manually.')),
      );
    }
  }

  // Enhanced date extraction with multiple patterns specific to health passports
  String _extractDate(String text) {
    // Try various date patterns seen in your samples
    final patterns = [
      RegExp(r'Visit:\s*(\d{2}/\w+/\d{4})'), // Visit: 06/Jan/2022
      RegExp(r'(\d{2}/\w+/\d{4}\s+\d{2}:\d{2})'), // 06/Jan/2022 12:10
      RegExp(r'(\d{2}\.\d{2}\.\d{4})'), // 13.10.2023 (DD.MM.YYYY)
      RegExp(r'(\d{4}-\d{2}-\d{2})'), // YYYY-MM-DD
      RegExp(r'(\d{2}/\d{2}/\d{4})'), // DD/MM/YYYY
      RegExp(
          r'(\d{1,2}\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{4})',
          caseSensitive: false), // 12 Jan 2023
    ];

    for (var pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(0)?.replaceFirst('Visit:', '')?.trim() ?? "";
      }
    }

    // Fallback: Look for text near "date" or "visit" keyword
    return _extractNearKeyword(text, ["date", "visit", "encounter"], 30);
  }

  // Enhanced clinic extraction for health passports
  String _extractClinic(String text) {
    // First try to find clinic name patterns from your samples
    final clinicPatterns = [
      RegExp(r'Seen by:\s*(.+?)\s+at\s+(.+)',
          caseSensitive: false), // Seen by: L.Kalapho at Outpatient
      RegExp(r'Facility:\s*(.+)', caseSensitive: false),
      RegExp(r'Hospital:\s*(.+)', caseSensitive: false),
      RegExp(r'Clinic:\s*(.+)', caseSensitive: false),
      RegExp(r'Boston Army Ricks',
          caseSensitive: false), // Specific to your sample
    ];

    for (var pattern in clinicPatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        // Return the most specific part found
        for (int i = match.groupCount; i >= 1; i--) {
          if (match.group(i)?.trim().isNotEmpty ?? false) {
            return match.group(i)!.trim();
          }
        }
      }
    }

    // Fallback: Look for text near clinic-related keywords
    return _extractNearKeyword(
        text,
        [
          "clinic",
          "hospital",
          "health center",
          "medical center",
          "dr.",
          "doctor",
          "seen by",
          "facility",
          "outpatient"
        ],
        50);
  }

  // Enhanced diagnosis extraction for health passports
  String _extractDiagnosis(String text) {
    // First try to find diagnosis patterns from your samples
    final diagnosisPatterns = [
      RegExp(r'Diagnoses at \d{2}:\d{2}\s*(.+)',
          caseSensitive:
              false), // Diagnoses at 12:10 Acute respiratory infection
      RegExp(r'DIAGNOSIS/LAB/TREATMENT / NOTES\s*(.+)',
          caseSensitive: false), // From your first sample
      RegExp(r'Diagnosis:\s*(.+)', caseSensitive: false),
      RegExp(r'Dx:\s*(.+)', caseSensitive: false),
      RegExp(r'Acute respiratory infection',
          caseSensitive: false), // Specific from your sample
      RegExp(r'Pic-breeding from the left foot',
          caseSensitive: false), // From your first sample
    ];

    for (var pattern in diagnosisPatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        // Return the first non-empty group
        for (int i = 1; i <= match.groupCount; i++) {
          if (match.group(i)?.trim().isNotEmpty ?? false) {
            return match.group(i)!.trim();
          }
        }
      }
    }

    // Fallback: Look for text near diagnosis-related keywords
    return _extractNearKeyword(
        text,
        ["diagnosis", "dx", "condition", "illness", "problem", "diagnoses"],
        60);
  }

  // Enhanced treatment extraction for health passports
  String _extractTreatment(String text) {
    // First try to find treatment patterns from your samples
    final treatmentPatterns = [
      RegExp(r'For c - ray\n(.+)',
          caseSensitive: false), // From your first sample
      RegExp(r'Rx:\s*([\s\S]+)', caseSensitive: false),
      RegExp(r'Medication:\s*([\s\S]+)', caseSensitive: false),
      RegExp(r'Prescription:\s*([\s\S]+)', caseSensitive: false),
      RegExp(r'Eloxacinine scoring\nQxd x 5h',
          caseSensitive: false), // From your first sample
      RegExp(r'-\s*Atelvice\n-\s*All courses',
          caseSensitive: false), // From your first sample
      RegExp(r'-\s*Meth.\n-\s*Nucleus',
          caseSensitive: false), // From your second sample
    ];

    for (var pattern in treatmentPatterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        // Return the first non-empty group
        for (int i = 1; i <= match.groupCount; i++) {
          if (match.group(i)?.trim().isNotEmpty ?? false) {
            return match.group(i)!.trim();
          }
        }
      }
    }

    // Fallback: Look for text near treatment-related keywords or list items
    String nearKeywords = _extractNearKeyword(
        text,
        [
          "treatment",
          "rx",
          "medication",
          "prescription",
          "drug",
          "therapy",
          "for",
          "take"
        ],
        100);

    // Also look for bullet points or dashes which often indicate treatments
    if (nearKeywords.isEmpty) {
      RegExp bulletPoints = RegExp(r'(-\s*.+\n?)+');
      Match? bulletsMatch = bulletPoints.firstMatch(text);
      if (bulletsMatch != null) {
        return bulletsMatch.group(0)!.trim();
      }
    }

    return nearKeywords;
  }

  // Helper to extract text near keywords
  String _extractNearKeyword(String text, List<String> keywords, int length) {
    text = text.toLowerCase();
    for (String keyword in keywords) {
      int index = text.indexOf(keyword.toLowerCase());
      if (index != -1) {
        int start = index + keyword.length;
        int end = start + length;
        end = end > text.length ? text.length : end;
        return text.substring(start, end).trim();
      }
    }
    return "";
  }

  // Build an editable field
  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  @override
  void dispose() {
    dateController.dispose();
    clinicController.dispose();
    diagnosisController.dispose();
    treatmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'OCR Scan',
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
                "Digitize Your Health Records",
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
                  label: const Text("Scan Prescription"),
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
              const SizedBox(height: 24.0),
              const Text(
                "Extracted Data (Editable)",
                style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16.0),
              _buildEditableField("Date of Encounter", dateController),
              _buildEditableField("Hospital/Clinic Name", clinicController),
              _buildEditableField("Diagnosis", diagnosisController),
              _buildEditableField(
                  "Treatment/Prescriptions", treatmentController),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const Text("Save Record"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
