import 'package:flutter/material.dart';

import 'package:fl_chart/fl_chart.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class BloodSugarRecord {
  final double value;
  final DateTime date;
  final String status;
  final Color color;

  BloodSugarRecord({
    required this.value,
    required this.date,
    required this.status,
    required this.color,
  });

  // Convert BloodSugarRecord to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'date': date.toIso8601String(),
      'status': status,
      'color': color.value, // Store color as an integer value
    };
  }

  // Create BloodSugarRecord from Map
  factory BloodSugarRecord.fromMap(Map<String, dynamic> map) {
    return BloodSugarRecord(
      value: map['value'].toDouble(),
      date: DateTime.parse(map['date']),
      status: map['status'],
      color: Color(map['color']), // Recreate Color from integer value
    );
  }

  // Determine blood sugar status based on value (assuming mmol/L)
  static String getStatus(double value) {
    // Ranges based on typical mmol/L values
    if (value < 2.8) return 'Hypoglycemic (Low)';
    if (value >= 2.8 && value < 3.9) return 'Low';
    if (value >= 3.9 && value < 5.6) return 'Normal';
    if (value >= 5.6 && value < 7.0) return 'Prediabetes';
    if (value >= 7.0 && value <= 20.0)
      return 'Diabetes'; // Allow a wide range for 'Diabetes'
    if (value > 20.0) return 'Very High';
    return 'Unknown'; // Should not happen with validation, but good fallback
  }

  // Get color for blood sugar status
  static Color getColorForStatus(String status) {
    switch (status) {
      case 'Hypoglycemic (Low)':
        return Colors.red[900]!; // Very low
      case 'Low':
        return Colors.orange; // Below target range
      case 'Normal':
        return Colors.green; // Within target range
      case 'Prediabetes':
        return Colors.yellow[700]!; // Elevated but not yet diabetes
      case 'Diabetes':
        return Colors.red; // Elevated or high range
      case 'Very High':
        return Colors.purple[900]!; // Dangerously high
      default:
        return Colors.grey; // Unknown or not in standard range
    }
  }

  String get formattedDate {
    return DateFormat('dd MMM, HH:mm').format(date);
  }
}

class BloodSugarScreen extends StatefulWidget {
  const BloodSugarScreen({Key? key}) : super(key: key);

  @override
  _BloodSugarScreenState createState() => _BloodSugarScreenState();
}

class _BloodSugarScreenState extends State<BloodSugarScreen> {
  List<BloodSugarRecord> records = [];
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

  // Fetch blood sugar data from timeline texts in SharedPreferences
  Future<List<BloodSugarRecord>> fetchBloodSugarDataFromTimeline() async {
    final prefs = await SharedPreferences.getInstance();
    final timelineTexts = prefs.getStringList('savedTexts') ?? [];
    final timelineDates = prefs.getStringList('savedDates') ?? [];
    List<BloodSugarRecord> bloodSugarReadings = [];

    final bloodSugarRegex = RegExp(
      r'(?:blood[\s-]*sugar|sugar|glucose|blood[\s-]*glucose|BG|BGL|bs|blood sugar level|blood glucose level)\s*[:\-]?\s*(\d+[,.]?\d*)\s*(mg\s*\/?\s*dl|mmol\s*\/?\s*l|mg|mmol|l)?',
      caseSensitive: false,
    );
    // final bloodSugarRegex = RegExp(
    //   r'(?:blood[\s-]*sugar|sugar|glucose|blood[\s-]*glucose|BG|BGL|bs|blood sugar level|blood glucose level|RBS)\s*[=:\-]\s*(\d+[,.]?\d*)\s*(mg\s*\/?\s*dl|mmol\s*\/?\s*l|mg|mmol|l)?',
    //   caseSensitive: false,
    // );
    // final bloodSugarRegex = RegExp(
    //   r'(?:blood[\s-]*sugar|sugar|glucose|blood[\s-]*glucose|BG|BGL|bs|blood sugar level|blood glucose level|RBS)\s*(?:[=:\-]*\s*)?(\d+[,.]?\d*)\s*(mg\s*\/?\s*dl|mmol\s*\/?\s*l|mg|mmol|l)?',
    //   caseSensitive: false,
    // );
    // final bloodSugarRegex = RegExp(
    //   r'(?:blood[\s-]*sugar|sugar|glucose|blood[\s-]*glucose|BG|BGL|bs|blood sugar level|blood glucose level|RBS)\s*[:\-]?\s*(\d+[,.]?\d*)\s*(mg\s*\/?\s*dl|mmol\s*\/?\s*l|mg|mmol|l)?',
    //   caseSensitive: false,
    // );

    for (int i = 0; i < timelineTexts.length; i++) {
      final text = timelineTexts[i];
      final match = bloodSugarRegex.firstMatch(text);

      if (i < timelineDates.length && match != null) {
        final dateString = timelineDates[i];
        DateTime? recordDate;
        try {
          recordDate = DateTime.parse(dateString);
        } catch (e) {
          print('Error parsing date "$dateString": $e');
          continue;
        }

        final valueStr = match.group(1);
        final unitStr = match.group(2);

        if (valueStr != null) {
          double? value = double.tryParse(valueStr.replaceAll(',', '.'));

          if (value != null) {
            bool isMgdl = false;
            if (unitStr != null) {
              final lowerUnit = unitStr.toLowerCase();
              if (lowerUnit.contains('mg') && lowerUnit.contains('dl')) {
                isMgdl = true;
              } else if (lowerUnit == 'mg') {
                if (value > 20) isMgdl = true;
              }
            } else {
              if (value > 40) isMgdl = true;
            }

            if (isMgdl) {
              value = value / 18.0;
            }

            if (value < 0.5 || value > 40.0) {
              print('Skipping implausible blood sugar value: $value (mmol/L)');
              continue;
            }

            final status = BloodSugarRecord.getStatus(value);
            final color = BloodSugarRecord.getColorForStatus(status);

            bloodSugarReadings.add(BloodSugarRecord(
              value: double.parse(value.toStringAsFixed(1)),
              date: recordDate,
              status: status,
              color: color,
            ));
          }
        }
      }
    }
    return bloodSugarReadings;
  }

