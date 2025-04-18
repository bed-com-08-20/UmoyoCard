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

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    HomeContent(),
    RecordScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
              backgroundColor: Colors.teal,
              elevation: 0,
              title: Text(
                'Home',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              actions: const [
                ProfileHeader(),
                SizedBox(width: 10),
              ],
            )
          : null,
      body: _widgetOptions.elementAt(_selectedIndex),
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

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi Wadi Mkweza, welcome back!',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Text(
              'Quick Links',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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

class RecentTimelineCard extends StatefulWidget {
  final VoidCallback? onTap;
  const RecentTimelineCard({Key? key, this.onTap}) : super(key: key);

  @override
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 20, color: Colors.blue),
                SizedBox(width: 5),
                Text(
                  "Latest Visit",
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.0),
            Text(
              _date.isNotEmpty
                  ? "Here is your latest hospital visit:\n$_date"
                  : "No recent visits found",
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
