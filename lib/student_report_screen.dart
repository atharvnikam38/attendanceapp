import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentReportScreen extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final int rollNumber;

  StudentReportScreen({
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$studentName (Roll No: $rollNumber)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('classes')
                    .doc(classId)
                    .collection('students')
                    .doc(studentId)
                    .collection('attendance')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No attendance records found for this student.'));
                  }

                  var attendanceRecords = snapshot.data!.docs;
                  attendanceRecords.sort((a, b) => b.id.compareTo(a.id));

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: attendanceRecords.map((record) {
                        String date = record.id;
                        Map<String, dynamic>? recordData = record.data() as Map<String, dynamic>?;
                        String status = recordData != null && recordData.containsKey('status') ? recordData['status'] : 'Unknown';
                        return DataRow(cells: [
                          DataCell(Text(date)),
                          DataCell(
                            Text(
                              status,
                              style: TextStyle(
                                color: status == 'present'
                                    ? Colors.green
                                    : status == 'late'
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
