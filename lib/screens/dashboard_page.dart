import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'search_results_page.dart';
import 'report_lost_item_page.dart';
import 'report_found_item_page.dart';
import 'notifications_page.dart';

class DashboardPage extends StatelessWidget {
  final User user;

  const DashboardPage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the primary color from theme to match main.dart
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Color(0xFFFFF0F5), // Light pink background
      appBar: AppBar(
        backgroundColor: Color(0xFFFFF0F5), // Same as background
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.black),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationsPage(user: user),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black),
            onPressed: () {
              // User profile action
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // App logo
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 40),
            
            // Search Items button
            _buildActionButton(
              context,
              icon: Icons.search,
              label: 'Search items',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SearchResultsPage(user: user),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Report Lost Item button
            _buildActionButton(
              context,
              icon: Icons.assignment_late,
              label: 'Report Lost Item',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportLostItemPage(user: user),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Report Found Item button
            _buildActionButton(
              context,
              icon: Icons.check_circle_outline,
              label: 'Report Found Item',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportFoundItemPage(user: user),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFFFF4081), // Pink color
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          minimumSize: Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 