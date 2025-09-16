import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _sub;
  User? _user;
  bool _isLoading = true;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /// Call once when the provider is created
  void init() {
    _sub?.cancel();
    _sub = _auth.authStateChanges().listen((u) {
      final changed = _user?.uid != u?.uid;
      _user = u;
      _isLoading = false;
      if (!_isInitialized) _isInitialized = true;
      if (changed) notifyListeners(); else notifyListeners(); // safe either way
    });
  }

  Future<void> signOut() async {
    await _auth.signOut(); // stream will emit null
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
