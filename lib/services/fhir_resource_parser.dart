import 'dart:convert';
import 'dart:typed_data';

class FHIRResourceParser {
  static String? decodeTextDocumentContent(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (e) {
      print('Error decoding text document content: $e');
      return null;
    }
  }

  static Uint8List? decodeBinaryDocumentContent(Uint8List bytes) {
    return bytes;
  }

  static String? getDocumentContentType(Map<String, dynamic>? documentReference) {
    if (documentReference != null &&
        documentReference.containsKey('content') &&
        (documentReference['content'] as List).isNotEmpty &&
        documentReference['content'][0].containsKey('attachment')) {
      return documentReference['content'][0]['attachment']['contentType'] as String?;
    }
    return null;
  }

  static Uint8List? getDocumentData(Map<String, dynamic>? documentReference) {
    if (documentReference != null &&
        documentReference.containsKey('content') &&
        (documentReference['content'] as List).isNotEmpty &&
        documentReference['content'][0].containsKey('attachment') &&
        documentReference['content'][0]['attachment'].containsKey('data')) {
      final base64Data = documentReference['content'][0]['attachment']['data'] as String?;
      if (base64Data != null && base64Data.isNotEmpty) {
        try {
          return base64Decode(base64Data);
        } catch (e) {
          print('Error decoding Base64 document data: $e');
          return null;
        }
      }
    }
    return null;
  }

  static String getPatientName(Map<String, dynamic>? data) {
    if (data != null && data.containsKey('name') && data['name'].isNotEmpty) {
      final name = data['name'][0];
      String displayName = '';
      if (name.containsKey('text')) {
        displayName = name['text'] as String? ?? displayName;
      } else {
        final given = (name['given'] as List?)?.join(' ') ?? '';
        final family = name['family'] as String? ?? '';
        displayName = '$given $family'.trim();
      }
      return displayName;
    }
    return 'Unknown';
  }

  static String getPatientGender(Map<String, dynamic>? data) {
    return data?['gender'] ?? 'Unknown';
  }

  static String getPatientBirthDate(Map<String, dynamic>? data) {
    return data?['birthDate'] ?? 'Unknown';
  }

  static List<String> getPatientPhoneNumbers(Map<String, dynamic>? data) {
    final phoneNumbers = <String>[];
    if (data != null && data.containsKey('telecom')) {
      final telecomList = data['telecom'] as List?;
      telecomList?.forEach((telecom) {
        if (telecom['system'] == 'phone' && telecom.containsKey('value')) {
          phoneNumbers.add(telecom['value'] as String);
        }
      });
    }
    return phoneNumbers;
  }

  static List<String> getPatientEmails(Map<String, dynamic>? data) {
    final emails = <String>[];
    if (data != null && data.containsKey('telecom')) {
      final telecomList = data['telecom'] as List?;
      telecomList?.forEach((telecom) {
        if (telecom['system'] == 'email' && telecom.containsKey('value')) {
          emails.add(telecom['value'] as String);
        }
      });
    }
    return emails;
  }

  static String getPatientAddress(Map<String, dynamic>? data) {
    if (data != null && data.containsKey('address') && data['address'].isNotEmpty) {
      return data['address'][0]['text'] as String? ?? 'Unknown';
    }
    return 'Unknown';
  }
}