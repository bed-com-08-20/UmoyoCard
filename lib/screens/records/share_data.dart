import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/login/patient_details.dart';
import 'package:umoyocard/services/fhir_service.dart';

/// A screen for selecting and sharing medical timeline entries with a FHIR server.
///
/// This screen allows users to:
/// - View their medical timeline entries grouped by month
/// - Search entries by month/year
/// - Select multiple entries for sharing
/// - Send selected entries to a FHIR server
/// - View patient details
class SharedDataRecord extends StatefulWidget {
  const SharedDataRecord({super.key});

  @override
  State<SharedDataRecord> createState() => _SharedDataRecordState();
}

/// The state class for [SharedDataRecord].
///
/// Manages:
/// - Loading and displaying timeline entries
/// - Search functionality
/// - Selection of multiple entries
/// - Sending data to FHIR server
class _SharedDataRecordState extends State<SharedDataRecord> {
  List<String> savedTexts = [];
  List<String> savedImages = [];
  List<String> savedDates = [];
  Set<int> _selectedIndices = {}; // To keep track of MULTIPLE selected items

  // --- State variables from TimelineScreen  ---
  final TextEditingController _searchController = TextEditingController();
  List<String> _availableMonths = [];
  bool _showSearchResults = false;
  List<int> _searchResults = []; // Stores original indices of search results
  bool _showMonthSuggestions = false;

  String? _currentPatientId;

  @override
  void initState() {
    super.initState();
    _loadTimelineData();
    _searchController.addListener(_onSearchChanged);
    _loadPatientId();
  }

  Future<void> _loadPatientId() async {
    final id = await FHIRService.getPatientId();
    setState(() {
      _currentPatientId = id;
    });
  }

  @override
  void dispose() {
    _searchController.dispose(); // Dispose controller
    super.dispose();
  }

  /// Loads timeline data from SharedPreferences and initializes the view.
  ///
  /// This method:
  /// - Loads saved texts, images and dates
  /// - Ensures dates exist for all entries
  /// - Extracts available months for searching
  /// - Resets search and selection state
  Future<void> _loadTimelineData() async {
    final prefs = await SharedPreferences.getInstance();
    savedTexts = prefs.getStringList('savedTexts') ?? [];
    savedImages = prefs.getStringList('savedImages') ?? [];
    savedDates = prefs.getStringList('savedDates') ?? [];

    if (savedDates.length < savedTexts.length) {
      final missingDates = savedTexts.length - savedDates.length;
      savedDates.addAll(List.generate(
          missingDates, (index) => DateTime.now().toIso8601String()));
    }

    final months = <String>{};
    for (final dateStr in savedDates) {
      try {
        final date = DateTime.parse(dateStr);
        months.add(DateFormat('MMMM yyyy').format(date));
      } catch (e) {
        // ignore: avoid_print
        print('Error parsing date: $dateStr, Error: $e');
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
          // ignore: avoid_print
          print('Error parsing month year for sorting: $a, $b, Error: $e');
          return 0;
        }
      });