  // Load initial data when the screen starts
  Future<void> _loadInitialData() async {
    final timelineData = await fetchBloodSugarDataFromTimeline();
    setState(() {
      records = timelineData;
      // Sort records by date, newest first
      records.sort((a, b) => b.date.compareTo(a.date));
      _updateAvailableMonths();
    });
  }

  // Update the list of available months for search suggestions
  void _updateAvailableMonths() {
    final months = <String>{};
    for (final record in records) {
      final monthYear = DateFormat('MMMM yyyy').format(record.date);
      months.add(monthYear);
    }
    setState(() {
      // Sort months in reverse chronological order
      _availableMonths = months.toList()..sort(_compareMonths);
    });
  }

  // Helper function to compare month strings for sorting
  int _compareMonths(String a, String b) {
    try {
      final dateA = DateFormat('MMMM yyyy').parse(a);
      final dateB = DateFormat('MMMM yyyy').parse(b);
      return dateB.compareTo(dateA);
    } catch (e) {
      return 0; // In case of parsing error, maintain original order
    }
  }

  // Listener for the search input field
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

    // Show month suggestions if query is not empty
    setState(() {
      _showMonthSuggestions = true;
      _showSearchResults = false; // Hide search results when typing
    });

    // Check if the query exactly matches an available month
    bool exactMatch =
        _availableMonths.any((month) => month.toLowerCase() == query);

