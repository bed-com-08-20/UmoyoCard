import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:umoyocard/screens/records/analytics_helper.dart'
    as analytics_helper;

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});
  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  List<String> savedTexts = [];
  List<String> savedImages = [];
  List<String> savedDates = [];
  final TextEditingController _searchController = TextEditingController();
  List<String> _availableMonths = [];
  bool _showSearchResults = false;
  List<int> _searchResults = [];
  bool _showMonthSuggestions = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedTexts = prefs.getStringList('savedTexts') ?? [];
      savedImages = prefs.getStringList('savedImages') ?? [];
      savedDates = prefs.getStringList('savedDates') ?? [];

      while (savedDates.length < savedTexts.length) {
        savedDates.add(DateTime.now().toIso8601String());
      }

      if (savedDates.length > savedTexts.length) {
        savedDates = savedDates.take(savedTexts.length).toList();
      }

      if (savedDates.length == savedTexts.length &&
          savedDates.any((date) => date == DateTime.now().toIso8601String())) {
        _updatePreferences();
      }

      final months = <String>{};
      for (final dateStr in savedDates) {
        try {
          final date = DateTime.parse(dateStr);

          months.add(DateFormat('MMMM yyyy').format(date));
        } catch (e) {
          continue;
        }
      }
      _availableMonths = months.toList()
        ..sort((a, b) {
          try {
            final dateA = DateFormat('MMMM yyyy').parse(a);
            final dateB = DateFormat('MMMM yyyy').parse(b);

            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });
    });
  }

  Future<void> _updatePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedTexts', savedTexts);
    await prefs.setStringList('savedImages', savedImages);
    await prefs.setStringList('savedDates', savedDates);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _showMonthSuggestions = false;
      });
      return;
    }
    setState(() {
      _showMonthSuggestions = true;
    });
    final monthSuggestions = _availableMonths
        .where((month) => month.toLowerCase().contains(query))
        .toList();
    if (monthSuggestions.length == 1 &&
        monthSuggestions.first.toLowerCase() == query.toLowerCase()) {
      _performSearch(monthSuggestions.first);
      return;
    }
    setState(() {
      _showMonthSuggestions = true;
    });
  }

  void _performSearch(String monthYear) {
    final results = <int>[];
    for (int i = 0; i < savedDates.length; i++) {
      try {
        final date = DateTime.parse(savedDates[i]);

        final formattedDate = DateFormat('MMMM yyyy').format(date);

        if (formattedDate.toLowerCase() == monthYear.toLowerCase()) {
          results.add(i);
        }
      } catch (e) {
        continue;
      }
    }
    setState(() {
      _searchResults = results;
      _showSearchResults = true;
      _showMonthSuggestions = false;
    });
  }

  Future<void> _exportToPdf(String? text, String? imagePath) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(build: (pw.Context context) {
        final widgets = <pw.Widget>[];
        if (text != null) {
          widgets.add(pw.Text(text));
        }
        if (imagePath != null) {
          try {
            final imageFile = File(imagePath);
            if (imageFile.existsSync()) {
              final image = pw.MemoryImage(imageFile.readAsBytesSync());
              widgets.add(pw.SizedBox(height: 20));
              widgets.add(pw.Image(image));
            } else {
              widgets.add(pw.Text(
                  'Image not found: ${imagePath.split('/').last}',
                  style: const pw.TextStyle(color: PdfColors.red)));
            }
          } catch (e) {
            widgets.add(pw.Text('Error loading image: $e',
                style: const pw.TextStyle(color: PdfColors.red)));
          }
        }
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start, children: widgets);
      }),
    );
    try {
      await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) {
      // Show an error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate PDF: $e')),
      );
    }
  }

  void _showFullImage(String imagePath) {
    if (!File(imagePath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image file not found.')),
      );
      return;
    }
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

  Widget _buildTimelineItem(int index) {
    if (index >= savedTexts.length) return const SizedBox();

    final hasText = index < savedTexts.length;
    final hasImage =
        index < savedImages.length && savedImages[index].isNotEmpty;
    final hasDate = index < savedDates.length;

    if (!hasText && !hasImage) return const SizedBox();

    DateTime itemDate;
    if (hasDate) {
      try {
        itemDate = DateTime.parse(savedDates[index]);
      } catch (e) {
        itemDate = DateTime.now();
      }
    } else {
      itemDate = DateTime.now();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2,
          height: (hasText ? 60 : 0) + (hasImage ? 200 : 0) + 20,
          color: _getMonthColor(itemDate),
          margin: const EdgeInsets.only(left: 8),
        ),
        const SizedBox(width: 16.0),
        Expanded(
          child: Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      DateFormat('MMM dd, - HH:mm').format(itemDate.toLocal()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  if (hasText)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
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
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              alignment: Alignment.center,
                              height: 150,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image,
                                  color: Colors.grey, size: 50),
                            );
                          },
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.picture_as_pdf),
                        onPressed: () => _exportToPdf(
                          hasText ? savedTexts[index] : null,
                          hasImage ? savedImages[index] : null,
                        ),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_forever, color: Colors.red),
                        onPressed: () => _confirmDelete(index),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getMonthColor(DateTime date) {
    final month = date.month;

    const colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.indigo,
      Colors.brown,
      Colors.cyan,
      Colors.deepPurple,
    ];

    return colors[(month - 1) % colors.length];
  }

  List<int> _getAllRecordsSorted() {
    List<int> indices = List.generate(savedTexts.length, (index) => index);
    indices.sort((a, b) {
      try {
        final dateA = DateTime.parse(savedDates[a]);
        final dateB = DateTime.parse(savedDates[b]);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });
    return indices;
  }

  Widget _buildMonthNavigationHeader() {
    if (savedTexts.isEmpty) {
      return const SizedBox();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            children: [
              Text(
                'All Entries (${savedTexts.length})',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Search by month (e.g. "April 2025") - filters entries',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _showSearchResults = false;
                              _showMonthSuggestions = false;
                            });
                          },
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        if (_showMonthSuggestions && _availableMonths.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4, left: 16, right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                // Added const
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                // Added const
                maxHeight: 200,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _availableMonths.length,
                itemBuilder: (context, index) {
                  final month = _availableMonths[index];
                  return ListTile(
                    title: Text(month),
                    onTap: () {
                      _searchController.text = month;
                      _performSearch(month);
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDateSectionHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            color: _getMonthColor(date),
            margin: const EdgeInsets.only(left: 8),
          ),
          const SizedBox(width: 16),
          Text(
            DateFormat('MMMM yyyy').format(date),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) async {
    if (index < 0 || index >= savedTexts.length) return;

    if (index < savedImages.length && savedImages[index].isNotEmpty) {
      final imagePath = savedImages[index];
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        try {
          await imageFile.delete();
          print('Deleted image file: $imagePath');
        } catch (e) {
          print('Error deleting image file $imagePath: $e');
        }
      }
    }

    setState(() {
      savedTexts.removeAt(index);
      if (index < savedImages.length) savedImages.removeAt(index);
      if (index < savedDates.length) savedDates.removeAt(index);

      while (savedImages.length > savedTexts.length) savedImages.removeLast();
      while (savedDates.length > savedTexts.length) savedDates.removeLast();
    });

    await _updatePreferences();

    analytics_helper.triggerAnalyticsProcessing();

    _loadSavedData();
  }

  void _confirmDelete(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'), // Added const
          content: const Text(
              'Are you sure you want to delete this entry?'), // Added const
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'), // Added const
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss dialog
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteItem(index);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRecordsIndices = _getAllRecordsSorted();
    Map<String, List<int>> groupedEntries = {};

    for (int index in allRecordsIndices) {
      if (index >= savedDates.length) continue;

      try {
        final date = DateTime.parse(savedDates[index]);

        final monthYear = DateFormat('MMMM yyyy').format(date);

        groupedEntries.putIfAbsent(monthYear, () => []).add(index);
      } catch (e) {
        continue;
      }
    }

    final sortedMonths = groupedEntries.keys.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMMM yyyy').parse(a);
          final dateB = DateFormat('MMMM yyyy').parse(b);

          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Timeline',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedData, // Refresh loads data
        child: Column(
          children: [
            _buildMonthNavigationHeader(),
            Expanded(
              child: savedTexts.isEmpty &&
                      !_showSearchResults // Show message only if no data and not searching
                  ? const Center(
                      child: Text(
                          'No timeline entries yet. Add some data!')) // Added const
                  : SingleChildScrollView(
                      physics:
                          const AlwaysScrollableScrollPhysics(), // Added const
                      padding: const EdgeInsets.all(16.0), // Added const
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_showSearchResults)
                            _searchResults.isEmpty
                                ? const Center(
                                    child:
                                        Text('No results found')) // Added const
                                : Column(
                                    children: _searchResults
                                        .map((index) =>
                                            _buildTimelineItem(index))
                                        .toList(),
                                  )
                          else
                            // Use the sorted month keys to build sections
                            ...sortedMonths.map((monthYear) {
                              final indicesForMonth =
                                  groupedEntries[monthYear] ?? [];
                              // Sort entries within the month by date descending (latest first)
                              indicesForMonth.sort((a, b) {
                                try {
                                  final dateA = DateTime.parse(savedDates[a]);
                                  final dateB = DateTime.parse(savedDates[b]);
                                  return dateB.compareTo(dateA);
                                } catch (e) {
                                  return 0;
                                }
                              });

                              DateTime sectionDate;
                              if (indicesForMonth.isNotEmpty) {
                                try {
                                  sectionDate = DateTime.parse(
                                      savedDates[indicesForMonth.first]);
                                } catch (e) {
                                  sectionDate = DateTime.now();
                                }
                              } else {
                                sectionDate = DateTime.now();
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDateSectionHeader(sectionDate),
                                  ...indicesForMonth
                                      .map((index) => _buildTimelineItem(index))
                                      .toList(),
                                ],
                              );
                            }).toList(),
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
