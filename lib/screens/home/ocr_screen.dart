import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
    }
  }

  Future<void> _processOCR(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();

      final prompt = '''
Extract blood pressure readings from this medical document. 
Return ONLY the readings in this exact format:
[date] [systolic]/[diastolic] mmHg
[date] [systolic]/[diastolic] mmHg
...

Example:
01/01/2023 120/80 mmHg
02/01/2023 118/78 mmHg

If no readings found, return: "No blood pressure readings detected"
''';

      final content = Content.multi([
        DataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ]);

      final response = await _geminiModel.generateContent([content]);
      final text = response.text ?? "No text extracted or recognized.";

      setState(() {
        _extractedText = text;
        _isProcessing = false;
      });

      if (text.contains("mmHg")) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BloodPressureScreen(ocrData: text),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No blood pressure readings found')),
        );
      }
    } catch (e) {
      debugPrint("OCR Error: $e");
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process image')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Blood Pressure'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (_isProcessing)
                      const Center(child: CircularProgressIndicator())
                    else ...[
                      ElevatedButton(
                        onPressed: () => _pickImage(ImageSource.camera),
                        child: const Text('Take Photo'),
                      ),
                      ElevatedButton(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        child: const Text('Choose from Gallery'),
                      ),
                    ],
                    if (_imageFile != null) ...[
                      const SizedBox(height: 20),
                      Image.file(_imageFile!, height: 200),
                    ],
                    if (_extractedText.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      const Text('Extracted Text:'),
                      Text(_extractedText),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}