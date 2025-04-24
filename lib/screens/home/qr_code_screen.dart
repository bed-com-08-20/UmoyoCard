import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final TextEditingController contentController = TextEditingController();
  bool isScanning = true;

  // Save raw record to timeline
  Future<void> _saveRecord() async {
    if (contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to save!')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    List<String> savedTexts = prefs.getStringList('savedTexts') ?? [];
    savedTexts.add(contentController.text.trim());
    await prefs.setStringList('savedTexts', savedTexts);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Health record saved successfully!')),
    );
  }

  void _processBarcode(String code) {
    setState(() => isScanning = false);

    String parsed = _extractMedicalContent(code);
    if (parsed.isEmpty) {
      parsed = code; // fallback to full code if nothing extracted
    }

    contentController.text = parsed;
  }

  String _extractMedicalContent(String raw) {
    final buffer = StringBuffer();

    try {
      final jsonData = json.decode(raw);
      if (jsonData is Map<String, dynamic>) {
        jsonData.forEach((key, value) {
          if (_isMedicalKey(key)) {
            buffer.writeln('${_capitalize(key)}: $value');
          }
        });
      }
    } catch (_) {
      // fallback to extracting lines with keywords
      final lines = raw.split('\n');
      for (final line in lines) {
        if (_isMedicalLine(line)) {
          buffer.writeln(line.trim());
        }
      }
    }

    return buffer.toString().trim();
  }

  bool _isMedicalKey(String key) {
    final medicalKeys = [
      'date', 'clinic', 'hospital', 'diagnosis', 'treatment',
      'medication', 'prescription', 'symptoms', 'observations',
      'doctor', 'patient', 'notes'
    ];
    return medicalKeys.any((k) => key.toLowerCase().contains(k));
  }

  bool _isMedicalLine(String line) {
    final keywords = [
      'clinic', 'hospital', 'diagnosis', 'treatment',
      'medication', 'prescription', 'symptom', 'observation',
      'date', 'doctor', 'patient'
    ];
    return keywords.any((word) =>
        line.toLowerCase().contains(word));
  }

  String _capitalize(String str) =>
      str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : str;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Medical QR/Barcode"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: isScanning
                ? MobileScanner(
              onDetect: (barcodeCapture) {
                final code = barcodeCapture.barcodes.firstOrNull?.rawValue;
                if (code != null) _processBarcode(code);
              },
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Scan Complete!", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => setState(() => isScanning = true),
                    icon: const Icon(Icons.replay),
                    label: const Text("Scan Again"),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Scanned Medical Content", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TextField(
                      controller: contentController,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}
