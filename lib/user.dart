import 'package:flutter/material.dart';
//import 'package:provider/provider.dart';
//import '/router/router.dart';  // Import to access GlobalState

class UserProvider with ChangeNotifier {
  static final UserProvider _instance = UserProvider._internal();
  bool isLoggedIn = false; // Initial state

  UserProvider({this.isLoggedIn = false});
  UserProvider._internal();
  static UserProvider get instance => _instance;

  void toggleLogin() {
    // Check conditions or just toggle the status
    instance.isLoggedIn = !instance.isLoggedIn;
    notifyListeners(); // Notify widgets that are listening for changes
  }
}