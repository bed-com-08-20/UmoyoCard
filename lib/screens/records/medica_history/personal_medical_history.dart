import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PersonalMedicalHistoryScreen extends StatelessWidget {
  const PersonalMedicalHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Personal Medical History',
          style: TextStyle(color: Colors.blue),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            MedicalCard(
              title: 'Chronic illness',
              details: {
                'Name of condition': 'Diabetes, Hypertension',
                'Date Diagnosed': 'Diagnosed 2020',
                'Status': 'Ongoing',
                'Medications': 'Metformin, Insulin',
              },
            ),
            MedicalCard(
              title: 'Allergies',
              details: {
                'Allergen Name': 'Peanuts, Penicillin',
                'Reaction Type': 'Mild',
                'Last occurrence Date': '23/04/2025',
                'Treatment used': 'None',
              },
            ),
            MedicalCard(
              title: 'Surgery',
              details: {
                'Date Performed': '12/09/2023',
                'Hospital Name': 'Zomba central',
                'Complicated (if any)': 'None',
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Add Record'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.history),
                  label: const Text('View History'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MedicalCard extends StatelessWidget {
  final String title;
  final Map<String, String> details;

  const MedicalCard({
    Key? key,
    required this.title,
    required this.details,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...details.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