    // Reset selection and search state on reload
    setState(() {
      _selectedIndices.clear(); // --- Clear the Set ---
      _showSearchResults = false;
      _showMonthSuggestions = false;
      _searchController.clear();
      _searchResults.clear(); // Also clear search results on reload
    });
  }

  /// Handles changes to the search input field.
  ///
  /// This method:
  /// - Clears search results when query is empty
  /// - Shows month suggestions as user types
  /// - Triggers search when exact month match is entered
  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _showMonthSuggestions = false; // Hide suggestions when empty
        _searchResults.clear();
        _selectedIndices.clear(); // Clear selection when search cleared
      });
      return;
    }

    setState(() {
      _showMonthSuggestions = true;
    });

    // Check if the query exactly matches an available month/year for triggering a search
    bool exactMatch =
        _availableMonths.any((month) => month.toLowerCase() == query);

    if (exactMatch) {
      _performSearch(query);
      setState(() {
        _showMonthSuggestions =
            false; // Hide suggestions after performing search
      });
    } else {
      // If not an exact match, keep showing suggestions (handled above)
      setState(() {
        _showSearchResults = false; // Hide previous search results if typing
      });
    }
  }

  void _performSearch(String monthYear) {
    final results = <int>[];
    for (int i = 0; i < savedDates.length; i++) {
      if (i >= savedDates.length) continue;
      try {
        final date = DateTime.parse(savedDates[i]);
        final formattedDate = DateFormat('MMMM yyyy').format(date);
        if (formattedDate.toLowerCase() == monthYear.toLowerCase()) {
          results.add(i);
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error parsing date during search: ${savedDates[i]}, Error: $e');
        continue;
      }
    }

    results.sort((a, b) {
      try {
        final dateA = DateTime.parse(savedDates[a]);
        final dateB = DateTime.parse(savedDates[b]);
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    setState(() {
      _searchResults = results;
      _showSearchResults = true;
      _showMonthSuggestions = false; // Hide suggestions after search
      _selectedIndices
          .clear(); // --- Clear selection when search results change ---
    });
  }

  /// Sends selected timeline entries to the FHIR server.
  ///
  /// This method:
  /// - Shows error if no items selected
  /// - Displays confirmation dialog
  /// - Sends each selected item to FHIR
  /// - Provides progress feedback via SnackBars
  /// - Shows final success/failure summary
  Future<void> _sendSelectedItemsToFHIR() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please select one or more timeline entries to share')),
      );
      return;
    }

    final itemsToSend = Set<int>.from(
        _selectedIndices); // Copy indices to avoid issues if state changes mid-send
    final count = itemsToSend.length;
    final itemS = count == 1 ? "entry" : "entries";

    // Show confirmation dialog
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Share ($count $itemS)'),
          content: Text(
              'Do you want to share the selected $count $itemS with the FHIR server?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false), // Return false
            ),
            TextButton(
              child: const Text('Share All'),
              onPressed: () => Navigator.of(context).pop(true), // Return true
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      // ignore: avoid_print
      print("Sharing cancelled by user.");
      return;
    }

    // Proceed with sending
    int successCount = 0;
    int failureCount = 0;
    bool firstError = true;

    // Show initial sending message
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text('Sharing $count $itemS...'),
          duration: Duration(seconds: count + 2)),
    );

    await Future.forEach(itemsToSend, (int index) async {
      if (index < 0 || index >= savedTexts.length) {
        // ignore: avoid_print
        print('Skipping invalid index $index during send.');
        failureCount++;
        return;
      }
      try {
        final text = savedTexts[index];
        final image =
            (index < savedImages.length && savedImages[index].isNotEmpty)
                ? savedImages[index]
                : '';

        // ignore: avoid_print
        print('Attempting to send item index: $index'); // Debug log

        await FHIRService.sendDocumentToFHIR(
          documentText: text,
          imagePath: image,
          // ignore: use_build_context_synchronously
          context:
              context, // Pass context if service needs it for feedback (it currently does)
        );
        print('Successfully processed item index: $index');
        successCount++;
      } catch (e) {
        print('Failed to send item index $index: $e');
        failureCount++;
        // Optionally show an error immediately, but could be overwhelming
        if (firstError) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(content: Text('Error sending item (index $index): $e'), backgroundColor: Colors.red),
          // );
          firstError =
              false; // Only show detailed error for the first failure maybe
        }
      }
    });

    // Show final status update
    String finalMessage;
    Color feedbackColor = Colors.green;

    if (failureCount == 0 && successCount > 0) {
      finalMessage = 'Successfully shared $successCount $itemS.';
    } else if (successCount > 0 && failureCount > 0) {
      final itemFS = failureCount == 1 ? 'item' : 'items';
      finalMessage =
          'Shared $successCount $itemS, but $failureCount $itemFS failed.';
      feedbackColor = Colors.orange;
    } else if (successCount == 0 && failureCount > 0) {
      final itemFS = failureCount == 1 ? 'item' : 'items';
      finalMessage = 'Failed to share $failureCount $itemFS.';
      feedbackColor = Colors.red;
    } else {
      finalMessage =
          'No items were processed.'; // Should not happen if initial check passes
      feedbackColor = Colors.grey;
    }

    if (mounted) {
      // Check if the widget is still in the tree
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(finalMessage), backgroundColor: feedbackColor),
      );
      // Clear selection after attempting to send all
      setState(() {
        _selectedIndices.clear();
      });
    }
  }
  // --- End Send to FHIR ---

  void _showFullImage(String imagePath) {
    if (imagePath.isEmpty) return;
    try {
      File imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image file not found.')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Full Image'),
              backgroundColor: Colors.teal,
              iconTheme: const IconThemeData(color: Colors.white),
              titleTextStyle:
                  const TextStyle(color: Colors.white, fontSize: 20),
            ),
            body: Center(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.file(imageFile),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading image: $e')),
      );
    }
  }

  /// Builds a single timeline entry widget.
  ///
  /// Parameters:
  /// - [index]: The index of the timeline entry to build
  ///
  /// Returns:
  /// - A widget displaying the timeline entry with:
  ///   - Checkbox for selection
  ///   - Date/time
  ///   - Entry text
  ///   - Thumbnail image (if available)
  ///   - Visual styling based on selection state
  Widget _buildTimelineItem(int index) {
    if (index < 0 || index >= savedDates.length) {
      return const SizedBox.shrink();
    }
    final hasText = index < savedTexts.length && savedTexts[index].isNotEmpty;
    final hasImage =
        index < savedImages.length && savedImages[index].isNotEmpty;
    final dateStr = savedDates[index];
    DateTime? date;
    try {
      date = DateTime.parse(dateStr).toLocal();
    } catch (e) {
      print("Error parsing date for item $index: $dateStr");
    }
    if (!hasText && !hasImage && date == null) return const SizedBox.shrink();

    // --- Check if this index is in the selected Set ---
    final bool isSelected = _selectedIndices.contains(index);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Stretch children to match height
        children: [
          // --- Timeline Indicator Line ---
          Padding(
            padding: const EdgeInsets.only(
                left: 8.0, right: 8.0), // Adjust padding for line
            child: Container(
              width: 2,
              // Height is determined by the intrinsic height of the row
              color: _getMonthColor(date ?? DateTime.now()),
            ),
          ),
          // --- End Timeline Indicator Line ---
          Expanded(
            child: Card(
              elevation: isSelected ? 4 : 2, // Subtle elevation change
              shape: RoundedRectangleBorder(
                side: BorderSide(
                    color:
                        isSelected ? Colors.teal.shade400 : Colors.transparent,
                    width: 2.0), // More prominent border when selected
                borderRadius:
                    BorderRadius.circular(8.0), // Slightly rounded corners
              ),
              margin: const EdgeInsets.only(
                  bottom: 12.0), // Increased bottom margin
              color: Color(0xFFF3E5F5),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedIndices.add(index);
                          } else {
                            _selectedIndices.remove(index);
                          }
                        });
                      },
                      activeColor:
                          Colors.teal.shade600, // Darker teal when checked
                      checkColor: Colors.white, // White checkmark
                      side: BorderSide(
                          color: Colors.grey.shade500,
                          width: 1.5), // Border for unchecked
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap, // Reduce tap area
                    ),
                    const SizedBox(
                        width: 8.0), // Space between checkbox and content
                    // --- Content (Date, Text, Image) ---
                    Expanded(
                      // Content takes remaining space
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (date != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                DateFormat('dd MMM yyyy - HH:mm').format(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[
                                      700], // Slightly darker grey for date
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          if (!hasText && !hasImage && date == null)
                            const Text("Invalid entry data",
                                style: TextStyle(color: Colors.red)),
                          if (hasText)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              // --- Apply color style if selected ---
                              child: Text(savedTexts[index],
                                  style: TextStyle(
                                      fontSize: 14.0,
                                      color: isSelected
                                          ? Colors.teal.shade800
                                          : Colors
                                              .black87, // Teal color if selected
                                      fontWeight: isSelected
                                          ? FontWeight.w500
                                          : FontWeight
                                              .normal // Optionally bold if selected
                                      )),
                            ),
                          if (hasImage)
                            GestureDetector(
                              onTap: () => _showFullImage(savedImages[index]),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4.0),
                                child: Image.file(
                                  File(savedImages[index]),
                                  fit: BoxFit.contain,
                                  height: 100,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 100,
                                      color: Colors.grey[200],
                                      alignment: Alignment.center,
                                      child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.broken_image,
                                                color: Colors.grey),
                                            SizedBox(height: 4),
                                            Text("Image Error",
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey))
                                          ]),
                                    );
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // --- End Content ---
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // --- End Build Timeline Item ---

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

  List<int> _getAllRecordsSorted() {
    if (savedDates.isEmpty) return [];
    List<int> indices = List.generate(savedDates.length, (index) => index);
    indices.sort((a, b) {
      try {
        final dateA = DateTime.parse(savedDates[a]);
        final dateB = DateTime.parse(savedDates[b]);
        return dateB.compareTo(dateA);
      } catch (e) {
        print(
            'Error comparing dates for sorting: ${savedDates[a]}, ${savedDates[b]}, Error: $e');
        return 0;
      }
    });
    return indices;
  }

  /// Builds the search header widget with month suggestions.
  ///
  /// Returns:
  /// - A widget containing:
  ///   - Title
  ///   - Search field
  ///   - Month suggestions (when typing)
  Widget _buildMonthNavigationHeader() {
    // --- MODIFIED: Suggestions show all available months if search is not empty ---
// Show all if search is empty

    final List<String> displaySuggestions = _searchController.text.isNotEmpty
        ? _availableMonths // If input is not empty, show ALL available months
        : []; // If input is empty, show no suggestions

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Column(
        children: [
          const Text(
            'Select Entries to Share', // Updated Title
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by month (e.g. "April 2025")',
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
                        // _onSearchChanged will handle state updates
                      },
                    )
                  : null,
            ),
          ),
          // --- Suggestions Box ---
          if (_showMonthSuggestions && displaySuggestions.isNotEmpty)
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
                  itemCount: displaySuggestions.length,
                  itemBuilder: (context, index) {
                    final month = displaySuggestions[index];
                    return ListTile(
                      title: Text(month),
                      dense: true,
                      onTap: () {
                        _searchController.text = month;
                        _searchController.selection =
                            TextSelection.fromPosition(
                          TextPosition(offset: _searchController.text.length),
                        );
                        // --- Trigger search immediately on suggestion tap ---
                        _performSearch(month);
                        // --- Hide suggestions after tap ---
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

  /// Builds a header for a month section with select/deselect all functionality.
  ///
  /// Parameters:
  /// - [date]: The date representing the month/year
  /// - [monthIndices]: List of indices belonging to this month
  ///
  /// Returns:
  /// - A widget displaying the month header with select/deselect all button
  Widget _buildDateSectionHeader(DateTime date, List<int> monthIndices) {
    // Check if all items in this month are already selected
    final bool allSelected = monthIndices.isNotEmpty &&
        monthIndices.every((index) => _selectedIndices.contains(index));

    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0, left: 0),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 24,
            color: _getMonthColor(date),
          ),
          const SizedBox(width: 16),
          Expanded(
            // Allow text to take available space
            child: Text(
              DateFormat('MMMM yyyy').format(date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
          ),
          // --- Select/Deselect All Button for the Month ---
          TextButton(
            onPressed: monthIndices.isEmpty
                ? null
                : () {
                    // Disable if no items
                    setState(() {
                      if (allSelected) {
                        // If all are selected, deselect them
                        _selectedIndices.removeAll(monthIndices);
                      } else {
                        // Otherwise, select all
                        _selectedIndices.addAll(monthIndices);
                      }
                    });
                  },
            child: Text(
              allSelected ? 'Deselect All' : 'Select All',
              style: const TextStyle(fontSize: 12, color: Colors.teal),
            ),
          )
          // --- End Select/Deselect Button ---
        ],
      ),
    );
  }
  // --- End Build Date Section Header ---

  @override
  Widget build(BuildContext context) {
    final allRecordsIndicesSorted = _getAllRecordsSorted();

    Map<String, List<int>> groupedEntries = {};
    if (!_showSearchResults) {
      for (int index in allRecordsIndicesSorted) {
        if (index >= 0 && index < savedDates.length) {
          try {
            final date = DateTime.parse(savedDates[index]);
            final monthYear = DateFormat('MMMM yyyy').format(date);
            groupedEntries.putIfAbsent(monthYear, () => []).add(index);
          } catch (e) {
            // ignore: avoid_print
            print("Error grouping entry with index $index: $e");
            continue;
          }
        }
      }
    }

    // Determine if the "Select All Results" button should be shown
    bool showSelectAllResultsButton =
        _showSearchResults && _searchResults.isNotEmpty;
    bool allSearchResultsSelected = showSelectAllResultsButton &&
        _searchResults.every((index) => _selectedIndices.contains(index));

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          // --- Show selection count in AppBar ---
          _selectedIndices.isEmpty
              ? 'Share Data'
              : '${_selectedIndices.length} Selected',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // Patient details button moved to actions
          IconButton(
            icon: _currentPatientId == null
                ? const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                : const Icon(Icons.remove_red_eye),
            tooltip: 'View Patient Details',
            onPressed: _currentPatientId == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PatientDetailsScreen(
                          // USING THE DYNAMIC ID HERE
                          patientId: _currentPatientId!,
                        ),
                      ),
                    );
                  },
          ),
          // --- Add a Clear Selection button to AppBar ---
          if (_selectedIndices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Selection',
              onPressed: () {
                setState(() {
                  _selectedIndices.clear();
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildMonthNavigationHeader(),

            // --- Header for Search Results (with Select All button) ---
            if (_showSearchResults &&
                _searchResults
                    .isNotEmpty) // Only show header if there are search results
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Search Results (${_searchResults.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (allSearchResultsSelected) {
                            _selectedIndices.removeAll(_searchResults);
                          } else {
                            _selectedIndices.addAll(_searchResults);
                          }
                        });
                      },
                      child: Text(
                          allSearchResultsSelected
                              ? 'Deselect All'
                              : 'Select All',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.teal)),
                    )
                  ],
                ),
              ),
            if (_showSearchResults &&
                _searchResults.isEmpty) // Message for no search results
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                    child: Text('No results found.')), // Simplified message
              ),
            // --- End Search Results Header ---

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadTimelineData,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  children: [
                    if (_showSearchResults)
                      // --- Display Search Results ---
                      ..._searchResults
                          .map((index) => _buildTimelineItem(index))
                          // ignore: unnecessary_to_list_in_spreads
                          .toList()
                    else
                    // --- Display Grouped Entries (Default View) ---
                    if (groupedEntries.isEmpty && savedTexts.isEmpty)
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text('No entries found.')))
                    else if (groupedEntries.isEmpty &&
                        savedTexts.isNotEmpty) // Case for error in grouping
                      const Center(
                          child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Text(
                                  'Error displaying entries. Pull to refresh.')))
                    else
                      ...groupedEntries.entries.map((entry) {
                        entry.value.sort((a, b) {
                          try {
                            final dateA = DateTime.parse(savedDates[a]);
                            final dateB = DateTime.parse(savedDates[b]);
                            return dateB.compareTo(dateA);
                          } catch (e) {
                            return 0;
                          }
                        });

                        try {
                          if (entry.value.isEmpty)
                            // ignore: curly_braces_in_flow_control_structures
                            return const SizedBox.shrink();
                          final date =
                              DateTime.parse(savedDates[entry.value.first]);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // --- Pass month indices to header ---
                              _buildDateSectionHeader(date, entry.value),
                              ...entry.value
                                  .map((index) => _buildTimelineItem(index))
                                  // ignore: unnecessary_to_list_in_spreads
                                  .toList(),
                            ],
                          );
                        } catch (e) {
                          // ignore: avoid_print
                          print("Error building section for ${entry.key}: $e");
                          return const SizedBox.shrink();
                        }
                      }).toList(),
                  ],
                ),
              ),
            ),

            if (_selectedIndices
                .isNotEmpty) // Show button only when items are selected
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    // Use ElevatedButton.icon
                    icon: const Icon(Icons.share, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    // --- Call the modified send function ---
                    onPressed: _sendSelectedItemsToFHIR,
                    label: Text(
                      // --- Update button text based on selection count ---
                      'Send ${_selectedIndices.length} Selected ${_selectedIndices.length == 1 ? "Item" : "Items"} to FHIR',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              )
            else // Show hint text when nothing is selected
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 24.0, horizontal: 16.0),
                child: Text(
                  savedTexts.isEmpty
                      ? 'No entries found to share.'
                      : 'Use checkboxes to select one or more entries for sharing.', // Updated hint
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.teal[600], fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
