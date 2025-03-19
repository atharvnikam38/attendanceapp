import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'add_class_screen.dart';
import 'class_details_screen.dart';

class ClassesScreen extends StatefulWidget {
  @override
  _ClassesScreenState createState() => _ClassesScreenState();
}

class _ClassesScreenState extends State<ClassesScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Classes'),
      ),
      body: currentUser == null
          ? Center(child: Text('User not logged in'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null || !snapshot.data!.exists) {
                  return Center(child: Text('No user data found.')); 
                }

                List<dynamic> classIds = snapshot.data!.get('classes') ?? [];

                if (classIds.isEmpty) {
                  return Center(child: Text('No classes assigned. Add a new one!'));
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .where(FieldPath.documentId, whereIn: classIds)
                      .snapshots(),
                  builder: (context, classSnapshot) {
                    if (classSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
                      return Center(child: Text('No classes found.'));
                    }

                    var classes = classSnapshot.data!.docs;

                    return ListView.builder(
                      itemCount: classes.length,
                      itemBuilder: (context, index) {
                        var classData = classes[index];
                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          child: ListTile(
                            leading: Icon(Icons.class_, size: 40, color: Colors.blue),
                            title: Text(
                              classData['className'],
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('Subject: ${classData['subject']}'),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ClassDetailsScreen(
                                    classId: classData.id,
                                    className: classData['className'],
                                    subject: classData['subject'],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddClassScreen()),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Add Class',
      ),
    );
  }
}