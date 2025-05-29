import 'dart:async';
import 'package:flutter/material.dart';
import 'package:umoyocard/screens/profile/profile_header.dart';
import 'package:umoyocard/screens/profile/profile_screen.dart';
import 'package:umoyocard/screens/records/health_insights/blood_pressure_screen.dart';
import 'package:umoyocard/screens/records/health_insights/blood_sugar_screen.dart';
import 'package:umoyocard/screens/records/record_screen.dart';
import 'package:umoyocard/screens/home/ocr_screen.dart';
import 'package:umoyocard/screens/records/timeline_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The main home screen of the application that serves as a navigation hub.
///
/// This screen implements a bottom navigation bar to switch between three main sections:
/// - Home (default view with quick links)
/// - Records (health data management)
/// - Profile (user settings and information)
///
/// Uses a [PageView] to handle smooth transitions between sections
class HomeScreen extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    RecordScreen(),
    ProfileScreen(),
  ];

  /// Handles navigation when a bottom navigation item is tapped
  ///
  /// @param index The index of the tapped item (0 for Home, 1 for Records, 2 for Profile)
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Builds an appropriate AppBar based on the currently selected section
  ///
  /// @return An [AppBar] configured for the current section with appropriate
  ///         title and actions (like profile header)
  AppBar _getAppBar() {
    String title = '';
    List<Widget> actions = [];

    switch (_selectedIndex) {
      case 0:
        title = 'Home';
        actions = const [
          ProfileHeader(),
          SizedBox(width: 10),
        ];
        break;
      case 1:
        title = 'Records';
        actions = const [
          ProfileHeader(),
          SizedBox(width: 10),
        ];
        break;
      case 2:
        title = 'Profile';

        break;
    }

    return AppBar(
      automaticallyImplyLeading: false,
      centerTitle: true,
      backgroundColor: Colors.teal, // Consistent background color
      elevation: 0, // Consistent elevation
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: actions, // Set actions based on the selected index
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _getAppBar(), // Use the common AppBar function
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: _buildIcon(Icons.home, 0), label: ''),
          BottomNavigationBarItem(
              icon: _buildIcon(Icons.category, 1), label: ''),
          BottomNavigationBarItem(icon: _buildIcon(Icons.person, 2), label: ''),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }

  /// Builds a custom icon for the bottom navigation bar
  ///
  /// @param iconData The icon to display
  /// @param index The index this icon represents
  /// @return A [Widget] containing the styled icon with appropriate label
  Widget _buildIcon(IconData iconData, int index) {
    bool isSelected = _selectedIndex == index;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: isSelected
              ? BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: Icon(
            iconData,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
        SizedBox(height: 2),
        Text(
          _getLabel(index),
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Gets the label text for a bottom navigation item
  ///
  /// @param index The index of the navigation item
  /// @return The appropriate label text for the given index
  String _getLabel(int index) {
    switch (index) {
      case 0:
        return 'Home';
      case 1:
        return 'Records';
      case 2:
        return 'Profile';
      default:
        return '';
    }
  }
}

/// The content widget for the Home section of the application
///
/// Displays a welcome message and quick links to various features:
/// - Scan Health Passport
/// - Recent Timeline
/// - Blood Pressure
/// - Blood Sugar
class HomeContent extends StatefulWidget {
  @override
  // ignore: library_private_types_in_public_api
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String userName = "User";

  @override
  void initState() {
    super.initState();
    _loadUserName(); // Load the user's name when the screen starts
  }

  // Fetch the user's name from SharedPreferences
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('userName') ?? "User";
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi $userName, welcome back!', // Dynamic name display
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8.0),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickLinkCard(
                          context,
                          'Scan Health Passport',
                          Icons.qr_code_scanner,
                          () => _handleQuickLinkTap(
                              context, 'Scan Health Passport'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickLinkCard(
                          context,
                          'Recent Timeline',
                          Icons.timeline,
                          () => _handleQuickLinkTap(context, 'Recent Timeline'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickLinkCard(
                          context,
                          'Blood Pressure',
                          Icons.favorite,
                          () => _handleQuickLinkTap(context, 'Blood Pressure'),
                        ),
                        _buildQuickLinkCard(
                          context,
                          'Blood Sugar',
                          Icons.medical_services,
                          () => _handleQuickLinkTap(context, 'Blood Sugar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card widget for a quick link
  ///
  /// @param context The build context
  /// @param title The title to display on the card
  /// @param icon The icon to display on the card
  /// @param onTap The callback when the card is tapped
  /// @return A [Widget] representing the quick link card
  Widget _buildQuickLinkCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    if (title == 'Recent Timeline') {
      return Expanded(
        child: RecentTimelineCard(
          onTap: onTap,
        ),
      );
    }
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 30),
              SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles navigation when a quick link is tapped
  ///
  /// @param context The build context
  /// @param label The label of the quick link that was tapped
  void _handleQuickLinkTap(BuildContext context, String label) {
    if (label == 'Scan Health Passport') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OCRScreen()),
      );
    } else if (label == 'Recent Timeline') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TimelineScreen()),
      );
    } else if (label == 'Blood Pressure') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BloodPressureScreen()),
      );
    } else if (label == 'Blood Sugar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BloodSugarScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feature for "$label" is not implemented yet.')),
      );
    }
  }
}

