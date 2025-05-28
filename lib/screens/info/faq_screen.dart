import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.teal,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Frequently Asked Questions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildFAQItem(
              question: 'How do I scan my health passport?',
              answer:
                  'Go to the Scan section in the app and point your camera at the QR code or barcode on your health passport. The app will automatically detect and process it.',
            ),
            _buildFAQItem(
              question: 'Where is my health data stored?',
              answer:
                  'Your health data is stored securely on your device. You can choose to share specific records with healthcare providers through FHIR servers.',
            ),
            _buildFAQItem(
              question: 'What is FHIR and how does it work with UmoyoCard?',
              answer:
                  'FHIR (Fast Healthcare Interoperability Resources) is a standard for healthcare data exchange. UmoyoCard can share your health records with authorized FHIR servers when you give permission.',
            ),
            _buildFAQItem(
              question: 'How does the predictive analytics feature work?',
              answer:
                  'Our predictive analytics uses anonymized, aggregated data patterns to provide insights about potential health trends. These are not medical diagnoses but may help you identify areas to discuss with your doctor.',
            ),
            _buildFAQItem(
              question: 'How do I update my personal information?',
              answer:
                  'Go to your Profile, then select "Update Personal Information" to edit your details.',
            ),
            _buildFAQItem(
              question: 'Is my data secure?',
              answer:
                  'Yes, we use industry-standard encryption and security measures to protect your data. You can read more in our Privacy Policy.',
            ),
            _buildFAQItem(
              question: 'How do I delete my account?',
              answer:
                  'Go to your Profile, then select "Privacy Settings" where you will find the option to delete your account and all associated data.',
            ),
            const SizedBox(height: 20),
            const Text(
              "Don't see your question? Contact us through the Contact Us page.",
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(answer),
        ),
      ],
    );
  }
}
