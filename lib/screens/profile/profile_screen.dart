import 'package:flutter/material.dart';
import 'package:umoyocard/screens/login/login_screen.dart';
import 'package:umoyocard/screens/profile/change_password.dart';
import 'package:umoyocard/screens/profile/personal_information.dart';

class ProfileScreen extends StatelessWidget {
  // ignore: use_super_parameters
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Image and Name Section
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/profile_image.png'),
            ),
            const SizedBox(height: 8.0),
            const Text(
              'Harry Yamikani Peter',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),

            // Account & Settings Section
            _buildSectionTitle('Settings'),
            _buildListTile('Update Personal Information', Icons.person, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UpdatePersonalInfoScreen(),
                ),
              );
            }),
            _buildListTile('Change Password', Icons.lock, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            }),

            // Language Section
            _buildListTile('Language', Icons.language, () {}),

            // Help Section
            _buildSectionTitle('Need Help'),
            _buildListTile('Terms of Use', Icons.article, () {}),
            _buildListTile('Privacy Policy', Icons.privacy_tip, () {}),
            _buildListTile('Contact Us', Icons.contact_mail, () {}),
            _buildListTile('FAQ', Icons.help, () {}),
            _buildListTile('About UmoyoKhadi', Icons.info, () {}),

            const SizedBox(height: 16.0),

            // App Version
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 16.0),

            // Logout Button
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to the login screen upon logout
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Log out',
                  style: TextStyle(fontSize: 20, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildListTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16.0),
      onTap: onTap,
    );
  }
}
