import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';

class StudentHomePage extends StatefulWidget {
  final User user;

  StudentHomePage({required this.user});

  @override
  _StudentHomePageState createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Verify user's email when page loads
    _verifyUserEmail();
  }

  Future<void> _verifyUserEmail() async {
    final email = widget.user.email;
    
    if (email == null || !email.endsWith('@ceu.edu.ph')) {
      // Show error dialog and navigate back after signing out
      await _showInvalidEmailDialog();
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _showInvalidEmailDialog() async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Invalid Email"),
        content: Text("Only CEU school emails (@ceu.edu.ph) are allowed."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardPage(user: widget.user),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: widget.user.photoURL != null 
                    ? NetworkImage(widget.user.photoURL!)
                    : null,
                child: widget.user.photoURL == null 
                    ? Icon(Icons.person, size: 50)
                    : null,
              ),
              SizedBox(height: 20),
              Text(
                'Welcome, ${widget.user.displayName ?? "Student"}!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Email: ${widget.user.email}',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              Text(
                'You are logged in as a student',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _navigateToDashboard,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  child: Text(
                    'Continue',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