    if (exactMatch) {
      // If there's an exact match, perform the search
      _performSearch(query);
      setState(() {
        _showMonthSuggestions =
            false; // Hide suggestions after selecting an exact match
      });
    }
    // If no exact match, suggestions remain visible showing all available months
  }

  // Perform search based on the entered month/year
  void _performSearch(String monthYear) {
    final results = <int>[];
    // Iterate through all records and find those matching the month/year
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

    // Sort search results by date, newest first
    results.sort((a, b) => records[b].date.compareTo(records[a].date));

    setState(() {
      _searchResults = results;
      _showSearchResults = true; // Show search results
      _showMonthSuggestions = false; // Hide month suggestions
    });
  }

  // Build the search input and month suggestions header
  Widget _buildMonthNavigationHeader() {
    // Always show all available months when search is not empty
    final List<String> monthSuggestions = _searchController.text.isNotEmpty
        ? _availableMonths
        : []; // Show nothing if search is empty

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
                        _searchController.clear(); // Clear search text
                      },
                    )
                  : null,
            ),
          ),
          // Show month suggestions dropdown if typing and suggestions are available
          if (_showMonthSuggestions && monthSuggestions.isNotEmpty)
            Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(4.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 150, // Limit height of suggestion box
                  minWidth: double.infinity,
                ),
                child: ListView.builder(
                  shrinkWrap: true, // Make ListView only take needed space
                  itemCount: monthSuggestions.length,
                  itemBuilder: (context, index) {
                    final month = monthSuggestions[index];
                    return ListTile(
                      title: Text(month),
                      dense: true, // Compact list tile
                      onTap: () {
                        // When a suggestion is tapped, set the search text and perform search
                        _searchController.text = month;
                        // Place cursor at the end of the text
                        _searchController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _searchController.text.length),
                        );
                        _performSearch(month);
                        setState(() {
                          _showMonthSuggestions = false; // Hide suggestions
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

  // Build the bar chart for blood sugar overview - Matching the original BP chart structure
  Widget _buildBarChart() {
    // Display records are either search results or all records
    final displayRecords = _showSearchResults
        ? _searchResults.map((index) => records[index]).toList()
        : records;

    // Show a message if there are no records to display
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
                : "No blood sugar data available",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Note: This chart uses fixed height and does not calculate maxY or dynamic width,
    // mirroring the BloodPressureScreen chart structure as requested.
    // This means bars might overlap or be very thin if there are many records.

    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Color(0xFFE6F4EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _showSearchResults
                ? "Search Results Overview"
                : "Blood Sugar Overview",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180, // Fixed height as in BloodPressureScreen
            // Width will be constrained by the parent container/screen width
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                minY: 0,
                // MaxY is NOT set here, allowing fl_chart to determine it automatically,
                // mirroring the provided BloodPressureScreen chart logic.
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
                      // Show index + 1 for clarity on the bottom axis
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
                      'Blood Sugar (mmol/L)', // Unit adjusted for blood sugar
                      style: TextStyle(fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    axisNameSize: 30,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        // Format Y-axis labels (e.g., to one decimal place)
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                  // Hide right and top titles
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true), // Show chart borders
                gridData: FlGridData(show: true), // Show grid lines
                barGroups: displayRecords.asMap().entries.map((entry) {
                  int index = entry.key;
                  BloodSugarRecord record = entry.value;
                  return BarChartGroupData(
                    x: index, // X value is the index of the record
                    barRods: [
                      BarChartRodData(
                        toY: record.value, // Y value is the blood sugar value
                        color: record.color, // Use the record's color
                        width: 10, // Width of the bar
                      )
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build the header for each date section in the list
  Widget _buildDateSectionHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 16),
      child: Row(
        children: [
          // Small colored line indicating the month
          Container(
            width: 2,
            height: 24,
            color: _getMonthColor(date), // Get a color based on the month
          ),
          const SizedBox(width: 16),
          // Text for the month and year
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

  // Helper function to get a consistent color for each month
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
    // Month is 1-indexed, so subtract 1 for list index
    return colors[date.month - 1];
  }

  // Build a single list item for a blood sugar record
  Widget _buildRecordItem(BloodSugarRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2.0, // Add a slight shadow to cards
      child: ListTile(
        // Leading circle avatar with the status color
        leading: CircleAvatar(
          backgroundColor: record.color,
          radius: 12, // Smaller radius for subtle indicator
        ),
        // Title showing the blood sugar value and unit
        title: Text(
            "${record.value.toStringAsFixed(1)} mmol/L"), // Display value with one decimal
        // Subtitle showing the status and formatted date/time
        subtitle: Text("${record.status}\n${record.formattedDate}"),
      ),
    );
  }

  // Build the list of blood sugar records
  Widget _buildRecordList() {
    // Show a message if there are no records
    if (records.isEmpty && !_showSearchResults) {
      return Expanded(
        child: Center(
          child: Text(
            "No blood sugar records available",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // If search results are shown and there are no results
    if (_showSearchResults && _searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            "No results found for '${_searchController.text}'",
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    // Group records by month/year if not showing search results
    final Map<String, List<BloodSugarRecord>> groupedRecords = {};
    if (!_showSearchResults) {
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
            return 0; // Maintain order on error
          }
        });

      // Build the list with grouped sections
      return Expanded(
        child: ListView(
          children: [
            ...sortedGroups.expand((group) {
              DateTime date;
              try {
                date = DateFormat('MMMM yyyy').parse(group.key);
              } catch (e) {
                // Handle parsing error for group key date
                print('Error parsing group key date: ${group.key}, Error: $e');
                // Use a default date or skip the group if necessary
                date = DateTime.now();
              }
              return [
                _buildDateSectionHeader(date), // Section header for the month
                ...group.value.map(
                    _buildRecordItem), // List items for records in this month
              ];
            }),
          ],
        ),
      );
    } else {
      return Expanded(
        child: ListView.builder(
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final recordIndex = _searchResults[index];
            return _buildRecordItem(records[recordIndex]);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Blood Sugar',
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
