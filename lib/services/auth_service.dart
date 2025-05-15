import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'firebase_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    signInOption: SignInOption.standard
  );
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check Firebase configuration
  Future<bool> checkFirebaseConfig() async {
    try {
      // Try to get current user
      final user = _auth.currentUser;
      print('Firebase Auth initialized: ${_auth != null}');
      print('Current user: ${user?.uid ?? 'No user logged in'}');
      
      // Try to access Firestore
      try {
        await _firestore.collection('test').doc('test').get();
        print('Firestore connection successful');
      } catch (e) {
        // If the error is permission-denied, that's expected when not authenticated
        if (e.toString().contains('permission-denied')) {
          print('Firestore connection successful (permission denied as expected)');
        } else {
          print('Firestore connection error: $e');
        }
      }
      
      return true;
    } catch (e) {
      print('Firebase config error: $e');
      return false;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      // First, ensure we're signed out to avoid cached state issues
      await _googleSignIn.signOut();
      await _auth.signOut();
      
      // Start sign in process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      // User cancelled the sign-in flow
      if (googleUser == null) {
        print("Sign in cancelled");
        return null;
      }
      
      print("Google account selected: ${googleUser.email}");
      
      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      // Sign in to Firebase
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      
      if (user != null) {
        // Check for CEU email
        if (user.email != null && user.email!.toLowerCase().endsWith('@ceu.edu.ph')) {
          // Valid CEU email, save user data
          await _saveUserToFirestore(user, 'student');
          return user;
        } else {
          // Not a CEU email, sign out
          print("Non-CEU email detected: ${user.email}");
          await _auth.signOut();
          await _googleSignIn.signOut();
          
          // Show error dialog
          if (context.mounted) {
            _showInvalidEmailDialog(context);
          }
          
          return null;
        }
      }
      
      return null;
    } catch (e) {
      print("Error during Google sign in: $e");
      
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-in failed. Please try again.")),
        );
      }
      
      return null;
    }
  }
  
  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email, 
    String password,
    BuildContext context
  ) async {
    try {
      // Check domain
      if (!email.endsWith('@ceu.edu.ph')) {
        if (context.mounted) {
          _showInvalidEmailDialog(context);
        }
        return null;
      }
      
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update last sign in time
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!, 'student');
      }
      
      return userCredential;
    } catch (e) {
      print('Error signing in with email/password: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sign-in failed: ${_getAuthErrorMessage(e)}")),
        );
      }
      
      return null;
    }
  }
  
  // Create account with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email, 
    String password,
    BuildContext context
  ) async {
    try {
      // Check domain
      if (!email.endsWith('@ceu.edu.ph')) {
        if (context.mounted) {
          _showInvalidEmailDialog(context);
        }
        return null;
      }
      
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Save user data to Firestore
      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!, 'student');
      }
      
      return userCredential;
    } catch (e) {
      print('Error creating user with email/password: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Registration failed: ${_getAuthErrorMessage(e)}")),
        );
      }
      
      return null;
    }
  }

  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User user, String role) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'displayName': user.displayName ?? user.email?.split('@')[0],
      'email': user.email,
      'role': role,
      'lastSignIn': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
  
  // Verify current user has valid CEU email
  Future<bool> verifyCurrentUserEmailDomain() async {
    final User? user = _auth.currentUser;
    
    if (user != null) {
      final String? email = user.email;
      
      if (email != null && email.endsWith('@ceu.edu.ph')) {
        // Valid CEU email
        return true;
      } else {
        // Invalid email, sign out
        print('Non-CEU email detected: $email');
        await signOut();
        return false;
      }
    }
    
    // No user signed in
    return false;
  }
  
  // Show invalid email dialog
  void _showInvalidEmailDialog(BuildContext context) {
    showDialog(
      context: context,
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
  
  // Get user-friendly error message from Firebase Auth exceptions
  String _getAuthErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Incorrect password';
        case 'email-already-in-use':
          return 'Email already in use';
        case 'weak-password':
          return 'Password is too weak';
        case 'invalid-email':
          return 'Invalid email format';
        case 'operation-not-allowed':
          return 'Operation not allowed';
        case 'user-disabled':
          return 'This account has been disabled';
        case 'too-many-requests':
          return 'Too many attempts. Try again later';
        case 'network-request-failed':
          return 'Network error. Check your connection';
        default:
          return error.message ?? 'An unknown error occurred';
      }
    }
    return 'An unexpected error occurred';
  }

  // Workaround for PigeonUserDetails error and dependency version issues
  Future<Map<String, dynamic>> signInWithEmailPasswordWorkaround({
    required String email,
    required String password,
    required BuildContext context,
    required Function(BuildContext, {required String message, required String errorInfo}) showFlutterToast,
  }) async {
    UserCredential? credentials;
    bool success = false;
    UserModel? userModel;

    try {
      // Check domain
      if (!email.endsWith('@ceu.edu.ph')) {
        if (context.mounted) {
          _showInvalidEmailDialog(context);
        }
        return {'success': false, 'user': null};
      }

      try {
        credentials = await FirebaseAuth.instance
            .signInWithEmailAndPassword(email: email, password: password);
      } on FirebaseAuthException catch (ex) {
        Navigator.pop(context);
        showFlutterToast(
          context,
          message: ex.message.toString(), 
          errorInfo: 'error'
        );
        return {'success': false, 'user': null};
      } catch (e) {
        print("Creds: $credentials, Error: $e");
      }

      if (credentials != null) {
        String uid = credentials.user!.uid;
        DocumentSnapshot userData =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();
        userModel = UserModel.fromMap(userData.data() as Map<String, dynamic>);
        success = true;
      } else {
        // Fallback — still try to get user from currentUser
        User? currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          userModel = await FirebaseHelper.getUserModelById(currentUser.uid);
          success = userModel != null;
        }
      }

      // Update last sign in time if login succeeded
      if (success && credentials?.user != null) {
        await _saveUserToFirestore(credentials!.user!, 'student');
      }

      return {'success': success, 'user': userModel};
    } catch (e) {
      print('Error in sign in workaround: $e');
      if (context.mounted) {
        showFlutterToast(
          context,
          message: "Sign-in failed: ${_getAuthErrorMessage(e)}", 
          errorInfo: 'error'
        );
      }
      return {'success': false, 'user': null};
    }
  }
} 