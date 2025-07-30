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
        String tempUserId = prefs.getString('current_temp_id') ?? await AccountService.createUserId();
        
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

  // saveAccountDataInRegisterFlow()

  Future<void> saveAccountDataToFirebase(BuildContext context) async {
    final allInputs = FetchDataService.fetchFromInputState(context);
    final inputState = Provider.of<InputState>(context, listen: false);
    SaveDataService.saveToSharedPref(data: allInputs, userId: inputState.userId,); 
    await SaveDataService().handleSubmit(context, allInputs);
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