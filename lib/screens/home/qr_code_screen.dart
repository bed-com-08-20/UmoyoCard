import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef BarcodeCallback = void Function(String);

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final TextEditingController dateController = TextEditingController();
  final TextEditingController clinicController = TextEditingController();
  final TextEditingController diagnosisController = TextEditingController();
  final TextEditingController treatmentController = TextEditingController();
  bool isScanning = true;

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
    List<String> savedTexts = prefs.getStringList('savedTexts') ?? [];
    savedTexts.add(savedText);
    await prefs.setStringList('savedTexts', savedTexts);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health record saved successfully!')),
    );
  }

  void _processBarcode(String code) {
    setState(() {
      isScanning = false;
    });

    // Assume QR/barcode data is in JSON format

    try {
      Map<String, dynamic> data = _parseQRData(code);
      dateController.text = data['date'] ?? '';
      clinicController.text = data['clinic'] ?? '';
      diagnosisController.text = data['diagnosis'] ?? '';
      treatmentController.text = data['treatment'] ?? '';
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR/Barcode format')),
      );
    }
  }

  Map<String, dynamic> _parseQRData(String data) {
    try {
      return {
        "date": RegExp(r'Date: (.+)').firstMatch(data)?.group(1) ?? "",
        "clinic": RegExp(r'Clinic: (.+)').firstMatch(data)?.group(1) ?? "",
        "diagnosis": RegExp(r'Diagnosis: (.+)').firstMatch(data)?.group(1) ?? "",
        "treatment": RegExp(r'Treatment: (.+)').firstMatch(data)?.group(1) ?? "",
      };
    } catch (e) {
      return {};
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
          'Scan QR/Barcode',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: isScanning
                ? MobileScanner(
              onDetect: (barcode) {
                if (barcode.barcodes.isNotEmpty) {
                  _processBarcode(barcode.barcodes.first.rawValue ?? "");
                }
              },
            )
                : Center(
              child: const Text(
                "Scan Complete! Edit details below.",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildEditableField("Date of Encounter", dateController),
                    _buildEditableField("Hospital/Clinic Name", clinicController),
                    _buildEditableField("Diagnosis", diagnosisController),
                    _buildEditableField("Treatment/Prescriptions", treatmentController),
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
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0)),
        const SizedBox(height: 8.0),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            filled: true,
            fillColor: Colors.grey.shade100,
          ),
        ),
        const SizedBox(height: 16.0),
      ],
    );
  }
}
