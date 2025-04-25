import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
//import 'package:umoyocard/services/fhir_service.dart';

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
      if (savedDates.length < savedTexts.length) {
        final missingDates = savedTexts.length - savedDates.length;
        savedDates.addAll(List.generate(
            missingDates, (index) => DateTime.now().toIso8601String()));
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
          final dateA = DateFormat('MMMM yyyy').parse(a);
          final dateB = DateFormat('MMMM yyyy').parse(b);
          return dateB.compareTo(dateA);
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

  Widget _buildTimelineItem(int index) {
    final hasText = index < savedTexts.length;
    final hasImage = index < savedImages.length;
    final hasDate = index < savedDates.length;
    if (!hasText && !hasImage) return const SizedBox();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 2,
          height: hasImage ? 200 : 60,
          color: _getMonthColor(
              hasDate ? DateTime.parse(savedDates[index]) : DateTime.now()),
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
                  if (hasDate)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        DateFormat('MMM dd, yyyy - HH:mm').format(
                            DateTime.parse(savedDates[index]).toLocal()),
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
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.picture_as_pdf),
                        onPressed: () => _exportToPdf(
                          hasText ? savedTexts[index] : null,
                          hasImage ? savedImages[index] : null,
                        ),
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
    switch (month) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.red;
      case 3:
        return Colors.green;
      case 4:
        return Colors.purple;
      case 5:
        return Colors.orange;
      case 6:
        return Colors.pink;
      case 7:
        return Colors.teal;
      case 8:
        return Colors.amber;
      case 9:
        return Colors.indigo;
      case 10:
        return Colors.brown;
      case 11:
        return Colors.cyan;
      case 12:
        return Colors.deepPurple;
      default:
        return Colors.blue;
    }
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Column(
            children: [
              Text(
                'All Entries (${savedTexts.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'Search by month (e.g. "April 2025") - filters entries',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
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
            margin: EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                )
              ],
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
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
          ),
          const SizedBox(width: 16),
          Text(
            DateFormat('MMMM yyyy').format(date),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRecordsIndices = _getAllRecordsSorted();
    Map<String, List<int>> groupedEntries = {};
    for (int index in allRecordsIndices) {
      try {
        final date = DateTime.parse(savedDates[index]);
        final monthYear = DateFormat('MMMM yyyy').format(date);
        groupedEntries.putIfAbsent(monthYear, () => []).add(index);
      } catch (e) {
        continue;
      }
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Timeline',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedData,
        child: Column(
          children: [
            _buildMonthNavigationHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_showSearchResults)
                      _searchResults.isEmpty
                          ? Center(child: Text('No results found'))
                          : Column(
                              children: _searchResults
                                  .map((index) => _buildTimelineItem(index))
                                  .toList(),
                            )
                    else
                      ...groupedEntries.entries.map((entry) {
                        try {
                          final date = DateFormat('MMMM yyyy').parse(entry.key);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDateSectionHeader(date),
                              ...entry.value
                                  .map((index) => _buildTimelineItem(index))
                                  .toList(),
                            ],
                          );
                        } catch (e) {
                          return const SizedBox();
                        }
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