/// A card widget that displays the user's most recent hospital visit date
///
/// Automatically updates every 2 seconds to check for new visit data.
/// Extracts dates from saved text using pattern matching.
class RecentTimelineCard extends StatefulWidget {
  final VoidCallback? onTap;
  // ignore: use_super_parameters
  const RecentTimelineCard({Key? key, this.onTap}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _RecentTimelineCardState createState() => _RecentTimelineCardState();
}

class _RecentTimelineCardState extends State<RecentTimelineCard> {
  String _date = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLatestVisit();
    // Refresh every 2 seconds
    _timer = Timer.periodic(Duration(seconds: 2), (timer) {
      _fetchLatestVisit();
    });
  }

  /// Extracts a date string from the given text using pattern matching
  ///
  /// Supports multiple date formats including:
  /// - 13/01/2025 or 13-01-2025
  /// - 13/Jan/2025
  /// - 13 Jan 2025
  /// - Visit: 13/01/2025
  /// - Visit: 13/Jan/2025
  ///
  /// @param text The text to search for dates
  /// @return The extracted date string, or empty string if no date found
  String _extractDate(String text) {
    final datePattern = RegExp(
      r'(\b\d{1,2}\s*[/-]\s*\d{1,2}\s*[/-]\s*\d{2,4}\b)|' // 13 / 01 / 2025 or 13-01-2025
      r'(\b\d{1,2}\s*[/-]\s*(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*[/-]\s*\d{2,4}\b)|' // 13 / Jan / 2025
      r'(\b\d{1,2}\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{2,4}\b)|' // 13 Jan 2025
      r'(\b(?:Visit|Date)\s*[:.]?\s*(\d{1,2}\s*[/-]\s*\d{1,2}\s*[/-]\s*\d{2,4})\b)|' // Visit: 13 / 01 / 2025
      r'(\b(?:Visit|Date)\s*[:.]?\s*(\d{1,2}\s*[/-]\s*(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s*[/-]\s*\d{2,4})\b)', // Visit: 13 / Jan / 2025
      caseSensitive: false,
    );

    for (var match in datePattern.allMatches(text)) {
      for (var i = 1; i <= match.groupCount; i++) {
        if (match.group(i) != null) {
          // Clean up extra spaces around slashes
          return match.group(i)!.replaceAll(RegExp(r'\s*/\s*'), '/').trim();
        }
      }
    }

    return '';
  }

  Future<void> _fetchLatestVisit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> texts = prefs.getStringList('savedTexts') ?? [];

      if (texts.isNotEmpty) {
        final latestText = texts.last;
        final extractedDate = _extractDate(latestText);

        setState(() {
          _date = extractedDate;
        });

        await prefs.setString('latestVisitDate', _date);
      } else {
        setState(() {
          _date = '';
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching latest visit: $e');
      setState(() {
        _date = '';
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timeline, size: 20, color: Colors.blue),
                SizedBox(width: 5),
                Text(
                  "Latest Hospital Visit",
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            if (_date.isNotEmpty) ...[
              Text(
                "Here is your latest hospital visit:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 8.0),
              Text(
                _date,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ] else ...[
              Text(
                "No recent visits found",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
