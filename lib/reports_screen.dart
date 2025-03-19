import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class ReportsScreen extends StatefulWidget {
  final String classId;
  ReportsScreen({required this.classId});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Map<String, Map<String, dynamic>> studentAttendance = {};
  List<Map<String, dynamic>> defaulters = [];
  int totalSessions = 0;

  @override
  void initState() {
    super.initState();
    _updateReports();
  }

  void _updateReports() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('attendance')
        .get();

    totalSessions = snapshot.docs.length;
    studentAttendance.clear();
    defaulters.clear();

    var studentsSnapshot = await FirebaseFirestore.instance
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

    studentAttendance.forEach((studentId, data) {
      double percentage =
          data['total'] > 0 ? (data['present'] / data['total']) * 100 : 0;
      if (percentage < 50) {
        defaulters.add({
          'name': data['name'],
          'rollNumber': data['rollNumber'],
          'percentage': percentage,
        });
      }
    });

    setState(() {});
  }

  Future<void> _downloadExcelReport() async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Attendance Report'];

    // Header Row
    sheet.appendRow([
      TextCellValue("Roll Number"),
      TextCellValue("Name"),
      TextCellValue("Attendance"),
      TextCellValue("Attendance %"),
    ]);

    // Data Rows
    for (var entry in studentAttendance.values) {
      int rollNumber = entry['rollNumber'];
      String name = entry['name'];
      int present = entry['present'];
      int total = entry['total'];
      double percentage = total > 0 ? (present / total) * 100 : 0;

      sheet.appendRow([
        TextCellValue(rollNumber.toString()),
        TextCellValue(name),
        TextCellValue("$present/$total"),
        TextCellValue("${percentage.toStringAsFixed(2)}%"),
      ]);
    }

    List<int>? fileBytes = excel.encode();
    if (fileBytes == null) return;

    if (kIsWeb) {
      // Web Download
      final blob = html.Blob([Uint8List.fromList(fileBytes)],
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "Attendance_Report.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile Download
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Storage permission denied.")),
        );
        return;
      }

      Directory directory;
      if (Platform.isAndroid) {
        directory = (await getExternalStorageDirectory())!;
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      String filePath = "${directory.path}/Attendance_Report.xlsx";
      File(filePath).writeAsBytesSync(fileBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excel downloaded: $filePath")),
      );
    }
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
              child: Column(
                children: [
                  Text('Total Sessions: $totalSessions',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                ],
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: studentAttendance.keys.length,
              itemBuilder: (context, index) {
                var data = studentAttendance.values.elementAt(index);
                double attendancePercentage = data['total'] > 0
                    ? (data['present'] / data['total']) * 100
                    : 0;

                return ListTile(
                  title: Text('${data['name']} (Roll No: ${data['rollNumber']})',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      'Attendance: ${data['present']}/${data['total']} (${attendancePercentage.toStringAsFixed(2)}%)'),
                );
              },
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: studentAttendance.entries.map((entry) {
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
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _downloadExcelReport,
              icon: Icon(Icons.download),
              label: Text("Download Excel"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            if (defaulters.isNotEmpty)
              Column(
                children: [
                  Text('Defaulters (Attendance < 50%)',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: defaulters.length,
                    itemBuilder: (context, index) {
                      var data = defaulters[index];
                      return ListTile(
                        title: Text('${data['name']} (Roll No: ${data['rollNumber']})',
                            style:
                                TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        subtitle: Text('Attendance: ${data['percentage'].toStringAsFixed(2)}%'),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
