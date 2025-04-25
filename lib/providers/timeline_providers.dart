import 'package:flutter/material.dart';
import '../models/timeline_entry.dart';

class TimelineProvider extends ChangeNotifier {
  final List<TimelineEntry> _entries = [];

  List<TimelineEntry> get allEntries => _entries;

  void addEntry(TimelineEntry entry) {
    _entries.add(entry);
    notifyListeners();
  }

  List<TimelineEntry> getBloodPressureEntries() {
    return _entries.where((e) => e.bloodPressure != null).toList();
  }

  List<TimelineEntry> getBloodSugarEntries() {
    return _entries.where((e) => e.bloodSugar != null).toList();
  }

  List<TimelineEntry> getWeightEntries() {
    return _entries.where((e) => e.weight != null).toList();
  }

  List<TimelineEntry> getPersonalMedicalHistoryEntries() {
    return _entries.where((e) => e.personalMedicalHistory != null).toList();
  }

  List<TimelineEntry> getFamilyMedicalHistoryEntries() {
    return _entries.where((e) => e.familyMedicalHistory != null).toList();
  }
}
