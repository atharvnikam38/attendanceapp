import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TakeAttendanceScreen extends StatefulWidget {
  final String classId;
  TakeAttendanceScreen({required this.classId});

  @override
  _TakeAttendanceScreenState createState() => _TakeAttendanceScreenState();
}

class _TakeAttendanceScreenState extends State<TakeAttendanceScreen> {
  Map<String, String> attendanceStatus = {};
  int totalStudents = 0;

  void _submitAttendance() async {
    if (attendanceStatus.length < totalStudents) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please mark attendance for all students.')),
      );
      return;
    }

    DateTime now = DateTime.now();
    String dateTime = now.toIso8601String();

    List<Map<String, dynamic>> records = attendanceStatus.entries.map((entry) {
      return {
        'studentId': entry.key,
        'status': entry.value,
      };
    }).toList();

    // Save class-wise attendance with time and date
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('attendance')
        .doc(dateTime)
        .set({'records': records, 'timestamp': now}, SetOptions(merge: true));

    // Save student-wise attendance with time and date
    for (var entry in attendanceStatus.entries) {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .doc(entry.key)
          .collection('attendance')
          .doc(dateTime)
          .set({'status': entry.value, 'timestamp': now});
    }

    Navigator.pop(context);
  }

  void _setAllStatus(String status) {
    setState(() {
      attendanceStatus = {};
      FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .get()
          .then((snapshot) {
        totalStudents = snapshot.docs.length;
        for (var doc in snapshot.docs) {
          attendanceStatus[doc.id] = status;
        }
        setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take Attendance')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () => _setAllStatus('present'),
                child: Text('All Present', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
              ElevatedButton(
                onPressed: () => _setAllStatus('absent'),
                child: Text('All Absent', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
              ElevatedButton(
                onPressed: () => _setAllStatus('late'),
                child: Text('All Late', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              ),
              ElevatedButton(
                onPressed: () => _setAllStatus('event'),
                child: Text('All Event', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              ),
            ],
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('students')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No students found.'));
                }

                var students = snapshot.data!.docs;
                totalStudents = students.length;

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student = students[index];
                    String status = attendanceStatus[student.id] ?? '';
                    return ListTile(
                      title: Text(student['name']),
                      subtitle: Text('Roll No: ${student['rollNumber']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusButton(student.id, 'P', 'present', Colors.green, status),
                          _buildStatusButton(student.id, 'A', 'absent', Colors.red, status),
                          _buildStatusButton(student.id, 'L', 'late', Colors.orange, status),
                          _buildStatusButton(student.id, 'E', 'event', Colors.blue, status),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submitAttendance,
        child: Icon(Icons.save),
      ),
    );
  }

  Widget _buildStatusButton(String studentId, String label, String statusValue, Color color, String selectedStatus) {
    return TextButton(
      onPressed: () {
        setState(() {
          attendanceStatus[studentId] = statusValue;
        });
      },
      child: Text(label, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: selectedStatus == statusValue ? color : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
