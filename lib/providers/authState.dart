import 'dart:async';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _sub;
  User? _user;
  String? _tempId;
  bool _isLoading = true;
  bool _isInitialized = false;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid ?? _tempId;
  String? get tempId => _tempId;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /* = = = = = = = =
  Getting/Creating the Current ID 
  = = = = = = = = */

  Future<String> _getOrCreateTempId() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check for existing temp ID
    String? existingTempId = prefs.getString('current_temp_id');
    
    if (existingTempId != null && existingTempId.startsWith('temp_')) {
      if (kDebugMode) {
        print('AuthProvider: Found existing temp ID: $existingTempId');
      }
      return existingTempId;
    }
    
    // Generate new temp ID inline
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    final randomId = List.generate(28, (index) => chars[random.nextInt(chars.length)]).join();
    final newTempId = 'temp_$randomId';
    
    await prefs.setString('current_temp_id', newTempId);
    
    if (kDebugMode) {
      print('AuthProvider: Generated new temp ID: $newTempId');
    }
    
    return newTempId;
  }

  Future<void> _cleanupTempSession() async {
    if (_tempId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Remove temp ID
      await prefs.remove('current_temp_id');
      
      // Clean up any inputs associated with temp ID
      await prefs.remove('inputs_$_tempId');
      
      // Clean up any users data associated with temp ID
      final keys = prefs.getKeys();
      for (String key in keys) {
        if (key.startsWith('users_$_tempId')) {
          await prefs.remove(key);
        }
      }
      
      if (kDebugMode) {
        print('AuthProvider: Cleaned up temp session: $_tempId');
      }
      
      _tempId = null;
      
    } catch (e) {
      if (kDebugMode) {
        print('AuthProvider Error: Failed to cleanup temp session - $e');
      }
    }
  }

  void init() {
    _sub?.cancel();
    _sub = _auth.authStateChanges().listen((u) async {
      final previousUserId = _user?.uid ?? _tempId;
      final newUserId = u?.uid;
      
      _user = u;
      
      if (u != null) {
        // User is logged in - clean up temp session if it exists
        if (_tempId != null) {
          await _cleanupTempSession();
        }
        _isLoading = false;
        if (!_isInitialized) _isInitialized = true;
        
        // Notify if user changed
        if (previousUserId != newUserId) {
          notifyListeners();
        }
      } else {
        // No authenticated user - set up temp session
        _tempId = await _getOrCreateTempId();
        _isLoading = false;
        if (!_isInitialized) _isInitialized = true;
        
        // Notify if session changed (from real user to temp)
        if (previousUserId != _tempId) {
          notifyListeners();
        }
      }
    });
  }

  /*void init() {
    _sub?.cancel();
    _sub = _auth.authStateChanges().listen((u) {
      final changed = _user?.uid != u?.uid;
      _user = u;
      _isLoading = false;
      if (!_isInitialized) _isInitialized = true;
      if (changed) notifyListeners(); else notifyListeners(); // safe either way
    });
  }*/

  /* = = = = = = = =
  Logging In/Out User
  = = = = = = = = */

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await _auth.signOut();
    
    // Force immediate state update instead of waiting for stream
    _user = null;
    _isLoading = false;
    notifyListeners(); // This will immediately trigger your app-level listener
  }

  /* = = = = = = = =
  Register User 
  = = = = = = = = */

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // Cleanup will happen automatically in the auth state listener
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /* = = = = = = = =
  Dispose
  = = = = = = = = */

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

}
