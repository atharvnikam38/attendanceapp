import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AttendanceDetailsScreen extends StatefulWidget {
  final String classId;
  final String attendanceId;
  AttendanceDetailsScreen({required this.classId, required this.attendanceId});

  @override
  _AttendanceDetailsScreenState createState() => _AttendanceDetailsScreenState();
}

class _AttendanceDetailsScreenState extends State<AttendanceDetailsScreen> {
  bool isEditing = false;
  String filterStatus = '';
  Map<String, String> updatedAttendance = {};
  List<Map<String, dynamic>> records = [];
  Map<String, dynamic> studentDetails = {};

  void _fetchStudentDetails() async {
    var studentsSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('students')
        .get();
    
    setState(() {
      studentDetails = {for (var doc in studentsSnapshot.docs) doc.id: doc.data()};
      records.sort((a, b) => studentDetails[a['studentId']]['rollNumber'].compareTo(studentDetails[b['studentId']]['rollNumber']));
    });
  }

  void _saveUpdatedAttendance() async {
    if (updatedAttendance.isNotEmpty) {
      for (var entry in updatedAttendance.entries) {
        records.firstWhere((r) => r['studentId'] == entry.key)['status'] = entry.value;
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('attendance')
          .doc(widget.attendanceId)
          .update({'records': records});
    }

    setState(() {
      isEditing = false;
      updatedAttendance.clear();
    });
  }

  void _setAllStatus(String status) {
    setState(() {
      for (var record in records) {
        updatedAttendance[record['studentId']] = status;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchStudentDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Details'),
        actions: [
          if (!isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('attendance')
            .doc(widget.attendanceId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Attendance record not found.'));
          }

          var record = snapshot.data!;
          records = List<Map<String, dynamic>>.from(record['records']);
          int totalStudents = records.length;
          int presentLateCount = records.where((r) => r['status'] == 'present' || r['status'] == 'late').length;

          List<Map<String, dynamic>> filteredRecords = filterStatus.isEmpty
              ? records
              : records.where((r) => r['status'] == filterStatus).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('$presentLateCount / $totalStudents Present',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _filterButton('All', ''),
                  _filterButton('Present', 'present'),
                  _filterButton('Absent', 'absent'),
                  _filterButton('Late', 'late'),
                  _filterButton('Event', 'event'),
                ],
              ),
              if (isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _setAllStatus('present'),
                      child: Text('All Present'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton(
                      onPressed: () => _setAllStatus('absent'),
                      child: Text('All Absent'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                    ElevatedButton(
                      onPressed: () => _setAllStatus('late'),
                      child: Text('All Late'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                    ElevatedButton(
                      onPressed: () => _setAllStatus('event'),
                      child: Text('All Event'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredRecords.length,
                  itemBuilder: (context, index) {
                    var student = filteredRecords[index];
                    String studentId = student['studentId'];
                    String status = updatedAttendance[studentId] ?? student['status'];
                    String studentName = studentDetails[studentId]?['name'] ?? 'Unknown';
                    int rollNumber = studentDetails[studentId]?['rollNumber'] ?? 0;

                    return ListTile(
                      title: Text(studentName, style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Roll No: $rollNumber'),
                      trailing: isEditing
                          ? DropdownButton<String>(
                              value: status,
                              items: ['present', 'absent', 'late', 'event']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: (newStatus) {
                                setState(() {
                                  updatedAttendance[studentId] = newStatus!;
                                });
                              },
                            )
                          : Text(status, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
              if (isEditing)
                ElevatedButton(
                  onPressed: _saveUpdatedAttendance,
                  child: Text('Save'),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterButton(String label, String statusFilter) {
    return TextButton(
      onPressed: () {
        setState(() {
          filterStatus = statusFilter;
        });
      },
      child: Text(label),
    );
  }
}