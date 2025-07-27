import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../data/inputState.dart';
import 'saveData_service.dart';
import '../router/router.dart';

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
      // CAPTURE ALL DATA BEFORE AUTHENTICATION (while context is still valid)
      final inputState = Provider.of<InputState>(context, listen: false);
      final allInputs = inputState.getCachedInputs();
      
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Associate with authenticated user
      if (userCredential.user != null) {
        final userId = userCredential.user!.uid;
        
        await _firestore.collection('users').doc(userId).set({
          'userId': userId,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('Associated temp document with auth user: $userId');
        
        // Save all inputs using the captured data (no context needed)
        await _saveInputsWithoutContext(allInputs, userId);

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.basicInfo, // or whatever your route name is for Basic_info.dart
          (route) => false,
        );
        
        return true;
      }
      return false;
    } catch (e) {
      print('Registration failed: $e');
      return false;
    }
  }
  
  Future<void> _saveInputsWithoutContext(Map<String, dynamic> allInputs, String userId) async {
    try {
      await SaveDataService.saveToSharedPref(
        data: allInputs, 
        userId: userId,
      );
      final inputsToSave = Map<String, dynamic>.from(allInputs);
      inputsToSave.remove('photoInputs');
      await _firestore.collection('users').doc(userId).set(
        inputsToSave,
        SetOptions(merge: true)
      );
      print('✅ Successfully saved all inputs for user: $userId');
    } catch (e) {
      print('❌ Error saving inputs without context: $e');
      throw e;
    }
  }
}