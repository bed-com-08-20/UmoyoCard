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
      });
      _processOCR(_imageFile!);
    }
  }

  // Process OCR using Google ML Kit
  Future<void> _processOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    String extractedText = recognizedText.text;

    setState(() {
      dateController.text = _extractField(extractedText, "Date");
      clinicController.text = _extractField(extractedText, "Clinic");
      diagnosisController.text = _extractField(extractedText, "Diagnosis");
      treatmentController.text = _extractField(extractedText, "Treatment");
    });

    textRecognizer.close();
  }

  // Extract specific fields from OCR text
  String _extractField(String text, String field) {
    text = text.toLowerCase();
    if (field == "Date") {
      RegExp dateRegex = RegExp(r'(\d{4}-\d{2}-\d{2})'); // YYYY-MM-DD
      Match? match = dateRegex.firstMatch(text);
      return match?.group(0) ?? "Date not found";
    } else if (field == "Clinic") {
      return _extractByKeyword(text, ["clinic", "hospital", "health center"]);
    } else if (field == "Diagnosis") {
      return _extractByKeyword(text, ["diagnosis", "condition", "illness"]);
    } else if (field == "Treatment") {
      return _extractByKeyword(
          text, ["treatment", "medication", "prescription"]);
    }
    return "";
  }

  // Extract text based on keywords
  String _extractByKeyword(String text, List<String> keywords) {
    for (String keyword in keywords) {
      int index = text.indexOf(keyword);
      if (index != -1) {
        int endIndex = text.indexOf("\n", index);
        return text.substring(index, endIndex != -1 ? endIndex : text.length);
      }
    }
    return "Not found";
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
        title: const Text("OCR Scan"),
        centerTitle: true,
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
