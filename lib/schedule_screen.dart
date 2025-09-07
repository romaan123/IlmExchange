import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleScreen extends StatefulWidget {
  final String withUser;

  const ScheduleScreen({super.key, required this.withUser});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );

    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  void _confirmSession() {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select both date and time.")),
      );
      return;
    }

    final formattedDate = DateFormat.yMMMMd().format(selectedDate!);
    final formattedTime = selectedTime!.format(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Session scheduled with ${widget.withUser} on $formattedDate at $formattedTime!",
        ),
      ),
    );

    setState(() {
      selectedDate = null;
      selectedTime = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = selectedDate != null && selectedTime != null;

    return Scaffold(
      appBar: AppBar(
        title: Text("Schedule Session"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Schedule a session with ${widget.withUser}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _pickDate,
              icon: Icon(Icons.calendar_today),
              label: Text(selectedDate == null
                  ? "Pick Date"
                  : DateFormat.yMMMMd().format(selectedDate!)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickTime,
              icon: Icon(Icons.access_time),
              label: Text(selectedTime == null
                  ? "Pick Time"
                  : selectedTime!.format(context)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: _confirmSession,
              icon: Icon(Icons.check),
              label: Text("Confirm Session"),
              style: ElevatedButton.styleFrom(
                backgroundColor: selected ? Colors.green : Colors.grey,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
