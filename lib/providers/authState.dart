import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/chatService.dart'; 

class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamChatService _chatService = StreamChatService();

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
        /*if (_tempId != null) {
          await _cleanupTempSession();
        }*/
        _isLoading = false;
        if (!_isInitialized) _isInitialized = true;

        // Connect to Stream Chat for authenticated users
        try {
          if (!_chatService.isUserConnected()) {
            final prefs = await SharedPreferences.getInstance();
            final inputsJson = prefs.getString('inputs_${u.uid}');
            String userName = 'User';
            
            if (inputsJson != null) {
              final inputs = Map<String, dynamic>.from(jsonDecode(inputsJson));
              userName = inputs['nameFirst'] ?? 'User';
            }
            
            await _chatService.connectUser(
              userId: u.uid,
              userName: userName,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('AuthProvider: Could not connect to Stream Chat - $e');
          }
        }
        
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

  /* = = = = = = = =
  Logging In/Out User
  = = = = = = = = */

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      if (credential.user != null) {
        // Get user data for Stream Chat
        try {
          final prefs = await SharedPreferences.getInstance();
          final inputsJson = prefs.getString('inputs_${credential.user!.uid}');
          String userName = 'User';
          
          if (inputsJson != null) {
            final inputs = Map<String, dynamic>.from(jsonDecode(inputsJson));
            userName = inputs['nameFirst'] ?? 'User';
          }
          
          // Connect to Stream Chat
          if (!_chatService.isUserConnected()) {
            await _chatService.connectUser(
              userId: credential.user!.uid,
              userName: userName,
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print('AuthProvider: Failed to connect to Stream Chat - $e');
          }
        }
      }

    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    // Disconnect from Stream Chat first
    try {
      if (_chatService.isUserConnected()) {
        await _chatService.disconnectUser();
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthProvider: Failed to disconnect from Stream Chat - $e');
      }
    }
    
    await _auth.signOut();
    
    // Force immediate state update instead of waiting for stream
    _user = null;
    _isLoading = false;
    notifyListeners(); // This will immediately trigger your app-level listener
  }

  /* = = = = = = = =
  Register User 
  = = = = = = = = */

  Future<void> signUp(String email, String password, inputProvider) async {
    try {

      _isLoading = true;
      notifyListeners();
      
      // Get the temp ID 
      final tempId = _tempId;
      if (tempId == null || tempId.isEmpty) {
        throw Exception('No temporary session found');
      }
      
      // Get all temp data from SharedPreferences via InputProvider
      final tempData = await inputProvider.getAllInputs();
      tempData['email'] = email;
      print('📱 Temp data retrieved: ${tempData.keys.toList()}');
      print('📱 Has photos: ${tempData.containsKey('photos')}');
      if (tempData.isEmpty) {
        throw Exception('No temporary data to transfer');
      }
      
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential.user == null) {
        throw Exception('Failed to create user');
      }
      
      final authenticatedUserId = userCredential.user!.uid;
      
      // Transfer temp data to authenticated user in Firestore
      await inputProvider.syncInputs(
        fromId: tempId,
        toId: authenticatedUserId,
      );

      // Transfer the users list
      await _transferUsersList(tempId, authenticatedUserId);
      
      // Update InputProvider to use the new authenticated session
      inputProvider.setCurrentSessionId(authenticatedUserId);

      // Connect to Stream Chat with the new user
      try {
        final userName = tempData['nameFirst'] ?? 'User';
        if (!_chatService.isUserConnected()) {
          await _chatService.connectUser(
            userId: authenticatedUserId,
            userName: userName,
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('AuthProvider: Failed to connect to Stream Chat - $e');
        }
      }
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      throw e;
    }
  }

  /* = = = = = = = =
  Helpers 
  = = = = = = = = */

  // this should probably be in the Input State, but whatever, this is a hack anyway
  Future<void> _transferUsersList(String fromId, String toId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersList = prefs.getStringList('users_$fromId');
      
      if (usersList != null && usersList.isNotEmpty) {
        await prefs.setStringList('users_$toId', usersList);
        await prefs.remove('users_$fromId');
        
        if (kDebugMode) {
          print('AuthProvider: Transferred ${usersList.length} users from users_$fromId to users_$toId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthProvider: Failed to transfer users list - $e');
      }
    }
  }

  /* = = = = = = = =
  Dispose 
  = = = = = = = = */

  @override
  void dispose() {
    // Disconnect from Stream Chat when disposing
    try {
      if (_chatService.isUserConnected()) {
        _chatService.disconnectUser();
      }
    } catch (e) {
      if (kDebugMode) {
        print('AuthProvider: Failed to disconnect from Stream Chat - $e');
      }
    }
    _sub?.cancel();
    super.dispose();
  }

}
