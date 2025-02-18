import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class OCRScreen extends StatefulWidget {
  final bool isPassportScan;

  const OCRScreen({super.key, required this.isPassportScan});

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController clinicController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();

  File? _imageFile;
  List<String> savedTexts = [];
  List<String> savedImages = [];

  // Load saved texts and images from preferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();

    savedTexts = prefs.getStringList('savedTexts') ?? [];
    savedImages = prefs.getStringList('savedImages') ?? [];
    setState(() {});
  }

  // Save data to preferences
  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList('savedTexts', savedTexts);
    await prefs.setStringList('savedImages', savedImages);
  }

  // Save image locally
  Future<String> saveImageLocally(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagePath =
        '${directory.path}/prescription_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await image.copy(imagePath);
    return imagePath;
  }

  // Pick an image from the gallery or camera
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

    setState(() {
      String extractedText = recognizedText.text;

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

  // Save extracted data
  void _saveData() {
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

    setState(() {
      savedTexts.add(savedText);

      if (_imageFile != null) {
        savedImages.add(_imageFile!.path);
      }

      _saveToPreferences();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health record saved successfully!')),
    );
  }

  // Export text to PDF
  Future<void> _exportTextToPdf(String text) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(text),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // Export image to PDF
  Future<void> _exportImageToPdf(String imagePath) async {
    final pdf = pw.Document();

    final image = pw.MemoryImage(File(imagePath).readAsBytesSync());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(image),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadSavedData(); // Load saved data when the screen is initialized
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
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
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
                onPressed: _saveData,
                child: const Text("Save Record"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                ),
              ),
              if (widget.isPassportScan) ...[
                const SizedBox(height: 24.0),
                const Text(
                  "Saved Texts",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                savedTexts.isEmpty
                    ? const Text("No texts saved.")
                    : Column(
                        children: savedTexts
                            .map((text) => _buildSavedTextItem(text))
                            .toList(),
                      ),
                const SizedBox(height: 24.0),
                const Text(
                  "Saved Images",
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                savedImages.isEmpty
                    ? const Text("No images saved.")
                    : Column(
                        children: savedImages
                            .map((imagePath) => _buildSavedImageItem(imagePath))
                            .toList(),
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Build editable fields
  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }

  // Build saved text item with three dots menu
  Widget _buildSavedTextItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.0),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'edit') {
                _editText(text);
              } else if (value == 'export') {
                _exportTextToPdf(text);
              } else if (value == 'delete') {
                _deleteText(text);
              }
            },
            itemBuilder: (BuildContext context) {
              return {'edit', 'export', 'delete'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  // Build saved image item with three dots menu
  Widget _buildSavedImageItem(String imagePath) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Image.file(
              File(imagePath),
              height: 150,
              fit: BoxFit.cover,
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'export') {
                _exportImageToPdf(imagePath);
              } else if (value == 'delete') {
                _deleteImage(imagePath);
              }
            },
            itemBuilder: (BuildContext context) {
              return {'export', 'delete'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  // Edit text
  void _editText(String text) {
    final index = savedTexts.indexOf(text);
    final controller = TextEditingController(text: text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Text'),
          content: TextField(
            controller: controller,
            maxLines: 5,
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  savedTexts[index] = controller.text;
                  _saveToPreferences();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Delete text
  void _deleteText(String text) {
    setState(() {
      savedTexts.remove(text);
      _saveToPreferences();
    });
  }

  // Delete image
  void _deleteImage(String imagePath) {
    setState(() {
      savedImages.remove(imagePath);
      _saveToPreferences();
    });
  }
}
