import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/router/router.dart';

class LogoutService {

  static Future<void> logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: ${e.toString()}')),
      );
    }
  }
  
}
