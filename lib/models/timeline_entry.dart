class TimelineEntry {
  final DateTime date;
  final String? bloodPressure;
  final String? bloodSugar;
  final double? weight;
  final String? personalMedicalHistory;
  final String? familyMedicalHistory;
  final String? prescription;

  TimelineEntry({
    required this.date,
    this.bloodPressure,
    this.bloodSugar,
    this.weight,
    this.personalMedicalHistory,
    this.familyMedicalHistory,
    this.prescription,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'bloodPressure': bloodPressure,
      'bloodSugar': bloodSugar,
      'weight': weight,
      'personalMedicalHistory': personalMedicalHistory,
      'familyMedicalHistory': familyMedicalHistory,
      'prescription': prescription,
    };
  }

  factory TimelineEntry.fromMap(Map<String, dynamic> map) {
    return TimelineEntry(
      date: DateTime.parse(map['date']),
      bloodPressure: map['bloodPressure'],
      bloodSugar: map['bloodSugar'],
      weight: map['weight']?.toDouble(),
      personalMedicalHistory: map['personalMedicalHistory'],
      familyMedicalHistory: map['familyMedicalHistory'],
      prescription: map['prescription'],
    );
  }
}
