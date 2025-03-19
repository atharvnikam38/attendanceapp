import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class NewReportsScreen extends StatefulWidget {
  final String classId;
  NewReportsScreen({required this.classId});

  @override
  _NewReportsScreenState createState() => _NewReportsScreenState();
}

class _NewReportsScreenState extends State<NewReportsScreen> {
  Map<String, Map<String, dynamic>> studentAttendance = {};
  int totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    var snapshot =
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('attendance')
            .get();

    totalSessions = snapshot.docs.length;
    studentAttendance.clear();

    var studentsSnapshot =
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('students')
            .get();

    Map<String, Map<String, dynamic>> studentDetails = {
      for (var doc in studentsSnapshot.docs) doc.id: doc.data(),
    };

    for (var record in snapshot.docs) {
      List records = record['records'];
      for (var student in records) {
        String studentId = student['studentId'];
        if (!studentDetails.containsKey(studentId)) continue;

        String studentName = studentDetails[studentId]?['name'] ?? 'Unknown';
        int rollNumber = studentDetails[studentId]?['rollNumber'] ?? 0;
        int presentCount = studentAttendance[studentId]?['present'] ?? 0;
        int presentValue =
            (student['status'] == 'present' || student['status'] == 'late')
                ? 1
                : 0;

        studentAttendance[studentId] = {
          'name': studentName,
          'rollNumber': rollNumber,
          'present': presentCount + presentValue,
          'total': totalSessions,
        };
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Class Reports')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Total Sessions: $totalSessions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: studentAttendance.keys.length,
              itemBuilder: (context, index) {
                var data = studentAttendance.values.elementAt(index);
                double attendancePercentage =
                    data['total'] > 0
                        ? (data['present'] / data['total']) * 100
                        : 0;

                return ListTile(
                  title: Text(
                    '${data['name']} (Roll No: ${data['rollNumber']})',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Attendance: ${data['present']}/${data['total']} (${attendancePercentage.toStringAsFixed(2)}%)',
                  ),
                );
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups:
                      studentAttendance.entries.map((entry) {
                        var data = entry.value;
                        return BarChartGroupData(
                          x: data['rollNumber'],
                          barRods: [
                            BarChartRodData(
                              toY: data['present'].toDouble(),
                              color: Colors.blue,
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
