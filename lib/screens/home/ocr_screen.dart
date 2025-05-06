import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:umoyocard/screens/records/analytics_helper.dart'
    as analytics_helper;
//import 'package:umoyocard/analytics_helper.dart' as analytics_helper; // Import with a prefix

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  String _extractedText = '';
  File? _imageFile;
  bool _isProcessing = false;

  // Note: API Key should ideally be loaded securely, not hardcoded.
  // For this example, using the one provided.
  // If using dotenv, you would load it like: dotenv.env['GEMINI_API_KEY']
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

  // Save record to SharedPreferences
  Future<void> _saveRecord() async {
    if (_extractedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text extracted to save!')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> savedTexts = prefs.getStringList('savedTexts') ?? [];
    List<String> savedImages = prefs.getStringList('savedImages') ?? [];
    List<String> savedDates = prefs.getStringList('savedDates') ?? [];

    savedTexts.add(_extractedText);
    if (_imageFile != null) {
      savedImages.add(_imageFile!.path);
    } else {
      // Add an empty string placeholder if no image was saved for this entry
      savedImages.add('');
    }
    savedDates.add(DateTime.now().toIso8601String());

    await prefs.setStringList('savedTexts', savedTexts);
    await prefs.setStringList('savedImages', savedImages);
    await prefs.setStringList('savedDates', savedDates);

    // Trigger the analytics processing AFTER saving the data
    analytics_helper.triggerAnalyticsProcessing();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health record saved successfully!')),
    );

    // Clear the current state after saving
    setState(() {
      _extractedText = '';
      _imageFile = null;
    });

    // Optionally pop the screen after saving
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
      // Save the image locally first so we have a persistent path
      String savedPath = await saveImageLocally(imageFile);

      setState(() {
        _imageFile = File(savedPath); // Use the saved path
        _extractedText = ''; // Clear previous text
        _isProcessing = true; // Show loading indicator
      });

      // Process OCR on the saved image file
      await _processOCR(_imageFile!);

      setState(() {
        _isProcessing = false; // Hide loading indicator
      });
    }
  }

  // Use Gemini API to process OCR and enhance text
  Future<void> _processOCR(File imageFile) async {
    if (_geminiApiKey == 'MISSING_API_KEY' || _geminiApiKey.isEmpty) {
      setState(() {
        _extractedText = "Error: API Key is missing. Cannot perform OCR.";
        _isProcessing = false;
      });
      return;
    }

    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
You are a skilled medical assistant. Carefully extract and correct all relevant medical information from the image of a health passport page. The page may contain handwritten or printed notes.
Guidelines: Please follow these guidelines carefully
- If a section is not present in the image, skip it.
- Focus on **extracting exactly what is written**, but make corrections to spelling, grammar, or formatting for clarity.
- **Do not guess or hallucinate information**; only extract what can be identified.
- Present the result in a clean, readable, and structured format using labeled sections or bullet points.
- Do NOT use Markdown (e.g., **bold** or `code` style).
- The structure should make sense to a healthcare worker or patient reading it.
- **Do NOT include explanations, summaries, or irrelevant details**—only the cleaned and structured medical data.

Always ensure the information is medically accurate and properly formatted for clarity and future digital record-keeping.

Identify and organize the following fields if they are present:

1. Date(s) — Format as dd/mm/yy
2. Medical Condition(s) or Diagnosis
3. Medication Name(s)
4. Dosage and Frequency
5. Administration Instructions
6. Doctor or Hospital Name
7. Patient Information (Name, Age, etc.)
8. Signs, symptoms, or Observations
''';

      final content = Content(
        'user',
        [
          DataPart('image/jpeg', imageBytes),
          TextPart(prompt),
        ],
      );

      final response = await _geminiModel.generateContent([content]);

      setState(() {
        _extractedText = response.text ?? "No text extracted or recognized.";
      });
    } catch (e) {
      debugPrint("Gemini OCR Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to process image. Please try again.')),
      );
      setState(() {
        _extractedText =
            "Error processing image: $e"; // Display error in text area
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'OCR Scan',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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
                // Display the image from the locally saved path
                Image.file(
                  _imageFile!,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(child: Text('Could not load image.'));
                  },
                ),
              ],
              if (_extractedText.isNotEmpty) ...[
                const SizedBox(height: 24.0),
                const Text(
                  "Extracted Prescription",
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
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                  ),
                  child: const Text('Save Record'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
