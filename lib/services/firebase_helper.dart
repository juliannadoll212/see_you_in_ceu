import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirebaseHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a UserModel by user ID
  static Future<UserModel?> getUserModelById(String uid) async {
    try {
      DocumentSnapshot documentSnapshot = 
          await _firestore.collection('users').doc(uid).get();
      
      if (documentSnapshot.exists) {
        return UserModel.fromMap(documentSnapshot.data() as Map<String, dynamic>);
      } else {
        print("No user found with UID: $uid");
        return null;
      }
    } catch (e) {
      print("Error getting user: $e");
      return null;
    }
  }
} 