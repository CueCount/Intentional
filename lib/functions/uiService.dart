import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'helpers/saveData_service.dart';
import 'helpers/fetchData_service.dart';
import '../providers/inputState.dart';
import 'dart:convert'; 
import 'package:image_picker/image_picker.dart';
import 'helpers/photo_service.dart';
import '../router/router.dart';

class UserActions {
  
  /* = = = = = = = = =
  ID Management
  = = = = = = = = = */
  
  static Future<String?> getCurrentUserId({BuildContext? context}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check Firebase Auth first (highest priority for authenticated users)
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
        print('📱 Using Firebase Auth ID: ${firebaseUser.uid}');
        // Optionally save to SharedPreferences for quick access
        await prefs.setString('current_user_id', firebaseUser.uid);
        return firebaseUser.uid;
      }
      
      // 2. Check stored current user ID
      String? userId = prefs.getString('current_user_id');
      if (userId != null && userId.isNotEmpty && !userId.startsWith('temp_')) {
        print('📱 Using stored user ID: $userId');
        return userId;
      }
      
      // 3. Check for temp ID (for onboarding users)
      userId = prefs.getString('current_temp_id');
      if (userId != null && userId.isNotEmpty) {
        print('📱 Using temp ID: $userId');
        return userId;
      }
      
      // 4. Fallback to Provider if context available
      if (context != null) {
        try {
          final inputState = Provider.of<InputState>(context, listen: false);
          if (inputState.userId.isNotEmpty) {
            print('📱 Using Provider ID as fallback: ${inputState.userId}');
            return inputState.userId;
          }
        } catch (e) {
          print('❌ Provider fallback failed: $e');
        }
      }
      
      print('⚠️ No user ID found anywhere');
      return null;
      
    } catch (e) {
      print('❌ getCurrentUserId failed: $e');
      return null;
    }
  }

  /* = = = = = = = = =
  Save to Local / Firebase 
  = = = = = = = = = */
  
  Future<void> saveNeedLocally(BuildContext context, Map<String, dynamic>? needData) async {
    try {
      final authenticatedUserId = await getCurrentUserId(context: context);
      if (authenticatedUserId == null) {throw Exception("User not authenticated");}
      if (needData != null) {
        await SaveDataService.saveToSharedPref(data: needData, userId: authenticatedUserId);
      }
      await setStatus(authenticatedUserId, {
        'needsUpdated': true,
      });
      print("✅ saveNeedLocally: Success");
    } catch (e) {
      print('❌ saveNeedLocally: Failed - $e');
      throw e;
    }
  }

  Future<void> saveNeedToFirebase(BuildContext context) async {
    try {
      // Use centralized ID function
      final authenticatedUserId = await getCurrentUserId(context: context);
      
      if (authenticatedUserId == null) {throw Exception("User not authenticated");}
      
      final allUserData = await FetchDataService.fetchUserFromSharedPreferences(authenticatedUserId);
      
      await SaveDataService.saveToFirestore(data: allUserData, userId: authenticatedUserId);
      
      print("✅ saveNeedToFirebase: Success");
      
    } catch (e) {
      print('❌ saveNeedToFirebase: Failed - $e');
      throw e;
    }
  }

  Future<void> savePhotosToFirebase(BuildContext context) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      // Use centralized ID function
      final authenticatedUserId = await getCurrentUserId(context: context);
      if (authenticatedUserId == null) {
        throw Exception("User not authenticated");
      }
      
      List<InputPhoto> photos = inputState.photoInputs;
      
      if (photos.isEmpty) {
        print('⚠️ No photos to save for user: $authenticatedUserId');
        return;
      }
      
      Map<String, dynamic> photoData = {'photos': photos};
      
      await SaveDataService.saveToFirestore(data: photoData, userId: authenticatedUserId);

      print('✅ ${photos.length} photos saved to Firebase for user: $authenticatedUserId');
      
    } catch (e) {
      print('❌ savePhotosToFirebase: Failed - $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving photos: $e')),
        );
      }
    }
  }

  /* = = = = = = = = =
  Status Services
  = = = = = = = = = */

  static Future<void> setStatus(String userId, Map<String, bool> flags) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      Map<String, dynamic> userData = {};
      try {
        userData = await FetchDataService.fetchUserFromSharedPreferences(userId);
      } catch (e) {
        print('No existing user data, creating new entry');
      }
      
      flags.forEach((fieldName, value) {
        userData[fieldName] = value;
      });
      
      final key = 'user_data_$userId';
      await prefs.setString(key, json.encode(userData));
      print('✅ Set flags $flags for user: $userId');
    } catch (e) {
      print('❌ setUserFlags: Failed - $e');
    }
  }

  static Future<Map<String, bool>> readStatus(String userId, List<String> statusNames) async {
  try {
    Map<String, dynamic> userData = await FetchDataService.fetchUserFromSharedPreferences(userId);
    
    Map<String, bool> currentStatus = {};
    for (String statusName in statusNames) {
      if (userData.containsKey(statusName)) {
        currentStatus[statusName] = userData[statusName];
      }
    }
    
    print('✅ Read status $currentStatus for user: $userId');
    return currentStatus;
    
  } catch (e) {
    print('❌ readUserStatus: Failed - $e');
    return {}; 
  }
}

  /* = = = = = = = = =
  Utilities
  = = = = = = = = = */

  int calculateAge(dynamic birthDateValue) {
    if (birthDateValue == null) return 0;
    
    DateTime birthDate;
    
    // Handle different input types
    if (birthDateValue is int) {
      // Convert milliseconds timestamp to DateTime
      birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateValue);
    } else if (birthDateValue is String) {
      // Try to parse string as int first, then as DateTime string
      try {
        int timestamp = int.parse(birthDateValue);
        birthDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (e) {
        try {
          birthDate = DateTime.parse(birthDateValue);
        } catch (e) {
          return 0; // Return 0 if parsing fails
        }
      }
    } else if (birthDateValue is DateTime) {
      birthDate = birthDateValue;
    } else {
      return 0; // Return 0 for unsupported types
    }
    
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    
    // Check if birthday hasn't occurred this year yet
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  Future<void> sendPhotoToCrop(BuildContext context) async {
    try {
      final XFile? selectedImage = await PhotoService.pickImage(context);
      if (selectedImage != null) {
        Navigator.pushNamed(context, AppRoutes.photoCrop, arguments: {'imageFile': selectedImage,},);
      }
      if (selectedImage == null) { 
        return; 
      }
    } catch (e) {
      print('Error in upload photo process: $e');
    }
  }

}