import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:umoyocard/services/fhir_resource_parser.dart';

class PatientDetailsScreen extends StatefulWidget {
  final String patientId;

  const PatientDetailsScreen({super.key, required this.patientId});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  Map<String, dynamic>? _patientData;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _documents = []; // Stores all documents
  bool _isFetchingDocuments = false;
  String? _documentsError;

  static const String _fhirServerBaseUrl = 'http://localhost:8080/fhir';
  static final _headers = {
    'Content-Type': 'application/fhir+json',
    'Accept': 'application/fhir+json',
  };

  @override
  void initState() {
    super.initState();
    _fetchPatientData();
    _fetchAllDocuments();
  }

  Future<void> _fetchPatientData() async {
    final url = '$_fhirServerBaseUrl/Patient/${widget.patientId}';
    try {
      final response = await http.get(Uri.parse(url), headers: _headers);
      if (response.statusCode == 200) {
        setState(() {
          _patientData = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to fetch patient data: Status ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching patient data: $e';
        _isLoading = false;
      });
    }
  }

  bool _hasPatientDataToShow() {
    if (_patientData == null) return false;
    return FHIRResourceParser.getPatientName(_patientData).isNotEmpty ||
        FHIRResourceParser.getPatientGender(_patientData).isNotEmpty ||
        FHIRResourceParser.getPatientBirthDate(_patientData).isNotEmpty ||
        FHIRResourceParser.getPatientPhoneNumbers(_patientData).isNotEmpty ||
        FHIRResourceParser.getPatientEmails(_patientData).isNotEmpty ||
        FHIRResourceParser.getPatientAddress(_patientData).isNotEmpty;
  }

  Future<void> _fetchAllDocuments() async {
    final searchUrl =
        '$_fhirServerBaseUrl/DocumentReference?subject=Patient/${widget.patientId}';
    setState(() {
      _isFetchingDocuments = true;
      _documentsError = null;
      _documents.clear();
    });

    try {
      final response = await http.get(Uri.parse(searchUrl), headers: _headers);
      if (response.statusCode == 200) {
        final searchResult = jsonDecode(response.body);
        final entryList = searchResult['entry'] as List?;

        if (entryList != null && entryList.isNotEmpty) {
          for (final entry in entryList) {
            final docRef = entry['resource'];
            if (docRef != null &&
                docRef['content'] != null &&
                docRef['content'].isNotEmpty) {
              final attachment = docRef['content'][0]['attachment'];
              final base64Data = attachment['data'] as String?;
              final contentType = attachment['contentType'] as String?;

              if (base64Data != null && base64Data.isNotEmpty) {
                try {
                  final decodedBytes = base64Decode(base64Data);
                  _documents.add({
                    'bytes': decodedBytes,
                    'type': contentType,
                    'content': contentType == 'text/plain'
                        ? utf8.decode(decodedBytes)
                        : null,
                  });
                } catch (e) {
                  print('Error decoding document: $e');
                }
              }
            }
          }
        }
      } else {
        setState(() {
          _documentsError =
              'Failed to fetch documents: Status ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _documentsError = 'Error fetching documents: $e';
      });
    } finally {
      setState(() {
        _isFetchingDocuments = false;
      });
    }
  }

  Future<String> _savePdfToTemporaryFile(Uint8List pdfBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/document_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      throw 'Error saving PDF: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.teal,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }

    if (_patientData == null || !_hasPatientDataToShow()) {
      return const Center(
        child: Text(
          'No patient data available.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${FHIRResourceParser.getPatientName(_patientData)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
                'Gender: ${FHIRResourceParser.getPatientGender(_patientData)}'),
            const SizedBox(height: 8),
            Text(
                'Birth Date: ${FHIRResourceParser.getPatientBirthDate(_patientData)}'),
            const SizedBox(height: 8),
            if (FHIRResourceParser.getPatientPhoneNumbers(_patientData)
                .isNotEmpty) ...[
              const Text('Phone Numbers:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...FHIRResourceParser.getPatientPhoneNumbers(_patientData)
                  .map((phone) => Text(phone)),
              const SizedBox(height: 8),
            ],
            if (FHIRResourceParser.getPatientEmails(_patientData)
                .isNotEmpty) ...[
              const Text('Emails:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...FHIRResourceParser.getPatientEmails(_patientData)
                  .map((email) => Text(email)),
              const SizedBox(height: 8),
            ],
            Text(
                'Address: ${FHIRResourceParser.getPatientAddress(_patientData)}'),
            const SizedBox(height: 16),
            _buildDocumentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Documents:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (_isFetchingDocuments)
          const Center(child: CircularProgressIndicator()),
        if (_documentsError != null)
          Text('Error: $_documentsError',
              style: const TextStyle(color: Colors.red)),
        if (!_isFetchingDocuments && _documents.isEmpty)
          const Text('No documents available.'),
        ..._documents.map((doc) => _buildDocumentCard(doc)).toList(),
      ],
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> document) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${document['type'] ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (document['type'] == 'text/plain' && document['content'] != null)
              Text(document['content']),
            if (document['type'] == 'application/pdf')
              FutureBuilder<String>(
                future: _savePdfToTemporaryFile(document['bytes']),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return SizedBox(
                      height: 400,
                      child: PDFView(
                        filePath: snapshot.data!,
                        enableSwipe: true,
                        swipeHorizontal: false,
                        autoSpacing: false,
                        pageSnap: false,
                        pageFling: false,
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error loading PDF: ${snapshot.error}');
                  }
                  return const CircularProgressIndicator();
                },
              ),
            if (document['type']?.startsWith('image/') == true)
              Image.memory(document['bytes']),
          ],
        ),
      ),
    );
  }
}
