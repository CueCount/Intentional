import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Register a new user with email and password
  Future<bool> registerAuth(
    BuildContext context,
    String email, 
    String password,
  ) async {
    
    try {
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Associate with authenticated user
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'userId': userCredential.user!.uid,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('Associated temp document with auth user: ${userCredential.user!.uid}');
        
        return true;
      }
      return false;
    } catch (e) {
      print('Registration failed: $e');
      return false;
    }
  }
}