import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream listening to auth state changes
  Stream<User?> get userStream => _auth.authStateChanges();

  // Login with email and password
  Future<UserModel?> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (cred.user != null) {
        return await getUserData(cred.user!.uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Fetch role and details from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = Map<String, dynamic>.from(doc.data() as Map<String, dynamic>);
        
        // --- Auto-promotion for MVP testing ---
        if (data['email'] == 'admin1@gmail.com' && data['role'] != 'admin') {
          await _firestore.collection('users').doc(uid).update({'role': 'admin'});
          data['role'] = 'admin';
        } else if (data['email'] == 'driver1@gmail.com' && data['role'] != 'driver') {
          await _firestore.collection('users').doc(uid).update({'role': 'driver'});
          data['role'] = 'driver';
        }
        // --------------------------------------

        return UserModel.fromMap(data, doc.id);
      } else {
        return null; // Do not auto-provision. They must use the Signup screen!
      }
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Register with email and password
  Future<UserModel?> registerWithEmailAndPassword(String email, String password, String role, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password.trim());
      User? user = result.user;
      
      if (user != null) {
        UserModel newUser = UserModel(
          uid: user.uid,
          role: role,
          name: name,
          email: email.trim(),
        );
        // Save to firestore
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
      return null;
    } catch (e) {
      rethrow; // Pass error up to show in UI
    }
  }
}
