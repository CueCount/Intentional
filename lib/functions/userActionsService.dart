import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'helpers/saveData_service.dart';
import 'helpers/fetchData_service.dart';
import '../../data/inputState.dart';
import 'dart:convert'; 
import 'package:image_picker/image_picker.dart';
import 'helpers/photo_service.dart';
import '../router/router.dart';

class UserActions {
  
  /* = = = = = = = = =
  ID MGMT
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

  static Future<void> setCurrentUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_user_id', userId);
      print('✅ Set current user ID: $userId');
    } catch (e) {
      print('❌ Failed to set current user ID: $e');
    }
  }

  /* = = = = = = = = =
  Save to Local / Firebase 
  = = = = = = = = = */
  
  Future<void> saveNeedLocally(BuildContext context, Map<String, dynamic>? needData) async {
    try {
      // Use centralized ID function instead of _getAuthenticatedUserId
      final authenticatedUserId = await getCurrentUserId(context: context);
      
      if (authenticatedUserId == null) {throw Exception("User not authenticated");}
      
      if (needData != null) {
        await SaveDataService.saveToSharedPref(data: needData, userId: authenticatedUserId);
      }

      await setNeedsUpdated(authenticatedUserId, true);
      
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
      
      final allUserData = await FetchDataService.getUserDataFromSharedPref(authenticatedUserId);
      
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
  "StateFlags?" Services
  = = = = = = = = = */
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

  static Future<void> setNeedsUpdated(String userId, bool needsUpdated) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing user data or create empty map
      Map<String, dynamic> userData = {};
      try {
        userData = await FetchDataService.getUserDataFromSharedPref(userId);
      } catch (e) {
        print('No existing user data, creating new entry');
      }
      
      // Add/update the needsUpdated field
      userData['needsUpdated'] = needsUpdated;
      
      // Save back to SharedPreferences
      final key = 'user_data_$userId';
      await prefs.setString(key, json.encode(userData));
      
      print('✅ Set needsUpdated to $needsUpdated for user: $userId');
    } catch (e) {
      print('❌ setNeedsUpdated: Failed - $e');
    }
  }

  static Future<bool> isInfoIncomplete(String userId) async {
    try {
      Map<String, dynamic> userData = await FetchDataService.getUserDataFromSharedPref(userId);
      return userData['infoIncomplete'] ?? true; // ← ADD ?? true BACK
    } catch (e) {
      print('❌ isInfoIncomplete: Failed - $e');
      return true;
    }
  }

  Future<bool> isNeedsUpdated(String userId) async {
    try {
      Map<String, dynamic> userData = await FetchDataService.getUserDataFromSharedPref(userId);
      return userData['needsUpdated'] ?? false; // Default to false if not set
    } catch (e) {
      print('❌ isNeedsUpdated: Failed - $e');
      return false;
    }
  }

  Future<void> resetNeedsUpdated(String userId) async {
    try {
      await setNeedsUpdated(userId, false);
      print('✅ Reset needsUpdated flag for user: $userId');
    } catch (e) {
      print('❌ resetNeedsUpdated: Failed - $e');
    }
  }

  /* = = = = = = = = =
  Messages - Keep exactly as is
  = = = = = = = = = */
  Future<bool> sendMessage(
    String targetUserId,
    String content
  ) async {
    try {
      // Get existing messages or create empty array
      // Add new message to array
      // Save message locally first
      // Artificial delay to simulate network latency
      // Update message in Firestore using your existing saveUserData
      // Update local status to sent
      return true;
    } catch (e) {
      print('Error in sendMessage: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> receiveMessages(String chatId) async {
    try {
      // Get user data to know who sent the message
      // Save to local cache for offline access
      // Note: In a real app, you'd transform the stream into a list here
      // This is simplified for the example
      return [];
    } catch (e) {
      print('Error in receiveMessages: $e');
      return [];
    }
  }

  /* = = = = = = = = =
  Photos
  = = = = = = = = = */
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