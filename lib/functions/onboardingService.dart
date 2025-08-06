import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'helpers/saveData_service.dart';
import 'helpers/fetchData_service.dart';
import 'helpers/register_service.dart';
import 'dart:math';

import 'userActionsService.dart';
enum DataSource { cache, firebase }

class AirTrafficController {

  /* = = = = = = = = = 
  Create Temporary ID 
  = = = = = = = = = */
  static Future<String> createUserId() async {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random(); // You'll need to import 'dart:math'
    
    // Create a truly random 28-character ID with temp prefix
    final randomId = List.generate(28, (index) => chars[random.nextInt(chars.length)]).join();
    
    return 'temp_$randomId';
  }

  /* = = = = = = = = =
  Saving Locally / Firebase
  = = = = = = = = = */
  Future<void> saveNeedInOnboardingFlow(BuildContext context, Map<String, dynamic>? needData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      String tempUserId = prefs.getString('current_temp_id') ?? 
        await createUserId().then((newId) async {
          await UserActions.setInfoIncomplete(newId, true);
          await UserActions.setNeedsUpdated(newId, true);
          return newId;
        });
      
      await prefs.setString('current_temp_id', tempUserId);
            
      if (needData != null) {
        await SaveDataService.saveToSharedPref(data: needData, userId: tempUserId);
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

  Future<void> saveAccountInputRegistrationFlow(BuildContext context, Map<String, dynamic>? accountData) async {
    try {
      final id = await UserActions.getCurrentUserId();
                  
      if (id != null && id.isNotEmpty && accountData != null && accountData.isNotEmpty) {
        await SaveDataService.saveToSharedPref(data: accountData, userId: id);
      }
    } catch (e) {
      print('Error in saveAccountInputRegistrationFlow: $e');
      throw e;
    }
  }

  Future<void> saveAccountDataToFirebase(BuildContext context) async {
    try {
      final id = await UserActions.getCurrentUserId();

      if (id != null && id.isNotEmpty) {
        await UserActions.setInfoIncomplete(id, false);
        await UserActions().resetNeedsUpdated(id);
        Map<String, dynamic> userData = await FetchDataService.getUserDataFromSharedPref(id);
        Map<String, dynamic> photoData = FetchDataService.fetchFromInputState(context);
        Map<String, dynamic> allData = {
          ...userData,
          ...photoData,
          'userId': id,
          'lastUpdated': DateTime.now().toIso8601String(),
          'infoIncomplete': false,
        };
        await SaveDataService().saveToFirebaseOnRegister(context, allData);
        print('✅ Account data saved to Firebase for user: $id');
      }
      
    } catch (e) {
      print('❌ saveAccountDataToFirebase: Failed - $e');
    }
  }

}