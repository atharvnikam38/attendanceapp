import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'attendance_details_screen.dart';

class ViewAttendanceScreen extends StatelessWidget {
  final String classId;
  ViewAttendanceScreen({required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance Records')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('attendance')
            .orderBy('timestamp', descending: false) // Latest lecture at the bottom
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No attendance records found.'));
          }

          var records = snapshot.data!.docs;
          records = records.reversed.toList(); // Reverse the order for display

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              var record = records[index];
              DateTime timestamp = (record['timestamp'] as Timestamp).toDate();
              int totalStudents = record['records'].length;
              int presentLateCount = record['records'].where((r) => r['status'] == 'present' || r['status'] == 'late').length;

              return ListTile(
                title: Text('Lecture ${records.length - index}'), // Latest lecture first
                subtitle: Text('${timestamp.toLocal()}'),
                trailing: Text('$presentLateCount / $totalStudents Present'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AttendanceDetailsScreen(
                        classId: classId,
                        attendanceId: record.id,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}