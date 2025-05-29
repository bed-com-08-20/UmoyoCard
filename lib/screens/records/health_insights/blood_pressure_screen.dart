import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BloodPressureRecord {
  final int systolic;
  final int diastolic;
  final DateTime date;
  final String category;
  final Color color;

  BloodPressureRecord({
    required this.systolic,
    required this.diastolic,
    required this.date,
    required this.category,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'systolic': systolic,
      'diastolic': diastolic,
      'date': date.toIso8601String(),
      'category': category,
      'color': color.value,
    };
  }

  factory BloodPressureRecord.fromMap(Map<String, dynamic> map) {
    return BloodPressureRecord(
      systolic: map['systolic'],
      diastolic: map['diastolic'],
      date: DateTime.parse(map['date']),
      category: map['category'],
      color: Color(map['color']),
    );
  }

  static String getCategory(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return "Normal";
    if (systolic >= 120 && systolic < 130 && diastolic < 80) return "Elevated";
    if ((systolic >= 130 && systolic < 140) ||
        (diastolic >= 80 && diastolic < 90)) {
      return "Hypertension Stage 1";
    }
    if (systolic >= 140 && diastolic >= 90) return "Hypertension Stage 2";
    if (systolic > 180 || diastolic > 120) return "Hypertensive Crisis";
    return "Not in range";
  }

  static Color getColorForCategory(String category) {
    switch (category) {
      case "Normal":
        return Colors.green;
      case "Elevated":
        return Colors.blue;
      case "Hypertension Stage 1":
        return Colors.orange;
      case "Hypertension Stage 2":
        return Colors.black;
      case "Hypertensive Crisis":
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  String get formattedDate {
    return DateFormat('dd MMM yyyy HH:mm').format(date);
  }
}

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({Key? key}) : super(key: key);

  @override
  _BloodPressureScreenState createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  List<BloodPressureRecord> records = [];
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchResults = false;
  List<int> _searchResults = [];
  bool _showMonthSuggestions = false;
  List<String> _availableMonths = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<BloodPressureRecord>> fetchBloodPressureDataFromTimeline() async {
    final prefs = await SharedPreferences.getInstance();
    final timelineTexts = prefs.getStringList('savedTexts') ?? [];
    final timelineDates = prefs.getStringList('savedDates') ?? [];
    List<BloodPressureRecord> bloodPressureReadings = [];

    final bloodPressureRegex = RegExp(
      r'(?:blood\s*pressure|bp|b\/p|pressure)\s*[=:\-]?\s*(\d+)\s*[\/\\]\s*(\d+)\s*(?:mmHg|mm\s*hg|mm\s*of\s*hg)?|(\d+)\s*[\/\\]\s*(\d+)\s*(?:mmHg|mm\s*hg|mm\s*of\s*hg)?\s*(?:blood\s*pressure|bp|b\/p|pressure)',
      caseSensitive: false,
    );

    for (int i = 0; i < timelineTexts.length; i++) {
      final text = timelineTexts[i];
      final matches = bloodPressureRegex.allMatches(text);

      for (final match in matches) {
        if (i < timelineDates.length) {
          int? systolic, diastolic;
          if (match.group(1) != null && match.group(2) != null) {
            systolic = int.tryParse(match.group(1)!);
            diastolic = int.tryParse(match.group(2)!);
          } else if (match.group(3) != null && match.group(4) != null) {
            systolic = int.tryParse(match.group(3)!);
            diastolic = int.tryParse(match.group(4)!);
          }

          if (systolic != null && diastolic != null) {
            final dateString = timelineDates[i];
            final category =
                BloodPressureRecord.getCategory(systolic, diastolic);
            final color = BloodPressureRecord.getColorForCategory(category);

            bloodPressureReadings.add(BloodPressureRecord(
              systolic: systolic,
              diastolic: diastolic,
              date: DateTime.parse(dateString),
              category: category,
              color: color,
            ));
          }
        }
      }
    }
    return bloodPressureReadings;
  }

  Future<void> _loadInitialData() async {
    // Always get fresh data from timeline, don't use saved blood_pressure_records
    final timelineData = await fetchBloodPressureDataFromTimeline();
    setState(() {
      records = timelineData;
      records.sort((a, b) => b.date.compareTo(a.date));
      _updateAvailableMonths();
    });
  }

  void _updateAvailableMonths() {
    final months = <String>{};
    for (final record in records) {
      final monthYear = DateFormat('MMMM yyyy').format(record.date);
      months.add(monthYear);
    }
    setState(() {
      _availableMonths = months.toList()..sort(_compareMonths);
    });
  }

  int _compareMonths(String a, String b) {
    final dateA = DateFormat('MMMM yyyy').parse(a);
    final dateB = DateFormat('MMMM yyyy').parse(b);
    return dateB.compareTo(dateA);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _showMonthSuggestions = false;
        _searchResults.clear();
      });
      return;
    }

    setState(() {
      _showMonthSuggestions = true;
    });

    bool exactMatch =
        _availableMonths.any((month) => month.toLowerCase() == query);

    if (exactMatch) {
      _performSearch(query);
      setState(() {
        _showMonthSuggestions = false;
      });
    } else {
      setState(() {
        _showSearchResults = false;
      });
    }
  }

  void _performSearch(String monthYear) {
    final results = <int>[];
    for (int i = 0; i < records.length; i++) {
      try {
        final date = records[i].date;
        final formattedDate = DateFormat('MMMM yyyy').format(date);
        if (formattedDate.toLowerCase() == monthYear.toLowerCase()) {
          results.add(i);
        }
      } catch (e) {
        print(
            'Error parsing date during search: ${records[i].date}, Error: $e');
        continue;
      }
    }

    results.sort((a, b) => records[b].date.compareTo(records[a].date));

    setState(() {
      _searchResults = results;
      _showSearchResults = true;
      _showMonthSuggestions = false;
    });
  }

  Widget _buildMonthNavigationHeader() {
    // Show all available months when search is not empty
    final List<String> monthSuggestions =
        _searchController.text.isNotEmpty ? _availableMonths : [];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by month (e.g. "May 2025")',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.teal, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade600),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
            ),
          ),
          if (_showMonthSuggestions && monthSuggestions.isNotEmpty)
            Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(4.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 150,
                  minWidth: double.infinity,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: monthSuggestions.length,
                  itemBuilder: (context, index) {
                    final month = monthSuggestions[index];
                    return ListTile(
                      title: Text(month),
                      dense: true,
                      onTap: () {
                        _searchController.text = month;
                        _searchController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _searchController.text.length),
                        );
                        _performSearch(month);
                        setState(() {
                          _showMonthSuggestions = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final displayRecords = _showSearchResults
        ? _searchResults.map((index) => records[index]).toList()
        : records;

    if (displayRecords.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFE6F4EA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            _showSearchResults
                ? "No results found for '${_searchController.text}'"
                : "No blood pressure data available",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _showSearchResults
                  ? "Search Results Overview"
                  : "Blood Pressure Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  minY: 0,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Dates(month/day)',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      axisNameSize: 30,
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            DateFormat('MM/dd')
                                .format(displayRecords[value.toInt()].date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameWidget: const Text(
                        'Blood Pressure (mmHg)',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      axisNameSize: 30,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  barGroups: displayRecords.asMap().entries.map((entry) {
                    int index = entry.key;
                    BloodPressureRecord record = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: record.systolic.toDouble(),
                          color: record.color,
                          width: 10,
                        )
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSectionHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16),
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
              color: Colors.teal.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMonthColor(DateTime date) {
    final List<Color> colors = [
      Colors.blue.shade300,
      Colors.red.shade300,
      Colors.green.shade300,
      Colors.purple.shade300,
      Colors.orange.shade300,
      Colors.pink.shade300,
      Colors.teal.shade300,
      Colors.amber.shade400,
      Colors.indigo.shade300,
      Colors.brown.shade300,
      Colors.cyan.shade300,
      Colors.deepPurple.shade300,
    ];
    return colors[date.month - 1];
  }

  Widget _buildRecordItem(BloodPressureRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: record.color),
        title: Text("${record.systolic}/${record.diastolic} mmHg"),
        subtitle: Text("${record.category}\n${record.formattedDate}"),
      ),
    );
  }

  Widget _buildRecordList() {
    if (records.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "No blood pressure records available",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Group records by month/year
    final Map<String, List<BloodPressureRecord>> groupedRecords = {};
    for (final record in records) {
      final monthYear = DateFormat('MMMM yyyy').format(record.date);
      groupedRecords.putIfAbsent(monthYear, () => []).add(record);
    }

    // Sort the groups by date (newest first)
    final sortedGroups = groupedRecords.entries.toList()
      ..sort((a, b) {
        try {
          final dateA = DateFormat('MMMM yyyy').parse(a.key);
          final dateB = DateFormat('MMMM yyyy').parse(b.key);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });

    return Expanded(
      child: ListView(
        children: [
          if (_showSearchResults)
            ..._searchResults.map((index) => _buildRecordItem(records[index]))
          else
            ...sortedGroups.expand((group) {
              final date = DateFormat('MMMM yyyy').parse(group.key);
              return [
                _buildDateSectionHeader(date),
                ...group.value.map(_buildRecordItem),
              ];
            }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Blood Pressure',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            )),
      ),
      body: Column(
        children: [
          _buildMonthNavigationHeader(),
          _buildBarChart(),
          _buildRecordList(),
        ],
      ),
    );
  }
}
