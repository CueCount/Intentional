import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'localData_service.dart';
import 'userData_service.dart';
import 'matches_service.dart';
import 'register_service.dart';
import 'package:image_picker/image_picker.dart';
import 'photo_service.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../data/inputState.dart';
import '../data/firestore_service.dart';
import '../pages/Needs/photoCrop.dart';

class AirTrafficController {
  final LocalDataService _localDataService = LocalDataService();
  final UserDataService _userDataService = UserDataService();
  final MatchesService _matchesService = MatchesService();
  
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
          // Not logged in — use or create temp userId
          String tempUserId = prefs.getString('userId') ?? await LocalDataService.createUserId();
          prefs.setString('userId', tempUserId);
          inputState.setUserId(tempUserId);
        }
      }

      // STEP 3: Save the input
      if (needData != null) {
        LocalDataService.saveToInputState(context: context, data: needData);
      }

    } catch (e) {
      print('Error in addedNeed: $e');
      throw e;
    }
  }


  Future<void> saveAllInputs(BuildContext context) async {
    final inputState = Provider.of<InputState>(context, listen: false);

    // 1. Gather current inputs from the Provider
    final allInputs = LocalDataService.fetchFromInputState(context);

    // 2. Save to SharedPreferences
    LocalDataService.saveToSharedPref(data: allInputs, userId: inputState.userId,); 

    // 3. Save to Firestore
    final firestoreService = FirestoreService();
    await firestoreService.handleSubmit(allInputs);
    /* I should move the Firestore save function to the data services file, and check if it is set up to submit everythign properly with the filtered arguments. */

    // Optionally show a success toast/snackbar here
  }
  
  /// Register a new user
  Future<bool> registerUser(
    BuildContext context,
    String email, 
    String password,
  ) async {
    try {
      Map<String, dynamic>? localData = LocalDataService.fetchFromInputState(context);
      // Create an instance of AuthService first
      final AuthService authService = AuthService();
      // Then call the instance method on that object
      await authService.registerAuth(context, email, password);
      if (localData != null) {
        await _userDataService.saveUserData(localData);
      }
      return true;
    } catch (e) {
      print('Error in registerUser: $e');
      return false;
    }
  }
  
  /// Login existing user
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
  
  /// Calculate matches for current user
  Future<List<Map<String, dynamic>>> calculateMatches({bool useCache = true}) async {
    try {
      // Get local data (preferences)
      //Map<String, dynamic>? localData = await LocalDataService.getLocalData();
      // Calculate matches
      List<Map<String, dynamic>> matches = await _userDataService.fetchUsers();
      return matches;
    } catch (e) {
      print('Error in calculateMatches: $e');
      return [];
    }
  }
  
  /// Send message to another user
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
  
  /// Receive and process new messages
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
  
  /// Unmatch from another user
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
  
  /// Get unmatched profiles
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
    
  /// Log out the current user
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

  Future<void> uploadPhoto(BuildContext context) async {
    try {
      // Step 1: Pick the image
      
      final XFile? selectedImage = await PhotoService.pickImage(context);
      if (selectedImage != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoCropPage(imageFile: selectedImage),
          ),
        );
      }
      
      // If no image was selected or an error occurred, exit early
      if (selectedImage == null) {
        return;
      }
      
      final bytes = await selectedImage.readAsBytes();
      final base64Image = base64Encode(bytes);
    
      
    } catch (e) {
      print('Error in upload photo process: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error processing photo: $e')),
      );
    }
  }

}