import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimetableScreen extends StatefulWidget {
  @override
  _TimetableScreenState createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> times = [
    '8:30-9:30',
    '9:30-10:30',
    '10:30-11:30',
    '11:30-12:30',
    'BREAK',
    '1:30-2:30',
    '2:30-3:30',
    'Extra Class',
  ];

  Map<String, String> timetable = {};

  void _editSlot(String day, String time) {
    TextEditingController classController = TextEditingController();
    TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Timetable Slot"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: classController,
                decoration: InputDecoration(labelText: "Class Name"),
              ),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(labelText: "Subject"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  timetable['$day-$time'] =
                      "${classController.text}\n${subjectController.text}";
                });
                FirebaseFirestore.instance
                    .collection('timetable')
                    .doc('$day-$time')
                    .set({
                      'className': classController.text,
                      'subject': subjectController.text,
                    });
                Navigator.pop(context);
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Timetable")),
      body: Padding(
        padding: EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 24,
            dataRowHeight: 80,
            headingRowHeight: 60,
            columns:
                [
                  DataColumn(
                    label: Text(
                      "Day",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ] +
                times
                    .map(
                      (t) => DataColumn(
                        label: Text(
                          t,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .toList(),
            rows:
                days.map((day) {
                  return DataRow(
                    cells:
                        [
                          DataCell(
                            Text(
                              day,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ] +
                        times.map((time) {
                          return DataCell(
                            GestureDetector(
                              onTap: () => _editSlot(day, time),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                alignment: Alignment.center,
                                child: Text(
                                  timetable['$day-$time'] ??
                                      (time == 'BREAK'
                                          ? 'BREAK'
                                          : 'Tap to add'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight:
                                        time == 'BREAK'
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                    color:
                                        time == 'BREAK'
                                            ? Colors.red
                                            : Colors.black,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                }).toList(),
          ),
        ),
      ),
    );
  }
}
