import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddClassScreen extends StatefulWidget {
  @override
  _AddClassScreenState createState() => _AddClassScreenState();
}

class _AddClassScreenState extends State<AddClassScreen> {
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final CollectionReference classesRef = FirebaseFirestore.instance.collection('classes');

  void _saveClass() async {
    String className = _classNameController.text.trim();
    String subject = _subjectController.text.trim();
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (className.isNotEmpty && subject.isNotEmpty && currentUser != null && currentUser.uid.isNotEmpty) {
      DocumentReference newClassRef = await classesRef.add({
        'className': className,
        'subject': subject,
        'teachers': [currentUser.uid], // Assign the logged-in teacher
      });

      // Update the teacher's document to reference this new class
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
        'classes': FieldValue.arrayUnion([newClassRef.id]),
      });

      Navigator.pop(context); // Go back to Classes Screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add New Class')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _classNameController,
              decoration: InputDecoration(
                labelText: 'Class Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveClass,
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}