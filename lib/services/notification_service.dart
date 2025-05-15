import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// DO NOT reference this function from the NotificationService class
// It needs to be declared as a top-level function only
/*
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Need to ensure Firebase is initialized for background handlers
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
  // Firebase will automatically display the notification in the system tray
}
*/

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  // final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  // Singleton pattern
  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> init() async {
    if (_initialized) return;
    
    // NOTE: Firebase Messaging functionality is disabled
    
    try {
      // Request notification permissions
      /*
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: true,
        carPlay: false,
        criticalAlert: false,
      );
      
      print('User notification settings: ${settings.authorizationStatus}');
      
      // Set up foreground notification presentation options (iOS)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      
      // Configure FCM callbacks for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Get and store the FCM token
      String? token = await _messaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        await _saveTokenToFirestore(token);
      }
      
      // Listen for token refreshes
      _messaging.onTokenRefresh.listen(_saveTokenToFirestore);
      */
      
      _initialized = true;
      print('Notification service initialized (Firebase Messaging disabled)');
    } catch (e) {
      print('Error initializing notification service: $e');
      // Don't rethrow, allow app to continue even without notifications
    }
  }
  
  // Save FCM token to Firestore for the current user
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No authenticated user, cannot save FCM token');
        return;
      }
      
      final userId = currentUser.uid;
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('FCM token saved for user: $userId');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }
  
  // Handle foreground messages
  /*
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
    
    // Firebase will automatically display the notification in the system tray
    // for Android. For iOS, we've configured foreground presentation options above.
  }
  */
  
  // Send a notification to all users about an approved item
  Future<void> sendItemApprovedNotification({
    required String itemType,
    required String itemName,
  }) async {
    try {
      // Create notification data
      final String title = 'New Item Update';
      final String body = itemType == 'found' 
          ? 'Hey! A $itemName has been found!' 
          : 'Hey! A $itemName has been reported lost!';
      
      // Save notification to Firestore for in-app notifications
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': title,
        'body': body,
        'itemType': itemType,
        'itemName': itemName,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });
      
      print('Notification saved to Firestore');
      
      // Note: Firebase Cloud Messaging functionality is disabled
    } catch (e) {
      print('Error sending notification: $e');
    }
  }
} 