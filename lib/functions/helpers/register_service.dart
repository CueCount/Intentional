import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data/inputState.dart';
import '../../router/router.dart';
import 'fetchData_service.dart';
import 'saveData_service.dart';
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
    
    final prefs = await SharedPreferences.getInstance();
    final tempId = prefs.getString('current_temp_id');
    
    print('Found temp_id: $tempId');
    
    if (tempId == null) {
      print('❌ No temp_id found in SharedPreferences');
      return false;
    }
    
    // Get all temp user data from SharedPreferences
    final tempUserDataString = prefs.getString('user_data_$tempId');
    print('Found temp user data string: $tempUserDataString');
    
    Map<String, dynamic> tempUserData = {};
    
    if (tempUserDataString != null) {
      tempUserData = json.decode(tempUserDataString);
    } else {
      print('⚠️ No temp user data found, but continuing with registration...');
    }
          
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
      
      // Transfer temp data to authenticated user
      await _transferTempDataToAuthenticatedUser(tempId, authenticatedUserId, tempUserData, email);
      print('✅ Temp data transfer completed');
      
      // Fetch fresh data from Firebase and populate SharedPreferences
      final freshData = await FetchDataService.fetchSessionDataFromFirebase(authenticatedUserId);
      if (freshData.isNotEmpty) {
        final cleanedData = cleanUserData(freshData);
        await SaveDataService.saveToSharedPref(data: cleanedData, userId: authenticatedUserId);
        print('✅ Fresh data loaded from Firebase to SharedPreferences');
      }
      
      // Clear Provider data to avoid confusion
      if (context.mounted) {
        final inputState = Provider.of<InputState>(context, listen: false);
        inputState.clearAllData();
        print('✅ Cleared Provider data for fresh start');
        
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
    Map<String, dynamic> tempUserData,
    String email
  ) async {
    try {
      print('🔄 Starting temp data transfer...');
      print('From temp_id: $tempId');
      print('To authenticated user: $authenticatedUserId');
      print('Data to transfer: $tempUserData');
      
      final prefs = await SharedPreferences.getInstance();
      
      if (tempUserData.isNotEmpty) {
        print('🔄 Saving to Firestore...');
        final firestoreData = Map<String, dynamic>.from(tempUserData);
        // Add essential fields
        firestoreData['userId'] = authenticatedUserId;
        firestoreData['email'] = email;
        firestoreData['created_at'] = FieldValue.serverTimestamp();
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
      await prefs.remove('current_temp_id');
      
      // Remove temp user data
      await prefs.remove('user_data_$tempId');
      
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
        final tempUserDataString = prefs.getString('user_data_$tempId');
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