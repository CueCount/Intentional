import 'package:flutter/material.dart';
import 'dart:async';
import 'saveData_service.dart';
import 'fetchData_service.dart';
import 'matches_service.dart';
import 'register_service.dart';
import 'login_service.dart';
import 'package:image_picker/image_picker.dart';
import 'photo_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../data/inputState.dart';
import '../router/router.dart';
enum DataSource { cache, firebase }

class AirTrafficController {
  
  /* = = = = = = = = =
  Save Needs to Local
  = = = = = = = = = */
  Future<void> addedNeed(BuildContext context, Map<String, dynamic>? needData) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      // STEP 1: If userId isn't already set in memory
      if (inputState.userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        // STEP 2: Check Firebase Auth session
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null && firebaseUser.uid.isNotEmpty) {
          // Authenticated session — use Firebase UID
          inputState.setUserId(firebaseUser.uid);
          prefs.setString('userId', firebaseUser.uid);
        } else {
          String tempUserId = prefs.getString('userId') ?? await AccountService.createUserId();
          prefs.setString('userId', tempUserId);
          inputState.setUserId(tempUserId);
        }
      }
      // STEP 3: Save the input
      if (needData != null) {
        SaveDataService.saveToInputState(context: context, data: needData);
      }
    } catch (e) {
      print('Error in addedNeed: $e');
      throw e;
    }
  }
  Future<void> uploadPhoto(BuildContext context) async {
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
  
  /* = = = = = = = = =
  Save Needs to Firebase
  = = = = = = = = = */
  Future<void> saveAllInputs(BuildContext context) async {
    // 1. Gather current inputs from the Provider
    final allInputs = SaveDataService.fetchFromInputState(context);
    // 2. Save to SharedPreferences
    final inputState = Provider.of<InputState>(context, listen: false);
    SaveDataService.saveToSharedPref(data: allInputs, userId: inputState.userId,); 
    // 3. Save to Firestore
    await SaveDataService().handleSubmit(context, allInputs);
  }
  
  /* = = = = = = = = =
  Fetch Users (Unified)
  = = = = = = = = = */
  Future<List<Map<String, dynamic>>> discoverProfiles({
    DataSource source = DataSource.cache,
    bool onlyWithPhotos = false,
    bool forceFresh = false,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      List<Map<String, dynamic>> profiles = [];
      switch (source) {
        case DataSource.cache:
          profiles = await FetchDataService().fetchUserProfilesFromSharedPreferences();
          break;
        case DataSource.firebase:
          if (forceFresh) {
            await _clearUserCache();
          }
          profiles = await FetchDataService().fetchUsersFromFirebase(
            onlyWithPhotos: onlyWithPhotos,
            additionalFilters: additionalFilters,
          );
          final cleanedUsers = profiles.map((user) => cleanUserData(user)).toList();
          await SaveDataService().cacheFetchedProfilesToSharedPrefs(cleanedUsers);
          profiles = cleanedUsers;
          break;
      }
      print('📱 Discovered ${profiles.length} profiles from ${source.name}');
      return profiles;
    } catch (e) {
      print('❌ Error discovering profiles: $e');
      return [];
    }
  }

  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('user_data_')).toList();
      for (var key in keys) {
        await prefs.remove(key);
      }
      print('🧹 Cleared ${keys.length} cached user profiles');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

  // Convenience methods for backward compatibility and cleaner calling
  Future<List<Map<String, dynamic>>> discoverFromCache() async {
    return await discoverProfiles(source: DataSource.cache);
  }
  Future<List<Map<String, dynamic>>> discoverFromFirebase({
    bool onlyWithPhotos = true,
    bool forceFresh = false,
    Map<String, dynamic>? additionalFilters,
  }) async {
    return await discoverProfiles(
      source: DataSource.firebase,
      onlyWithPhotos: onlyWithPhotos,
      forceFresh: forceFresh,
      additionalFilters: additionalFilters,
    );
  }

  /* = = = = = = = = =
  Register User
  = = = = = = = = = */
  Future<bool> registerUser(
    BuildContext context,
    String email, 
    String password,
  ) async {
    try {
      final AuthService authService = AuthService();
      await authService.registerAuth(context, email, password);
      return true;
    } catch (e) {
      print('Error in registerUser: $e');
      return false;
    }
  }
  
  /* = = = = = = = = =
  Login/Logout User
  = = = = = = = = = */
  Future<bool> loginUser(
    BuildContext context,
    String email, 
    String password
  ) async {
    try {
      // Login authentication user
      /*await _authService.loginUser(email, password);*/
      return true;
    } catch (e) {
      print('Error in loginUser: $e');
      return false;
    }
  }
  Future<void> logoutUser(BuildContext context) async {
    try {
      // Log out authentication
      /*await _authService.logoutUser();*/
      // Update route - go back to welcome screen
      /*_routeService.navigateAndClearStack(context, '/welcome');*/
    } catch (e) {
      print('Error in logoutUser: $e');
      throw e;
    }
  }
  
  /* = = = = = = = = =
  Matches
  = = = = = = = = = */
  Future<List<Map<String, dynamic>>> calculateMatches({bool useCache = true}) async {
    try {
      return [];
    } catch (e) {
      print('Error in calculateMatches: $e');
      return [];
    }
  }
  Future<bool> unmatchUsers(
    BuildContext context,
    String targetUserId
  ) async {
    try {
      // Save local status
      // Get local data
      // Unmatch in Firestore
      // Recalculate matches
      // Update route - go back to matches screen
      /*_routeService.navigateReplace(context, '/matches');*/
      return true;
    } catch (e) {
      print('Error in unmatchUsers: $e');
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getUnmatchedFromUser(
    BuildContext context
  ) async {
    try {
      // Get user data
      // Save locally
      // Calculate matches (force refresh)
      // Update route status
      /*_routeService.updateRouteStatus('/discover');*/
      return [];
    } catch (e) {
      print('Error in getUnmatchedFromUser: $e');
      return [];
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
    
}