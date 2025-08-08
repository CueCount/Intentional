import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'userActionsService.dart';
import 'helpers/saveData_service.dart';
import 'helpers/fetchData_service.dart';
import '/router/router.dart';

class AccountService {

  /* = = = = = = = = =
  Logout Account
  = = = = = = = = = */
  static Future<void> logout(BuildContext context) async {
    try {
      final id = await UserActions.getCurrentUserId();
      print('✅ User ID: \n$id');
      if (id != null && id.isNotEmpty) {
        final data = await FetchDataService.fetchUserFromSharedPreferences(id);
        print('✅ Data fetched from \n$id');
        await SaveDataService.saveToFirestore(data: data, userId: id);
        print('✅ Data saved to \n$id');
        await SaveDataService.clearUserDataFromSharedPref(id);
        print('✅ Data cleared in Shared Preferences from \n$id');
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('current_user_id');
        await prefs.remove('current_temp_id');
        print('✅ Cleared current_user_id from SharedPreferences');
      }
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
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
        final id = await UserActions.getCurrentUserId();
        print('✅ User ID: \n$id');

        if (id != null && id.isNotEmpty) {
          final data = await FetchDataService.fetchUserFromFirebase(id);
          print('✅ Data fetched from \n$id in Firebase');
          await SaveDataService.saveToSharedPref(data: data, userId: id);
          print('✅ Data saved from \n$id into Shared Preferences');
        }
        if (context.mounted) {
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }
  
}
