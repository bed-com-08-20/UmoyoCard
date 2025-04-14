import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:umoyocard/screens/profile/profile_screen.dart';
import 'package:umoyocard/screens/records/health_insights/blood_pressure_screen.dart';
import 'package:umoyocard/screens/records/health_insights/blood_sugar_screen.dart';
import 'package:umoyocard/screens/records/health_insights/body_weight_screen.dart';
import 'package:umoyocard/screens/records/record_screen.dart';
import 'package:umoyocard/screens/home/ocr_screen.dart';
import 'package:umoyocard/screens/home/qr_code_screen.dart';
import 'package:umoyocard/screens/records/timeline_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const HomeContent(),
    const RecordScreen(),
    const ProfileScreen(),
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
        automaticallyImplyLeading: true,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          'Home',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      )
          : null,
      drawer: _buildDrawer(context),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Colors.blue),
            child: const Text(
              'UmoyoCard Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics Dashboard'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/analytics_dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback),
            title: const Text('User Feedback'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/feedback');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  String? _displayName;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _displayName = user?.displayName ?? 'there';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hi $_displayName, welcome back!',
              style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Quick Links',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildQuickLinkCard(
                          context,
                          'Scan Health Passport',
                          Icons.image_search,
                              () => _handleQuickLinkTap(context, 'Scan Health Passport'),
                        ),
                        _buildQuickLinkCard(
                          context,
                          'Scan Barcode or QR Code',
                          Icons.qr_code_scanner,
                              () => _handleQuickLinkTap(context, 'Scan QR Code'),
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
                          'Body Weight',
                          Icons.scale,
                              () => _handleQuickLinkTap(context, 'Body Weight'),
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
      return Expanded(child: RecentTimelineCard(onTap: onTap));
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.blue, size: 30),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleQuickLinkTap(BuildContext context, String label) {
    if (label == 'Scan Health Passport') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => OCRScreen()));
    } else if (label == 'Scan QR Code') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BarcodeScannerScreen()));
    } else if (label == 'Recent Timeline') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => TimelineScreen()));
    } else if (label == 'Blood Pressure') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BloodPressureScreen()));
    } else if (label == 'Body Weight') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => WeightTrackingScreen()));
    } else if (label == 'Blood Sugar') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => BloodSugarScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feature for "$label" is not implemented yet.')),
      );
    }
  }
}

class RecentTimelineCard extends StatefulWidget {
  final VoidCallback? onTap;
  const RecentTimelineCard({super.key, this.onTap});

  @override
  _RecentTimelineCardState createState() => _RecentTimelineCardState();
}

class _RecentTimelineCardState extends State<RecentTimelineCard> {
  String _latestText = 'Loading...';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchLatestText();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _fetchLatestText());
  }

  Future<void> _fetchLatestText() async {
    final prefs = await SharedPreferences.getInstance();
    final texts = prefs.getStringList('savedTexts') ?? [];
    setState(() {
      _latestText = texts.isNotEmpty ? texts.last : 'No recent record';
    });
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
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Recent Timeline",
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _latestText,
              style: const TextStyle(fontSize: 12.0, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
