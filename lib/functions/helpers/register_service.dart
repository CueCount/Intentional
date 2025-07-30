import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data/inputState.dart';
import '../../router/router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
      print('🔄 Starting registration process...');
      
      // CAPTURE TEMP DATA FROM SHAREDPREFERENCES BEFORE AUTHENTICATION
      final prefs = await SharedPreferences.getInstance();
      final tempId = prefs.getString('current_temp_id');
      
      print('🔍 Looking for temp_id in SharedPreferences...');
      print('Found temp_id: $tempId');
      
      if (tempId == null) {
        print('❌ No temp_id found in SharedPreferences');
        return false;
      }
      
      // Get all temp user data from SharedPreferences
      final tempUserDataString = prefs.getString('user_data_$tempId');
      print('🔍 Looking for user data with key: user_$tempId');
      print('Found temp user data string: $tempUserDataString');
      
      Map<String, dynamic> tempUserData = {};
      
      if (tempUserDataString != null) {
        tempUserData = json.decode(tempUserDataString);
        print('📦 Retrieved temp user data: $tempUserData');
      } else {
        print('⚠️ No temp user data found, but continuing with registration...');
      }
      
      print('🔄 Creating Firebase user...');
      
      // Create user with email and password
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print('✅ Firebase user created successfully');
      
      // Transfer temp data to authenticated user
      if (userCredential.user != null) {
        final authenticatedUserId = userCredential.user!.uid;
        print('🆔 Authenticated user ID: $authenticatedUserId');
        
        // Create authenticated user document in Firestore
        print('🔄 Creating user document in Firestore...');
        await _firestore.collection('users').doc(authenticatedUserId).set({
          'userId': authenticatedUserId,
          'email': email,
          'created_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        
        print('✅ Created authenticated user document in Firestore');
        
        // Transfer temp data to authenticated user
        print('🔄 About to transfer temp data...');
        await _transferTempDataToAuthenticatedUser(tempId, authenticatedUserId, tempUserData);
        print('✅ Temp data transfer completed');
        
        // Update Provider with authenticated user ID
        if (context.mounted) {
          final inputState = Provider.of<InputState>(context, listen: false);
          inputState.setUserId(authenticatedUserId);
          print('✅ Updated Provider with authenticated user ID');
          
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.basicInfo,
            (route) => false,
          );
        }
        
        return true;
      }
      
      print('❌ User credential was null');
      return false;
    } catch (e, stackTrace) {
      print('❌ Registration failed: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }
  
  // Transfer all temp data to authenticated user and destroy temp ID
  Future<void> _transferTempDataToAuthenticatedUser(
    String tempId, 
    String authenticatedUserId, 
    Map<String, dynamic> tempUserData
  ) async {
    try {
      print('🔄 Starting temp data transfer...');
      print('From temp_id: $tempId');
      print('To authenticated user: $authenticatedUserId');
      print('Data to transfer: $tempUserData');
      
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Save temp data to authenticated user in SharedPreferences
      if (tempUserData.isNotEmpty) {
        print('🔄 Saving to SharedPreferences...');
        await prefs.setString('user_$authenticatedUserId', json.encode(tempUserData));
        print('✅ Transferred SharedPreferences data from temp_id to authenticated user');
        
        // Verify it was saved
        final savedData = prefs.getString('user_$authenticatedUserId');
        print('🔍 Verification - saved data: $savedData');
      } else {
        print('⚠️ No temp user data to transfer to SharedPreferences');
      }
      
      // 2. Save temp data to authenticated user in Firestore
      if (tempUserData.isNotEmpty) {
        print('🔄 Saving to Firestore...');
        
        // Remove any data that shouldn't go to Firestore (like photoInputs)
        final firestoreData = Map<String, dynamic>.from(tempUserData);
        firestoreData.remove('photoInputs'); // Images can't be stored in Firestore
        
        print('🔍 Data going to Firestore: $firestoreData');
        
        await _firestore.collection('users').doc(authenticatedUserId).set(
          firestoreData,
          SetOptions(merge: true)
        );
        print('✅ Transferred Firestore data from temp_id to authenticated user');
      } else {
        print('⚠️ No temp user data to transfer to Firestore');
      }
      
      // 3. Destroy temp ID and its data
      print('🔄 Destroying temp data...');
      await _destroyTempId(tempId);
      print('✅ Temp data destruction completed');
      
    } catch (e, stackTrace) {
      print('❌ Error transferring temp data: $e');
      print('Stack trace: $stackTrace');
      throw e;
    }
  }
  
  // Destroy temp ID and all associated data
  Future<void> _destroyTempId(String tempId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove temp_id key
      await prefs.remove('temp_id');
      
      // Remove temp user data
      await prefs.remove('user_$tempId');
      
      print('🗑️ Destroyed temp_id: $tempId and all associated data');
      
    } catch (e) {
      print('❌ Error destroying temp_id: $e');
      throw e;
    }
  }
  
  // Helper function to get temp user data (for debugging)
  static Future<Map<String, dynamic>?> getTempUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tempId = prefs.getString('temp_id');
      
      if (tempId != null) {
        final tempUserDataString = prefs.getString('user_$tempId');
        if (tempUserDataString != null) {
          return json.decode(tempUserDataString);
        }
      }
      return null;
    } catch (e) {
      print('❌ Error getting temp user data: $e');
      return null;
    }
  }
}