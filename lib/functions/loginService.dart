import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/router/router.dart';
import 'helpers/fetchData_service.dart';
import 'dart:math';
import 'dart:convert'; 

class AccountService {

  /* = = = = = = = = = 
  Temporary ID Services 
  = = = = = = = = = */
  static Future<String> createUserId() async {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random(); // You'll need to import 'dart:math'
    
    // Create a truly random 28-character ID with temp prefix
    final randomId = List.generate(28, (index) => chars[random.nextInt(chars.length)]).join();
    
    return 'temp_$randomId';
  }

  static Future<void> setInfoIncomplete(String userId, bool isIncomplete) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing user data
    Map<String, dynamic> userData = await FetchDataService.getUserDataFromSharedPref(userId);
    
    // Add/update the infoIncomplete field
    userData['infoIncomplete'] = isIncomplete;
    
    // Save back to SharedPreferences
    final key = 'user_data_$userId';
    await prefs.setString(key, json.encode(userData));
    
    print('✅ Set infoIncomplete to $isIncomplete for user: $userId');
  } catch (e) {
    print('❌ setInfoIncomplete: Failed - $e');
  }
}

  static Future<bool> isInfoIncomplete(String userId) async {
    try {
      Map<String, dynamic> userData = await FetchDataService.getUserDataFromSharedPref(userId);
      return userData['infoIncomplete'] ?? true; // Default to true if not set
    } catch (e) {
      print('❌ isInfoIncomplete: Failed - $e');
      return true;
    }
  }

  /* = = = = = = = = = 
  Get Current User Id 
  = = = = = = = = = */
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String> getCurrentUserId() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    } else {
      return await AccountService.createUserId();
    }
  }

  /* = = = = = = = = =
  Logout Account
  = = = = = = = = = */
  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }

  /* = = = = = = = = =
  Login Account
  = = = = = = = = = */
  Future<void> login(BuildContext context, String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw 'Please fill all fields';
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user != null) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  
}
