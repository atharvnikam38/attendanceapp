import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'home_screen.dart';
import 'otp_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _obscurePassword = true; // Toggle for password visibility
  String _errorMessage = "";

  // Mailgun Credentials
  final String mailgunApiKey =
      "44d05a3aa7a46b91790867dc1edcf79c-2b77fbb2-07b2f2c6";
  final String mailgunDomain =
      "sandboxc68d16d2f1a24ffebce48ef5266f5770.mailgun.org";

  Future<void> _sendOTP(String email, String otp) async {
    String apiUrl = "https://api.mailgun.net/v3/$mailgunDomain/messages";

    Map<String, String> headers = {
      "Authorization":
          "Basic ${base64Encode(utf8.encode('api:$mailgunApiKey'))}",
      "Content-Type": "application/x-www-form-urlencoded",
    };

    Map<String, String> body = {
      "from": "Attendance App <mailgun@$mailgunDomain>",
      "to": email,
      "subject": "Your OTP Code",
      "text": "Your OTP code is: $otp",
    };

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: headers,
        body: body,
      );
      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = "Error sending OTP: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error sending OTP: ${e.toString()}";
      });
    }
  }

  void _login() async {
    setState(() {
      _errorMessage = "";
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        String otp = (100000 + Random().nextInt(900000)).toString();
        await _sendOTP(_emailController.text.trim(), otp);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    OtpScreen(email: _emailController.text.trim(), otp: otp),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Login Error: ${e.toString()}";
      });
    }
  }

  void _register() async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'name': _emailController.text.split('@')[0], // Basic username
            'email': _emailController.text.trim(),
            'createdAt': Timestamp.now(),
            'classes': [],
          });

      setState(() {
        _errorMessage = "Account created. Please log in.";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Registration Error: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock, size: 50, color: Colors.blue),
                    SizedBox(height: 10),
                    Text(
                      "Login to Your Account",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 20),

                    // Email Field
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 15),

                    // Password Field with Visibility Toggle
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),

                    // Error Message
                    if (_errorMessage.isNotEmpty)
                      Text(_errorMessage, style: TextStyle(color: Colors.red)),

                    SizedBox(height: 20),

                    // Login Button
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Login",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),

                    SizedBox(height: 10),

                    // Register Button
                    TextButton(
                      onPressed: _register,
                      child: Text("Don't have an account? Register here"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
