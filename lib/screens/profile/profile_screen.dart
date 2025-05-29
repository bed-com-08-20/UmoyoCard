import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umoyocard/screens/info/about_screen.dart';
import 'package:umoyocard/screens/info/contact_us_screen.dart';
import 'package:umoyocard/screens/info/faq_screen.dart';
import 'package:umoyocard/screens/info/language_screen.dart';
import 'package:umoyocard/screens/info/privacy_policy_screen.dart';
import 'package:umoyocard/screens/info/terms_of_use_screen.dart';
import 'package:umoyocard/screens/login/login_screen.dart';
import 'package:umoyocard/screens/profile/change_password.dart';
import 'package:umoyocard/screens/profile/personal_information.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _loadUserName();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    String? imagePath = prefs.getString('profileImagePath');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String? userName = prefs.getString('userName');
    if (userName != null) {
      setState(() {
        _userName = userName;
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', pickedFile.path);
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImage != null
                    ? FileImage(_profileImage!)
                    : const AssetImage('assets/profile_image.png')
                        as ImageProvider,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              _userName.isNotEmpty ? _userName : 'Wadi Mkweza',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24.0),
            _buildSectionTitle('Settings'),
            _buildListTile('Update Personal Information', Icons.person, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UpdatePersonalInfoScreen()),
              );
            }),
            _buildListTile('Change Password', Icons.lock, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ChangePasswordScreen()),
              );
            }),
            _buildListTile('Language', Icons.language, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageScreen()),
              );
            }),
            _buildSectionTitle('Need Help?'),
            _buildListTile('Terms of Use', Icons.article, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TermsOfUseScreen()),
              );
            }),
            _buildListTile('Privacy Policy', Icons.privacy_tip, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen()),
              );
            }),
            _buildListTile('Contact Us', Icons.contact_mail, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ContactUsScreen()),
              );
            }),
            _buildListTile('FAQ', Icons.help, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FAQScreen()),
              );
            }),
            _buildListTile('About UmoyoCard', Icons.info, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            }),
            const SizedBox(height: 16.0),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16.0),
            Center(
              child: TextButton(
                onPressed: () {
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
