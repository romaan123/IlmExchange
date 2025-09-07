import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_service.dart';

class SessionSchedulingScreen extends StatefulWidget {
  final String skillId;
  final String skillTitle;
  final String providerId;
  final String providerName;

  const SessionSchedulingScreen({
    super.key,
    required this.skillId,
    required this.skillTitle,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<SessionSchedulingScreen> createState() => _SessionSchedulingScreenState();
}

class _SessionSchedulingScreenState extends State<SessionSchedulingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;
  String _notes = '';
  bool _isLoading = false;

  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Schedule Session'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session info card
            _buildSessionInfoCard(isDarkMode),

            const SizedBox(height: 24),

            // Calendar
            _buildCalendar(isDarkMode),

            const SizedBox(height: 24),

            // Time selection
            if (_selectedDay != null) _buildTimeSelection(isDarkMode),

            const SizedBox(height: 24),

            // Notes
            if (_selectedDay != null && _selectedTime != null) _buildNotesSection(isDarkMode),

            const SizedBox(height: 32),

            // Schedule button
            if (_selectedDay != null && _selectedTime != null) _buildScheduleButton(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfoCard(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.deepPurple, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.skillTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, color: Colors.grey.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'with ${widget.providerName}',
                  style: TextStyle(fontSize: 16, color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TableCalendar<Event>(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedTime = null; // Reset time when date changes
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: Colors.deepPurple.withValues(alpha: 0.5), shape: BoxShape.circle),
                disabledTextStyle: TextStyle(color: Colors.grey.shade400),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              enabledDayPredicate: (day) {
                return day.isAfter(DateTime.now().subtract(const Duration(days: 1)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSelection(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _generateTimeSlots().map((time) {
                    final isSelected = _selectedTime == time;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedTime = time),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.deepPurple : Colors.transparent,
                          border: Border.all(color: isSelected ? Colors.deepPurple : Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          time.format(context),
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDarkMode ? Colors.white : Colors.black87),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(bool isDarkMode) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Any specific topics or requirements...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              ),
              maxLines: 3,
              onChanged: (value) => _notes = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _scheduleSession,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child:
            _isLoading
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : const Text('Schedule Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  List<TimeOfDay> _generateTimeSlots() {
    final slots = <TimeOfDay>[];
    for (int hour = 9; hour <= 21; hour++) {
      slots.add(TimeOfDay(hour: hour, minute: 0));
      if (hour < 21) {
        slots.add(TimeOfDay(hour: hour, minute: 30));
      }
    }
    return slots;
  }

  Future<void> _scheduleSession() async {
    if (_selectedDay == null || _selectedTime == null) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final sessionDateTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final sessionData = {
        'skillId': widget.skillId,
        'skillTitle': widget.skillTitle,
        'providerId': widget.providerId,
        'providerName': widget.providerName,
        'requesterId': currentUser.uid,
        'requesterName': currentUser.displayName ?? 'Anonymous',
        'dateTime': Timestamp.fromDate(sessionDateTime),
        'notes': _notes,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final sessionDocRef = await _firestore.collection('sessions').add(sessionData);

      // Send notification to provider with actual session ID
      await NotificationService.sendSessionNotification(
        receiverId: widget.providerId,
        title: 'New Session Request 📅',
        sessionDetails:
            'You have a new session request for "${widget.skillTitle}" on ${_formatDateTime(sessionDateTime)}. Please review and respond.',
        sessionId: sessionDocRef.id,
      );

      debugPrint('✅ Session created with ID: ${sessionDocRef.id}');

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session request sent successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error scheduling session: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
  }
}

class Event {
  final String title;
  Event(this.title);
}
