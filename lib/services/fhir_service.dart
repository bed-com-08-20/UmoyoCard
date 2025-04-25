import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fhir/r4.dart';
import 'package:pdf/widgets.dart' as pw;

class FHIRService {
  static const String _fhirServerBaseUrl = 'http://localhost:8080/fhir';

  static Future<void> sendDocumentToFHIR({
    required String documentText,
    required String imagePath,
    required BuildContext context,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'unknown';
      final userName = prefs.getString('userName') ?? 'Unknown User';
      final now = DateTime.now().toUtc().toIso8601String();

      // Create the PDF and get base64
      final pdfBase64 = await _createCombinedPdfBase64(documentText, imagePath);

      // Create DocumentReference resource
      final documentReference = DocumentReference(
        resourceType: R4ResourceType.DocumentReference,
        status: FhirCode('current'), // ✅ Corrected
        type: CodeableConcept(
          coding: [
            Coding(
              system: FhirUri('http://loinc.org'),
              code: FhirCode('34133-9'), // ✅ Corrected
              display: 'Summary of episode note',
            ),
          ],
        ),
        subject: Reference(reference: 'Patient/$userId'),
        author: [
          Reference(display: userName),
        ],
        description: 'Medical document scanned by user',
        content: [
          DocumentReferenceContent(
            attachment: Attachment(
              contentType: FhirCode('application/pdf'), // ✅ Corrected
              creation: FhirDateTime(now),
              title: 'User medical document',
              data: FhirBase64Binary(pdfBase64), // ✅ Corrected
            ),
          ),
        ],
        context: DocumentReferenceContext(
          period: Period(start: FhirDateTime(now)),
        ),
      );

      // Send to FHIR server
      final response = await http.post(
        Uri.parse('$_fhirServerBaseUrl/DocumentReference'),
        headers: {
          'Content-Type': 'application/fhir+json',
          'Accept': 'application/fhir+json',
        },
        body: jsonEncode(documentReference.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Document successfully sent to FHIR server')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send document: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending to FHIR: $e')),
      );
    }
  }

  static Future<String> _createCombinedPdfBase64(
    String text,
    String imagePath,
  ) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('User Medical Document',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text(text),
              pw.SizedBox(height: 20),
              if (imagePath.isNotEmpty)
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
    final bytes = await pdf.save();
    return base64Encode(bytes);
  }

  static Future<List<DocumentReference>> getPatientDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'unknown';

      final response = await http.get(
        Uri.parse(
            '$_fhirServerBaseUrl/DocumentReference?subject=Patient/$userId'),
        headers: {
          'Accept': 'application/fhir+json',
        },
      );

      if (response.statusCode == 200) {
        final bundle = Bundle.fromJson(jsonDecode(response.body));
        return bundle.entry
                ?.map((e) => e.resource as DocumentReference)
                .whereType<DocumentReference>()
                .toList() ??
            [];
      }
    } catch (e) {
      debugPrint('Error fetching documents: $e');
    }
    return [];
  }
}
