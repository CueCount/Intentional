import 'package:flutter/material.dart';
import 'dart:async';
import 'helpers/saveData_service.dart';
import 'helpers/fetchData_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/inputState.dart';

class UserActions {
  /* = = = = = = = = =
  Saving Inputs
  = = = = = = = = = */
  Future<void> saveNeedLocally(BuildContext context, Map<String, dynamic>? needData) async {
    try {
      final authenticatedUserId = await _getAuthenticatedUserId(context);
      
      if (authenticatedUserId == null) {throw Exception("User not authenticated");}
      
      if (needData != null) {await SaveDataService.saveToSharedPref(data: needData, userId: authenticatedUserId);}
      
      print("✅ saveNeedLocally: Success");
      
    } catch (e) {
      print('❌ saveNeedLocally: Failed - $e');
      throw e;
    }
  }

  Future<void> saveNeedToFirebase(BuildContext context) async {
    try {
      final authenticatedUserId = await _getAuthenticatedUserId(context);
      
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
    final userId = inputState.userId;
    
    List<InputPhoto> photos = inputState.photoInputs;
    
    if (photos.isEmpty) {
      print('⚠️ No photos to save for user: $userId');
      return;
    }
    
    Map<String, dynamic> photoData = {'photos': photos};
    await SaveDataService().handleSubmit(context, photoData);
    
    print('✅ ${photos.length} photos saved to Firebase for user: $userId');
    
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
  Messages
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
  Temporary Helpers
  = = = = = = = = = */
  static Future<bool> hasFieldData(String fieldKey) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Handle photos separately if stored as list
    if (fieldKey == 'photos') {
      List<String>? photos = prefs.getStringList(fieldKey);
      return photos?.isNotEmpty ?? false;
    }
    
    // Handle regular string fields
    String? value = prefs.getString(fieldKey);
    return value?.isNotEmpty ?? false;
  }

  Future<String?> _getAuthenticatedUserId(BuildContext context) async {
    try {
      // First check Firebase Auth
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
        return firebaseUser.uid;
      }
      
      // Fallback to Provider if available
      final inputState = Provider.of<InputState>(context, listen: false);
      if (inputState.userId.isNotEmpty && !inputState.userId.startsWith('temp_')) {
        return inputState.userId;
      }
      
      return null;
      
    } catch (e) {
      print("❌ _getAuthenticatedUserId: Failed - $e");
      return null;
    }
  }
}