import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/widgets.dart' as pw;

class FHIRService {
  static const String _fhirServerBaseUrl = 'http://localhost:8080/fhir';

  static Future<String?> getPatientId({bool keepPrefix = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString('userId');

      if (id == null) return null;

      // Remove 'pat-' prefix unless explicitly requested to keep it
      return id.replaceFirst('pat-', '');
    } catch (e) {
      debugPrint('Error getting patient ID: $e');
      return null;
    }
  }

  static Future<void> sendDocumentToFHIR({
    required String documentText,
    required String imagePath,
    required BuildContext context,
  }) async {
    try {
      // 1. Get and validate patient data
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final userName = prefs.getString('userName') ?? 'Unknown User';
      final now = DateTime.now().toUtc().toIso8601String();

      // Validate ID
      if (userId == null) {
        throw Exception(
            'Patient ID not found. Please create an account first.');
      }

      if (!_isValidFhirPatientId(userId)) {
        throw Exception(
            'Invalid patient ID format. Please log out and create a new account.');
      }

      debugPrint('Preparing document for patient: $userName (ID: $userId)');

      // 2. Create PDF
      final pdfBase64 = await _createSimplePdf(documentText, imagePath);

      // 3. Prepare FHIR resources
      final patient = _createPatientResource(userId, userName, prefs);
      final documentRef =
          _createDocumentReference(userId, userName, now, pdfBase64);

      // 4. Create/update patient
      await _createOrUpdateFhirResource('Patient', userId, patient);

      // 5. Create document reference
      await _createFhirResource('DocumentReference', documentRef);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Records shared successfully')),
        );
      }
    } catch (e) {
      debugPrint('FHIR Service Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share records: ${e.toString()}')),
        );
      }
      rethrow;
    }
  }

  static bool _isValidFhirPatientId(String id) {
    // Validate the pattern 'pat-' followed by a UUID
    return RegExp(
            r'^pat-[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$')
        .hasMatch(id.toLowerCase());
  }

  static Map<String, dynamic> _createPatientResource(
      String userId, String userName, SharedPreferences prefs) {
    return {
      "resourceType": "Patient",
      "id": userId.replaceFirst('pat-', ''), // FHIR IDs shouldn't have prefixes
      "identifier": [
        {
          "system": "http://hospital-system/patient-id",
          "value": userId // Keep full ID here
        }
      ],
      "name": [
        {
          "use": "official",
          "text": userName,
          "given": userName.split(' '),
          "family": userName.contains(' ') ? userName.split(' ').last : ''
        }
      ],
      "birthDate": prefs.getString('dob'),
      "telecom": [
        {"system": "phone", "value": prefs.getString('userPhone') ?? 'Unknown'},
        {"system": "email", "value": prefs.getString('email') ?? 'Unknown'}
      ],
      "gender": prefs.getString('gender')?.toLowerCase(),
      "address": [
        {"text": prefs.getString('address') ?? 'Unknown', "use": "home"}
      ]
    };
  }

  static Map<String, dynamic> _createDocumentReference(
      String userId, String userName, String now, String pdfBase64) {
    return {
      "resourceType": "DocumentReference",
      "status": "current",
      "type": {
        "coding": [
          {
            "system": "http://loinc.org",
            "code": "34133-9",
            "display": "Summary of episode note"
          }
        ]
      },
      "subject": {"reference": "Patient/${userId.replaceFirst('pat-', '')}"},
      "author": [
        {"display": userName}
      ],
      "description": "Patient medical record",
      "content": [
        {
          "attachment": {
            "contentType": "application/pdf",
            "creation": now,
            "data": pdfBase64
          }
        }
      ],
      "context": {
        "period": {"start": now}
      }
    };
  }

  static Future<void> _createOrUpdateFhirResource(
      String resourceType, String id, Map<String, dynamic> resource) async {
    final url =
        '$_fhirServerBaseUrl/$resourceType/${id.replaceFirst('pat-', '')}';

    final response = await http.put(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(resource),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
          'Failed to create/update $resourceType: ${response.body}');
    }
  }

  static Future<void> _createFhirResource(
      String resourceType, Map<String, dynamic> resource) async {
    final url = '$_fhirServerBaseUrl/$resourceType';

    final response = await http.post(
      Uri.parse(url),
      headers: _headers,
      body: jsonEncode(resource),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create $resourceType: ${response.body}');
    }
  }

  static final _headers = {
    'Content-Type': 'application/fhir+json',
    'Accept': 'application/fhir+json',
  };

  static Future<String> _createSimplePdf(String text, String imagePath) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Medical Record',
                  style: const pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Text(text),
              if (imagePath.isNotEmpty && File(imagePath).existsSync())
                pw.Image(
                  pw.MemoryImage(File(imagePath).readAsBytesSync()),
                  width: 300,
                  height: 300,
                ),
            ],
          );
        },
      ),
    );
    return base64Encode(await pdf.save());
  }
}
