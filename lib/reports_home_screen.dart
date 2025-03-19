import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reports_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportsHomeScreen extends StatefulWidget {
  @override
  _ReportsHomeScreenState createState() => _ReportsHomeScreenState();
}

class _ReportsHomeScreenState extends State<ReportsHomeScreen> {
  String? selectedClassId;
  String? selectedSubject;
  List<Map<String, String>> classList = []; // Store both classId and className
  Map<String, List<String>> classSubjects = {};

  @override
  void initState() {
    super.initState();
    _fetchClassesAndSubjects();
  }

  Future<void> _fetchClassesAndSubjects() async {
    String? teacherId = FirebaseAuth.instance.currentUser?.uid;
    if (teacherId == null) return;

    var userDoc = await FirebaseFirestore.instance.collection('users').doc(teacherId).get();

    if (userDoc.exists) {
      List<dynamic> classIds = userDoc['classes'] ?? [];
      for (var classId in classIds) {
        var classDoc = await FirebaseFirestore.instance.collection('classes').doc(classId).get();
        if (classDoc.exists) {
          String className = classDoc['className'];
          String subject = classDoc['subject'];

          if (!classList.any((item) => item['id'] == classId)) {
            classList.add({'id': classId, 'name': className});
          }

          if (!classSubjects.containsKey(classId)) {
            classSubjects[classId] = [];
          }
          if (!classSubjects[classId]!.contains(subject)) {
            classSubjects[classId]!.add(subject);
          }
        }
      }
      setState(() {});
    }
  }

  void _generateReport() {
    if (selectedClassId != null && selectedSubject != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportsScreen(classId: selectedClassId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Select Class & Subject")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: selectedClassId,
              items: classList.map((classData) {
                return DropdownMenuItem(
                  value: classData['id'],
                  child: Text(classData['name']!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedClassId = value;
                  selectedSubject = null;
                });
              },
              decoration: InputDecoration(labelText: "Select Class"),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedSubject,
              items: selectedClassId != null && classSubjects.containsKey(selectedClassId)
                  ? classSubjects[selectedClassId]!.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      );
                    }).toList()
                  : [],
              onChanged: (value) {
                setState(() {
                  selectedSubject = value;
                });
              },
              decoration: InputDecoration(labelText: "Select Subject"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generateReport,
              child: Text("View Report"),
            ),
          ],
        ),
      ),
    );
  }
}
