import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Map<String, dynamic>> schedules = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSchedules();
  }

  Future<void> fetchSchedules() async {
    setState(() => isLoading = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('schedule')
              .orderBy('timestamp', descending: false)
              .get();
      schedules =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
    } catch (e) {
      debugPrint('Error fetching schedules: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> addOrUpdateSchedule({
    Map<String, dynamic>? schedule,
    int? index,
  }) async {
    final titleController = TextEditingController(
      text: schedule?['title'] ?? '',
    );
    TimeOfDay? selectedTime;
    if (schedule?['time'] != null && schedule!['time'] != '') {
      try {
        final time = schedule['time'];
        final format = DateFormat.jm();
        final dt = format.parse(time);
        selectedTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {}
    }
    DateTime? selectedDate =
        schedule?['date'] != null && schedule!['date'] != ''
            ? DateFormat('yyyy-MM-dd').parse(schedule['date'])
            : null;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setStateDialog) => AlertDialog(
                  title: Text(
                    schedule == null ? 'Add Schedule' : 'Edit Schedule',
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedTime == null
                                  ? 'No time selected'
                                  : 'Time: ${selectedTime!.format(context)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  selectedTime = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'No date selected'
                                  : 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}\nDay: ${DateFormat('EEEE').format(selectedDate!)}',
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate ?? now,
                                firstDate: DateTime(now.year - 5),
                                lastDate: DateTime(now.year + 5),
                              );
                              if (picked != null) {
                                setStateDialog(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        if (title.isEmpty ||
                            selectedTime == null ||
                            selectedDate == null)
                          return;
                        final dateStr = DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDate!);
                        final dayStr = DateFormat('EEEE').format(selectedDate!);
                        final timeStr = selectedTime!.format(context);

                        final scheduleData = {
                          'title': title,
                          'time': timeStr,
                          'date': dateStr,
                          'day': dayStr,
                          'timestamp': DateTime.now(),
                        };

                        if (schedule == null) {
                          // Add new
                          await FirebaseFirestore.instance
                              .collection('schedule')
                              .add(scheduleData);
                        } else if (schedule['id'] != null) {
                          // Update existing
                          await FirebaseFirestore.instance
                              .collection('schedule')
                              .doc(schedule['id'])
                              .update(scheduleData);
                        }
                        Navigator.pop(context);
                        await fetchSchedules();
                      },
                      child: Text(schedule == null ? 'Add' : 'Save'),
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> deleteSchedule(int index) async {
    final schedule = schedules[index];
    if (schedule['id'] != null) {
      await FirebaseFirestore.instance
          .collection('schedule')
          .doc(schedule['id'])
          .delete();
      await fetchSchedules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        backgroundColor: Colors.teal,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : schedules.isEmpty
              ? const Center(child: Text('No schedules yet. Tap + to add one!'))
              : ListView.builder(
                itemCount: schedules.length,
                itemBuilder: (context, index) {
                  final schedule = schedules[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      title: Text(
                        schedule['title'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Time: ${schedule['time'] ?? ''}'),
                          Text('Day: ${schedule['day'] ?? ''}'),
                          Text('Date: ${schedule['date'] ?? ''}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed:
                                () => addOrUpdateSchedule(
                                  schedule: schedule,
                                  index: index,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteSchedule(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton: FloatingActionButton(
        heroTag: "schedule_fab",
        onPressed: () => addOrUpdateSchedule(),
        backgroundColor: Colors.teal,
        tooltip: 'Add Schedule',
        child: const Icon(Icons.add),
      ),
    );
  }
}
