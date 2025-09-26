import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/inputState.dart';
import 'helpers/saveData_service.dart';
import 'helpers/fetchData_service.dart';
import 'helpers/register_service.dart';
enum DataSource { cache, firebase }

class AirTrafficController {

  /* = = = = = = = = =
  Saving Locally / Firebase
  = = = = = = = = = */

  // move to Auth Provider
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

  // move to Auth Provider, used in photos
  Future<void> saveAccountDataToFirebase(BuildContext context) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      final id = inputState.userId;

      if (id != null && id.isNotEmpty) {
        Map<String, dynamic> userData = await FetchDataService.fetchUserFromSharedPreferences(id);
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