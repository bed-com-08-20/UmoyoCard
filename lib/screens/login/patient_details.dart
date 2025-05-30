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
  String? _documentContent;
  String? _documentContentType;
  Uint8List? _documentBytes;
  bool _isFetchingDocument = false;
  String? _documentError;
  String? _pdfFilePath;

  static const String _fhirServerBaseUrl = 'http://localhost:8080/fhir';
  static final _headers = {
    'Content-Type': 'application/fhir+json',
    'Accept': 'application/fhir+json',
  };

  @override
  void initState() {
    super.initState();
    _fetchPatientDataAndRelatedDocument();
  }

  Future<void> _fetchPatientDataAndRelatedDocument() async {
    await _fetchPatientData();
    if (_patientData != null && _hasPatientDataToShow()) {
      await _fetchFirstRelevantDocument();
    }
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

    final name = FHIRResourceParser.getPatientName(_patientData);
    final gender = FHIRResourceParser.getPatientGender(_patientData);
    final birthDate = FHIRResourceParser.getPatientBirthDate(_patientData);
    final phones = FHIRResourceParser.getPatientPhoneNumbers(_patientData);
    final emails = FHIRResourceParser.getPatientEmails(_patientData);
    final address = FHIRResourceParser.getPatientAddress(_patientData);

    return name.isNotEmpty ||
        gender.isNotEmpty ||
        birthDate.isNotEmpty ||
        phones.isNotEmpty ||
        emails.isNotEmpty ||
        address.isNotEmpty;
  }

  Future<void> _fetchFirstRelevantDocument() async {
    final searchUrl =
        '$_fhirServerBaseUrl/DocumentReference?subject=Patient/${widget.patientId}';
    setState(() {
      _isFetchingDocument = true;
      _documentError = null;
      _documentContent = null;
      _documentBytes = null;
      _documentContentType = null;
      _pdfFilePath = null;
    });
    try {
      final response = await http.get(Uri.parse(searchUrl), headers: _headers);
      if (response.statusCode == 200) {
        final searchResult = jsonDecode(response.body);
        final entryList = searchResult['entry'] as List?;
        if (entryList != null && entryList.isNotEmpty) {
          final firstDocumentReference = entryList.first['resource'];
          if (firstDocumentReference != null &&
              firstDocumentReference['content'] != null &&
              firstDocumentReference['content'].isNotEmpty &&
              firstDocumentReference['content'][0]['attachment'] != null) {
            final attachment =
                firstDocumentReference['content'][0]['attachment'];
            final base64Data = attachment['data'] as String?;
            final contentType = attachment['contentType'] as String?;

            if (base64Data != null && base64Data.isNotEmpty) {
              try {
                final decodedBytes = base64Decode(base64Data);
                setState(() {
                  _documentBytes = decodedBytes;
                  _documentContentType = contentType;
                  _isFetchingDocument = false;
                  _documentError = null;
                  if (contentType == 'text/plain') {
                    _documentContent = utf8.decode(decodedBytes);
                  }
                });
                if (contentType == 'application/pdf') {
                  await _savePdfToTemporaryFile(decodedBytes);
                }
              } catch (e) {
                setState(() {
                  _documentError = 'Error decoding document content: $e';
                  _isFetchingDocument = false;
                });
              }
            } else {
              setState(() {
                _documentError = 'No embedded document data found.';
                _isFetchingDocument = false;
              });
            }
          } else {
            setState(() {
              _documentError = 'No attachment found in the DocumentReference.';
              _isFetchingDocument = false;
            });
          }
        } else {
          setState(() {
            _documentContent = 'No DocumentReference found for this patient.';
            _isFetchingDocument = false;
          });
        }
      } else {
        setState(() {
          _documentError =
              'Failed to search for DocumentReference: Status ${response.statusCode}';
          _isFetchingDocument = false;
        });
      }
    } catch (e) {
      setState(() {
        _documentError = 'Error searching for DocumentReference: $e';
        _isFetchingDocument = false;
      });
    }
  }

  Future<void> _savePdfToTemporaryFile(Uint8List pdfBytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/document.pdf');
      await file.writeAsBytes(pdfBytes);
      setState(() {
        _pdfFilePath = file.path;
      });
    } catch (e) {
      setState(() {
        _documentError = 'Error saving PDF to temporary file: $e';
      });
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

    if (_patientData == null) {
      return const Center(
        child: Text(
          'No patient data available.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (!_hasPatientDataToShow()) {
      return const Center(
        child: Text(
          'No patient data available to display.',
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
            const Text('Document Content:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDocumentContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentContent() {
    if (_isFetchingDocument) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_documentError != null) {
      return Text('Error fetching document: $_documentError',
          style: const TextStyle(color: Colors.red));
    }
    if (_documentContentType == 'text/plain' && _documentContent != null) {
      return Text(_documentContent!);
    }
    if (_documentContentType == 'application/pdf' && _pdfFilePath != null) {
      return SizedBox(
        height: 400,
        child: PDFView(
          filePath: _pdfFilePath!,
          enableSwipe: true,
          swipeHorizontal: false,
          autoSpacing: false,
          pageSnap: true,
          pageFling: false,
        ),
      );
    }
    if (_documentContentType?.startsWith('image/') == true &&
        _documentBytes != null) {
      return Image.memory(_documentBytes!);
    }
    return const Text('No document content available.');
  }
}
