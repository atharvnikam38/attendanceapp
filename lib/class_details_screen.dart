import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'students_list_screen.dart';
import 'take_attendance_screen.dart';
import 'view_attendance_screen.dart';
import 'reports_screen.dart';

class ClassDetailsScreen extends StatelessWidget {
  final String classId;
  final String className;
  final String subject;

  ClassDetailsScreen({required this.classId, required this.className, required this.subject});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$className - $subject'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildDetailCard(Icons.people, 'Students', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentsListScreen(classId: classId),
                      ),
                    );
                  }),
                  _buildDetailCard(Icons.assignment, 'Take Attendance', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TakeAttendanceScreen(classId: classId),
                      ),
                    );
                  }),
                  _buildDetailCard(Icons.visibility, 'View Attendance', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewAttendanceScreen(classId: classId),
                      ),
                    );
                  }),
                  _buildDetailCard(Icons.bar_chart, 'Reports', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReportsScreen(classId: classId),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
