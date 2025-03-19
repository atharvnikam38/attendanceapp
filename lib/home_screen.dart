import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'classes_screen.dart';
import 'timetable_screen.dart';
import 'reports_home_screen.dart';

class HomeScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${currentUser?.email ?? "User"}! ',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildHomeCard(Icons.class_, 'Classes', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ClassesScreen()),
                    );
                  }),
                  _buildHomeCard(Icons.schedule, 'Timetable', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TimetableScreen()),
                    );
                  }),
                  _buildHomeCard(Icons.bar_chart, 'Reports', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportsHomeScreen()),
                    );
                  }),
                  _buildHomeCard(Icons.logout, 'Logout', () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard(IconData icon, String title, VoidCallback onTap) {
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
