import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<String> savedTexts = [];
  List<String> savedImages = [];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  // Load saved texts and images from SharedPreferences
  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedTexts = prefs.getStringList('savedTexts') ?? [];
      savedImages = prefs.getStringList('savedImages') ?? [];
    });
  }

  // Save updated lists to SharedPreferences
  Future<void> _updatePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedTexts', savedTexts);
    await prefs.setStringList('savedImages', savedImages);
  }

  // Export text to PDF
  Future<void> _exportTextToPdf(String text) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Text(text));
      }),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Export image to PDF
  Future<void> _exportImageToPdf(String imagePath) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(File(imagePath).readAsBytesSync());
    pdf.addPage(
      pw.Page(build: (pw.Context context) {
        return pw.Center(child: pw.Image(image));
      }),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Edit text record
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
                  _updatePreferences();
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

  // Delete a text record
  void _deleteText(String text) {
    setState(() {
      savedTexts.remove(text);
      _updatePreferences();
    });
  }

  // Delete an image record
  void _deleteImage(String imagePath) {
    setState(() {
      savedImages.remove(imagePath);
      _updatePreferences();
    });
  }

  // Build timeline item for text record
  Widget _buildTimelineTextItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator (a dot and vertical line)
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 60,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(width: 16.0),
        // Record content with three-dots menu
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                      child:
                          Text(text, style: const TextStyle(fontSize: 14.0))),
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
            ),
          ),
        ),
      ],
    );
  }

  // Build timeline item for image record
  Widget _buildTimelineImageItem(String imagePath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 60,
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(width: 16.0),
        // Record content with image and three-dots menu
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: Image.file(File(imagePath),
                        height: 100, fit: BoxFit.cover),
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
            ),
          ),
        ),
      ],
    );
  }

  // Build the timeline view combining texts and images
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Timeline")),
      body: RefreshIndicator(
        onRefresh: _loadSavedData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Saved Texts",
                  style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16.0),
              savedTexts.isEmpty
                  ? const Text("No texts saved.")
                  : Column(
                      // Reverse the list so that the latest text is on top
                      children: savedTexts.reversed
                          .map((text) => _buildTimelineTextItem(text))
                          .toList(),
                    ),
              const SizedBox(height: 32.0),
              const Text("Saved Images",
                  style:
                      TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16.0),
              savedImages.isEmpty
                  ? const Text("No images saved.")
                  : Column(
                      // Reverse the list so that the latest image is on top
                      children: savedImages.reversed
                          .map(
                              (imagePath) => _buildTimelineImageItem(imagePath))
                          .toList(),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
