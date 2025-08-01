import 'package:flutter/material.dart';
import 'dart:async';
import 'helpers/saveData_service.dart';
import 'helpers/fetchData_service.dart';
import 'helpers/matches_service.dart';
import 'helpers/register_service.dart';
import 'loginService.dart';
import 'package:image_picker/image_picker.dart';
import 'helpers/photo_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../data/inputState.dart';
import '../router/router.dart';

enum DataSource { cache, firebase }

class AirTrafficController {
  
  /* = = = = = = = = =
  Onboarding + Registration Flow
  = = = = = = = = = */
  Future<void> saveNeedInOnboardingFlow(BuildContext context, Map<String, dynamic>? needData) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);

      if (inputState.userId.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        
        // Check for existing temp_id, create one if it doesn't exist
        String tempUserId = prefs.getString('current_temp_id') ?? 
          await AccountService.createUserId().then((newId) async {
            await AccountService.setInfoIncomplete(newId, true);
            return newId;
          });
        
        // Save the temp_id to SharedPreferences
        await prefs.setString('current_temp_id', tempUserId);
        
        // Set it in the Provider for this session
        inputState.setUserId(tempUserId);
        
        print('Using temp_id for onboarding: $tempUserId');
      }

      // Save the onboarding data
      if (needData != null) {
        await SaveDataService.saveToSharedPref(data: needData, userId: inputState.userId);
      }
      
    } catch (e) {
      print('Error in saveNeedInOnboardingFlow: $e');
      throw e;
    }
  }
  
  Future<bool> registerUserAndTransferSavedData(
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

  Future<void> saveAccountDataToFirebase(BuildContext context) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      final userId = inputState.userId;
      
      // 1. Get user data from SharedPreferences
      Map<String, dynamic> userData = await FetchDataService.getUserDataFromSharedPref(userId);
      
      // 2. Get photo data from Provider
      Map<String, dynamic> photoData = FetchDataService.fetchFromInputState(context);
      
      // 3. Combine all data
      Map<String, dynamic> allData = {
        ...userData,
        ...photoData,
        'userId': userId,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      // 4. Save to Firebase
      await SaveDataService().handleSubmit(context, allData);
      
      print('✅ Account data saved to Firebase for user: $userId');
      
    } catch (e) {
      print('❌ saveAccountDataToFirebase: Failed - $e');
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