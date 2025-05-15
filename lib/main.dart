import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';

import 'firebase_options.dart';
import 'screens/student_login_page.dart';
import 'screens/admin_login_page.dart';
import 'services/notification_service.dart';

// Define the background message handler at the top level
/* 
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized
  await Firebase.initializeApp();
  print('Background message: ${message.notification?.title}');
}
*/

void main() {
  // Add exception catching for diagnostic purposes
  FlutterError.onError = (FlutterErrorDetails details) {
    print('FLUTTER ERROR: ${details.exception}');
    print('STACK TRACE: ${details.stack}');
    FlutterError.presentError(details);
  };
  
  // Add global error handling for uncaught async errors
  runZonedGuarded(
    () async {
      print('App starting...');
      WidgetsFlutterBinding.ensureInitialized();
      print('Flutter binding initialized');
      
      try {
        // Initialize Firebase with the generated options
        final app = await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        
        print('Firebase initialized successfully with projectId: ${app.options.projectId}');
        
        // Initialize Firestore settings for better performance
        FirebaseFirestore.instance.settings = Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        
        print('Firestore settings configured');
        
        // Initialize Firebase Messaging background handler
        // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        
        // Initialize notification service
        await NotificationService().init();
        print('Notification service initialized completely');
        
        runApp(const MyApp());
        print('App launched successfully');
      } catch (e, stackTrace) {
        print('STARTUP ERROR: $e');
        print('STACK TRACE: $stackTrace');
        
        // Try to run the app without Firebase as fallback
        print('Attempting to launch app without dependencies...');
        runApp(const FallbackApp());
      }
    },
    (error, stackTrace) {
      print('UNHANDLED ERROR: $error');
      print('STACK TRACE: $stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Add performance optimizations
    return MaterialApp(
      title: 'See You In CEU',
      debugShowCheckedModeBanner: false,
      
      // Add these performance optimizations
      themeMode: ThemeMode.light, // Use light theme to reduce rendering complexity
      
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.white,
        visualDensity: VisualDensity.adaptivePlatformDensity, // Optimize for platform
        
        // Optimize image caching
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.pink)
            .copyWith(secondary: Colors.pinkAccent),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('See You in CEU test ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Use precacheImage for better performance
            FutureBuilder(
              future: precacheImage(AssetImage('assets/logo.png'), context),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Image.asset(
                    'assets/logo.png',
                    width: 200, // Reduced from 250 for faster loading
                    height: 200, // Reduced from 250 for faster loading
                    fit: BoxFit.contain,
                  );
                } else {
                  return SizedBox(
                    width: 200,
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
              },
            ),
            SizedBox(height: 20),
            Text('Welcome!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentLoginPage()),
                );
              },
              child: Text('Login as a User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 65, 128),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminLoginPage()),
                );
              },
              child: Text('Login as Admin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 65, 128),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                textStyle: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Student Login Page is no longer needed as we directly navigate to StudentHomePage now

// Simple fallback app in case of critical errors
class FallbackApp extends StatelessWidget {
  const FallbackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'See You In CEU',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Application Error',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Please restart the app or contact support.'),
            ],
          ),
        ),
      ),
    );
  }
}
