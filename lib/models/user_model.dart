import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? displayName;
  final String? email;
  final String role;
  final Timestamp? lastSignIn;

  UserModel({
    required this.uid,
    this.displayName,
    this.email,
    required this.role,
    this.lastSignIn,
  });

  // Create a UserModel from a Map (e.g., Firestore document)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      displayName: map['displayName'],
      email: map['email'],
      role: map['role'] ?? 'student',
      lastSignIn: map['lastSignIn'],
    );
  }

  // Convert UserModel to a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'role': role,
      'lastSignIn': lastSignIn,
    };
  }
} 