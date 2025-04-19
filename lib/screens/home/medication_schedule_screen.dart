import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class Medication {
  final String name;
  final String dosage;
  final List<TimeOfDay> intakeTimes;
  final DateTime startDate;
  final DateTime endDate;

  Medication({
    required this.name,
    required this.dosage,
    required this.intakeTimes,
    required this.startDate,
    required this.endDate,
  });
}

class MedicationScheduleScreen extends StatefulWidget {
  const MedicationScheduleScreen({super.key});

  @override
  State<MedicationScheduleScreen> createState() => _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  final List<Medication> _medications = [];
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _scheduleNotifications(Medication medication) async {
    for (var time in medication.intakeTimes) {
      DateTime scheduledTime = DateTime(
        medication.startDate.year,
        medication.startDate.month,
        medication.startDate.day,
        time.hour,
        time.minute,
      );
      if (scheduledTime.isBefore(DateTime.now())) continue;

// Convert to TZDateTime
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      await _notificationsPlugin.zonedSchedule(
        scheduledTime.millisecondsSinceEpoch ~/ 1000, // unique id
        'Medication Reminder',
        'Time to take ${medication.name} (${medication.dosage})',
        tzScheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails('med_channel', 'Medications'),
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // optional, based on repeat needs
      );

    }
  }

  void _addMedication() async {
    final result = await showDialog<Medication>(
      context: context,
      builder: (context) => const AddMedicationDialog(),
    );
    if (result != null) {
      setState(() => _medications.add(result));
      await _scheduleNotifications(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medication Schedule')),
      body: ListView.builder(
        itemCount: _medications.length,
        itemBuilder: (context, index) {
          final med = _medications[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text('${med.name} (${med.dosage})'),
              subtitle: Text('From ${DateFormat.yMMMd().format(med.startDate)} to ${DateFormat.yMMMd().format(med.endDate)}\nIntake Times: ${med.intakeTimes.map((t) => t.format(context)).join(', ')}'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMedication,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddMedicationDialog extends StatefulWidget {
  const AddMedicationDialog({super.key});

  @override
  State<AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<AddMedicationDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  List<TimeOfDay> _intakeTimes = [TimeOfDay.now()];

  void _addTime() {
    setState(() => _intakeTimes.add(TimeOfDay.now()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medication'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Medication Name')),
            TextField(controller: _dosageController, decoration: const InputDecoration(labelText: 'Dosage')),
            ListTile(
              title: const Text('Start Date'),
              subtitle: Text(DateFormat.yMMMd().format(_startDate)),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (date != null) setState(() => _startDate = date);
              },
            ),
            ListTile(
              title: const Text('End Date'),
              subtitle: Text(DateFormat.yMMMd().format(_endDate)),
              onTap: () async {
                final date = await showDatePicker(context: context, initialDate: _endDate, firstDate: _startDate, lastDate: DateTime(2100));
                if (date != null) setState(() => _endDate = date);
              },
            ),
            const SizedBox(height: 10),
            const Text('Intake Times:'),
            ..._intakeTimes.map((time) => ListTile(
              title: Text(time.format(context)),
              onTap: () async {
                final newTime = await showTimePicker(context: context, initialTime: time);
                if (newTime != null) setState(() => _intakeTimes[_intakeTimes.indexOf(time)] = newTime);
              },
            )),
            TextButton.icon(onPressed: _addTime, icon: const Icon(Icons.add), label: const Text('Add Time')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final med = Medication(
              name: _nameController.text,
              dosage: _dosageController.text,
              intakeTimes: _intakeTimes,
              startDate: _startDate,
              endDate: _endDate,
            );
            Navigator.pop(context, med);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
