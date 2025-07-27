import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/router/router.dart';

class AccountService {

  /* = = = = = = = = = 
  Create User Id 
  = = = = = = = = = */
  static Future<String> createUserId() async {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = List.generate(28, (index) => chars[(DateTime.now().millisecondsSinceEpoch + index) % chars.length]).join();
    return rand;
  }

  /* = = = = = = = = = 
  Get Current User Id 
  = = = = = = = = = */
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String> getCurrentUserId() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    } else {
      return await AccountService.createUserId();
    }
  }

  /* = = = = = = = = =
  Logout Account
  = = = = = = = = = */
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

  /* = = = = = = = = =
  Login Account
  = = = = = = = = = */
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
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}
  
}
