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

  // Export content to PDF
  Future<void> _exportToPdf(String? text, String? imagePath) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(build: (pw.Context context) {
        final widgets = <pw.Widget>[];
        if (text != null) {
          widgets.add(pw.Text(text));
        }
        if (imagePath != null) {
          final image = pw.MemoryImage(File(imagePath).readAsBytesSync());
          widgets.add(pw.SizedBox(height: 20));
          widgets.add(pw.Image(image));
        }
        return pw.Column(children: widgets);
      }),
    );
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  // Edit text record
  void _editText(int index) {
    final controller = TextEditingController(text: savedTexts[index]);
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

  // Delete a record
  void _deleteRecord(int index) {
    setState(() {
      savedTexts.removeAt(index);
      if (index < savedImages.length) {
        savedImages.removeAt(index);
      }
      _updatePreferences();
    });
  }

  // Show full screen image
  void _showFullImage(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Full Image'),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  // Build timeline item combining text and image
  Widget _buildTimelineItem(int index) {
    final hasText = index < savedTexts.length;
    final hasImage = index < savedImages.length;

    if (!hasText && !hasImage) return const SizedBox();

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
              height: hasImage ? 200 : 60,
              color: Colors.blue,
            ),
          ],
        ),
        const SizedBox(width: 16.0),
        // Record content with three-dots menu
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hasText)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                          child: Text(savedTexts[index],
                              style: const TextStyle(fontSize: 14.0)),
                        ),
                      if (hasImage)
                        GestureDetector(
                          onTap: () => _showFullImage(savedImages[index]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: Image.file(
                              File(savedImages[index]),
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'edit' && hasText) {
                        _editText(index);
                      } else if (value == 'export') {
                        _exportToPdf(
                          hasText ? savedTexts[index] : null,
                          hasImage ? savedImages[index] : null,
                        );
                      } else if (value == 'delete') {
                        _deleteRecord(index);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      final items = <PopupMenuItem<String>>[];
                      if (hasText) {
                        items.add(const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ));
                      }
                      items.addAll([
                        const PopupMenuItem<String>(
                          value: 'export',
                          child: Text('Export'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ]);
                      return items;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = savedTexts.length > savedImages.length
        ? savedTexts.length
        : savedImages.length;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Timeline',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (itemCount > 0)
                Column(
                  children: List.generate(itemCount, (index) {
                    return _buildTimelineItem(index);
                  }).reversed.toList(),
                )
              else
                const Center(child: Text("No entries saved.")),
            ],
          ),
        ),
      ),
    );
  }
}
