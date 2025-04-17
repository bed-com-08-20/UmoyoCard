import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class OCRScreen extends StatefulWidget {
  const OCRScreen({super.key});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  File? _imageFile;
  String _extractedText = "";
  bool _isProcessing = false;

  final String _geminiApiKey = 'AIzaSyBjG13H2bbGtrQw_rHUyqRr82MS_6kp-A8';
  late final GenerativeModel _geminiModel;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initGemini();
  }

  void _initGemini() {
    _geminiModel = GenerativeModel(
      model: 'gemini-1.5-pro-latest',
      apiKey: _geminiApiKey,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _extractedText = "";
        _isProcessing = true;
      });

      await _runOCR(_imageFile!);
    }
  }

  Future<void> _runOCR(File imageFile) async {
    try {
      final mlKitText = await _runMLKitOCR(imageFile);
      final geminiText = await _enhanceOCRWithGemini(imageFile, mlKitText);

      setState(() {
        _extractedText = geminiText;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _extractedText = "Error: ${e.toString()}";
        _isProcessing = false;
      });
    }
  }

  Future<String> _runMLKitOCR(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText =
    await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    return recognizedText.text;
  }

  Future<String> _enhanceOCRWithGemini(File imageFile, String mlKitText) async {
    final imageBytes = await imageFile.readAsBytes();

    final prompt =
        "Refine the following OCR output and correct any errors. Also, extract the following information, if present: medication name, dosage, and any instructions. Return the refined text and extracted information in a clear, readable format:\n\n$mlKitText";

    final content = Content(
      'user',
      [
        DataPart('image/jpeg', imageBytes),
        TextPart(prompt),
      ],
    );

    final response = await _geminiModel.generateContent([content]);

    return response.text ?? "No text recognized or enhanced by Gemini.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Scan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library),
              label: const Text("Pick from Gallery"),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
            const SizedBox(height: 16),
            if (_imageFile != null)
              Image.file(_imageFile!, height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            _isProcessing
                ? const CircularProgressIndicator()
                : Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _extractedText.isEmpty
                      ? 'No text extracted yet.'
                      : _extractedText,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
