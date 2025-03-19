import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' as flutter;
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'student_report_screen.dart';

class StudentsListScreen extends flutter.StatefulWidget {
  final String classId;
  StudentsListScreen({required this.classId});

  @override
  _StudentsListScreenState createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends flutter.State<StudentsListScreen> {
  final flutter.TextEditingController _nameController = flutter.TextEditingController();
  final flutter.TextEditingController _rollNumberController = flutter.TextEditingController();

  /// Function to Add a Single Student to Firebase
  void _addStudent(String name, int rollNumber) async {
    if (name.isNotEmpty && rollNumber > 0) {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('students')
          .add({
        'name': name,
        'rollNumber': rollNumber,
        'createdAt': Timestamp.now(),
      });

      setState(() {}); // Refresh UI
    }
  }

  /// Function to Import Students from Excel File
  Future<void> _importStudents() async {
    if (kIsWeb) {
      html.FileUploadInputElement uploadInput = html.FileUploadInputElement();
      uploadInput.accept = ".xlsx";
      uploadInput.click();

      uploadInput.onChange.listen((event) async {
        final files = uploadInput.files;
        if (files != null && files.isNotEmpty) {
          final reader = html.FileReader();
          reader.readAsArrayBuffer(files.first);
          reader.onLoadEnd.listen((event) {
            Uint8List bytes = Uint8List.fromList(reader.result as List<int>);
            _processExcel(bytes);
          });
        }
      });
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        Uint8List? bytes = result.files.first.bytes;
        if (bytes != null) {
          _processExcel(bytes);
        }
      }
    }
  }

  /// Function to Process Excel File and Add Students to Database
  void _processExcel(Uint8List bytes) {
    var excelFile = excel.Excel.decodeBytes(bytes);
    var sheet = excelFile.tables.keys.first;

    for (var row in excelFile.tables[sheet]!.rows.skip(1)) {
      String? name = row[0]?.value.toString();
      int? rollNumber = int.tryParse(row[1]?.value.toString() ?? '');

      if (name != null && rollNumber != null) {
        _addStudent(name, rollNumber);
      }
    }

    flutter.ScaffoldMessenger.of(context).showSnackBar(
      flutter.SnackBar(content: flutter.Text("Students Imported Successfully!")),
    );
  }

  @override
  flutter.Widget build(flutter.BuildContext context) {
    return flutter.Scaffold(
      appBar: flutter.AppBar(title: flutter.Text('Students')),
      body: flutter.Column(
        children: [
          /// **Student List**
          flutter.Expanded(
            child: flutter.StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('students')
                  .orderBy('rollNumber')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == flutter.ConnectionState.waiting) {
                  return flutter.Center(child: flutter.CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return flutter.Center(child: flutter.Text('No students added yet.'));
                }

                var students = snapshot.data!.docs;

                return flutter.ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    var student = students[index];
                    return flutter.ListTile(
                      leading: flutter.Icon(flutter.Icons.person, color: flutter.Colors.blue),
                      title: flutter.Text(student['name']),
                      subtitle: flutter.Text('Roll No: ${student['rollNumber']}'),
                      onTap: () {
                        flutter.Navigator.push(
                          context,
                          flutter.MaterialPageRoute(
                            builder: (context) => StudentReportScreen(
                              classId: widget.classId,
                              studentId: student.id,
                              studentName: student['name'],
                              rollNumber: student['rollNumber'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          /// **Drag & Drop Feature for Web**
          if (kIsWeb)
            flutter.DragTarget<html.File>(
              onAccept: (file) async {
                final reader = html.FileReader();
                reader.readAsArrayBuffer(file);
                reader.onLoadEnd.listen((event) {
                  Uint8List bytes = Uint8List.fromList(reader.result as List<int>);
                  _processExcel(bytes);
                });
              },
              builder: (context, candidateData, rejectedData) {
                return flutter.Container(
                  height: 100,
                  margin: flutter.EdgeInsets.all(10),
                  decoration: flutter.BoxDecoration(
                    color: flutter.Colors.blue.shade100,
                    borderRadius: flutter.BorderRadius.circular(10),
                    border: flutter.Border.all(color: flutter.Colors.blue, width: 2),
                  ),
                  child: flutter.Center(
                    child: flutter.Text(
                      "Drag & Drop Excel File Here",
                      style: flutter.TextStyle(
                        fontSize: 16,
                        fontWeight: flutter.FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),

      /// **Floating Buttons (Import & Add)**
      floatingActionButton: flutter.Column(
        mainAxisAlignment: flutter.MainAxisAlignment.end,
        children: [
          /// **Import Excel Button**
          flutter.FloatingActionButton.extended(
            onPressed: _importStudents,
            icon: flutter.Icon(flutter.Icons.upload_file),
            label: flutter.Text("Import Excel"),
            backgroundColor: flutter.Colors.orange,
          ),
          flutter.SizedBox(height: 10),

          /// **Add Student Button**
          flutter.FloatingActionButton(
            onPressed: () => _showAddStudentDialog(context),
            child: flutter.Icon(flutter.Icons.add),
            backgroundColor: flutter.Colors.blue,
          ),
        ],
      ),
    );
  }

  /// Function to Show Add Student Dialog
  void _showAddStudentDialog(flutter.BuildContext context) {
    flutter.showDialog(
      context: context,
      builder: (context) => flutter.AlertDialog(
        title: flutter.Text('Add Student'),
        content: flutter.Column(
          mainAxisSize: flutter.MainAxisSize.min,
          children: [
            flutter.TextField(
              controller: _nameController,
              decoration: flutter.InputDecoration(labelText: 'Student Name'),
            ),
            flutter.TextField(
              controller: _rollNumberController,
              decoration: flutter.InputDecoration(labelText: 'Roll Number'),
              keyboardType: flutter.TextInputType.number,
            ),
          ],
        ),
        actions: [
          flutter.TextButton(
            onPressed: () => flutter.Navigator.pop(context),
            child: flutter.Text('Cancel'),
          ),
          flutter.ElevatedButton(
            onPressed: () {
              _addStudent(_nameController.text, int.tryParse(_rollNumberController.text) ?? 0);
              _nameController.clear();
              _rollNumberController.clear();
              flutter.Navigator.pop(context);
            },
            child: flutter.Text('Add'),
          ),
        ],
      ),
    );
  }
}
