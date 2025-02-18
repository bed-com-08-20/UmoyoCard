import 'package:flutter/material.dart';
import 'package:umoyocard/screens/profile_screen.dart';
import 'package:umoyocard/screens/record_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static List<Widget> _widgetOptions = <Widget>[
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
              backgroundColor: Colors.white,
              elevation: 0,
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
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
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
}

class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Hi Wadi Mkweza, welcome back!',
              style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Quick Links',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            GridView.builder(
              shrinkWrap: true,
              itemCount: quickLinks.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final quickLink = quickLinks[index];
                return _QuickLinkCard(
                  icon: quickLink['icon'] as IconData,
                  label: quickLink['label'] as String,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickLinkCard({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 30, color: Colors.blue),
          const SizedBox(height: 8.0),
          Text(label, style: const TextStyle(fontSize: 14.0)),
        ],
      ),
    );
  }
}

const quickLinks = [
  {'icon': Icons.qr_code_scanner, 'label': 'Scan Health Passport'},
  {'icon': Icons.timeline, 'label': 'Recent Timeline'},
  {'icon': Icons.favorite, 'label': 'Blood Pressure'},
  {'icon': Icons.medical_services, 'label': 'Blood Sugar'},
  {'icon': Icons.monitor_heart, 'label': 'Heart Rate'},
  {'icon': Icons.accessibility, 'label': 'Weight (tikambirana izi)'},
];
