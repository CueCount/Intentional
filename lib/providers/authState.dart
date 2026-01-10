import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../functions/chatService.dart';
import '../../widgets/registration_result.dart'; // Add this import
import 'inputState.dart';


class AppAuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final StreamChatService _chatService = StreamChatService();

  StreamSubscription<User?>? _sub;
  User? _user;
  String? _tempId;
  bool _isLoading = true;
  bool _isInitialized = false;

  // Flag to block auth listener during registration
  bool _blockAuthListener = false;

  // Getters
  User? get user => _user;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid ?? _tempId;
  String? get tempId => _tempId;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  /* = = = = = = = =
  Initializing App 
  = = = = = = = = */

  void init() {
    _sub?.cancel();
    _sub = _auth.authStateChanges().listen((u) async {
      // CRITICAL: Block auth listener during registration
      if (_blockAuthListener) {
        if (kDebugMode) {
          print('🚫 AuthProvider: Blocking auth state change during registration');
        }
        return;
      }
      
      if (kDebugMode) {
        print('👤 AuthProvider: Auth state changed - User: ${u?.uid ?? "null"}');
      }
      
      final previousUserId = _user?.uid ?? _tempId;
      final newUserId = u?.uid;
      
      _user = u;
      
      if (u != null) {
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
        
        if (previousUserId != newUserId) {
          notifyListeners();
        }
      } else {
        _tempId = await _getOrCreateTempId();
        _isLoading = false;
        if (!_isInitialized) _isInitialized = true;
        
        if (previousUserId != _tempId) {
          notifyListeners();
        }
      }
    });
  }

  /* = = = = = = = =
  Temperary ID 
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

  /* = = = = = = = =
  Sign In/Out
  = = = = = = = = */

  Future<void> signIn(String email, String password, InputState inputState) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );

      if (credential.user != null) {
        final userId = credential.user!.uid;
        
        // Fetch inputs from Firestore and save to SharedPreferences
        Map<String, dynamic> inputs = {};
        try {
          await inputState.saveInputsToLocalFromRemote(userId);
          inputs = await inputState.fetchInputsFromLocal();
          if (kDebugMode) {
            print('✅ AuthProvider: Fetched ${inputs.keys.length} input fields for user');
          }
        } catch (e) {
          if (kDebugMode) {
            print('⚠️ AuthProvider: Failed to fetch inputs - $e');
          }
        }

        // Get user name for Stream Chat (now from freshly fetched inputs)
        String userName = inputs['nameFirst'] ?? 'User';
        
        // Connect to Stream Chat
        try {
          if (!_chatService.isUserConnected()) {
            await _chatService.connectUser(
              userId: userId,
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
    notifyListeners();
  }

  /* = = = = = = = =
  Register
  = = = = = = = = */

  Future<RegistrationResult> signUp(String email, String password, inputProvider) async {
    // BLOCK the auth listener from reacting to Firebase Auth changes
    _blockAuthListener = true;
    _isLoading = true;
    UserCredential? userCredential;
    String? authenticatedUserId;
    
    try {
      final tempId = _tempId;
      if (tempId == null || tempId.isEmpty) {
        _blockAuthListener = false;
        _isLoading = false;
        return RegistrationResult.failure(
          message: 'No temporary session found. Please restart the app and try again.',
          code: 'no-temp-session',
        );
      }
      
      if (kDebugMode) {
        print('🚀 Starting registration for temp ID: $tempId');
      }
      
      // Get all temp data
      final tempData = await inputProvider.fetchInputsFromLocal();
      tempData['email'] = email;
      
      if (tempData.isEmpty) {
        _blockAuthListener = false;
        _isLoading = false;
        return RegistrationResult.failure(
          message: 'No profile data found. Please complete your profile first.',
          code: 'no-temp-data',
        );
      }
      
      // STEP 1: Create Firebase Auth user
      if (kDebugMode) {
        print('🔐 Creating Firebase Auth user...');
      }
      
      try {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        _blockAuthListener = false;
        _isLoading = false;
        
        if (kDebugMode) {
          print('❌ Firebase Auth Error: ${e.code}');
        }
        
        return RegistrationResult.failure(
          message: _getFirebaseErrorMessage(e.code),
          code: e.code,
        );
      }
      
      if (userCredential.user == null) {
        _blockAuthListener = false;
        _isLoading = false;
        return RegistrationResult.failure(
          message: 'Failed to create user account. Please try again.',
          code: 'user-creation-failed',
        );
      }
      
      authenticatedUserId = userCredential.user!.uid;
      
      if (kDebugMode) {
        print('✅ User created: $authenticatedUserId');
        print('🚫 Auth listener is BLOCKED - no navigation yet');
      }
      
      // STEP 2: Sync data to Firestore
      if (kDebugMode) {
        print('📦 Transferring data from users_onboarding to users...');
      }
      
      try {
        // Fetch data from users_onboarding/{tempId}
        final onboardingDoc = await FirebaseFirestore.instance
            .collection('users_onboarding')
            .doc(tempId)
            .get();
        
        if (!onboardingDoc.exists || onboardingDoc.data() == null) {
          throw Exception('No onboarding data found for temp ID: $tempId');
        }
        
        final onboardingData = onboardingDoc.data()!;
        
        if (kDebugMode) {
          print('📥 Retrieved ${onboardingData.keys.length} fields from users_onboarding');
        }
        
        // Write data to users/{authenticatedUserId}
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authenticatedUserId)
            .set({
              ...onboardingData,
              'createdAt': FieldValue.serverTimestamp(),
              'lastUpdated': FieldValue.serverTimestamp(),
            });
        
        if (kDebugMode) {
          print('✅ Data transferred to users/$authenticatedUserId');
        }
        
      } catch (e) {
        if (kDebugMode) {
          print('❌ Failed to transfer data: $e');
          print('🗑️ Attempting to delete Firebase Auth user...');
        }
        
        // Delete the auth user to allow retry
        try {
          await userCredential.user?.delete();
          if (kDebugMode) {
            print('✅ Deleted Firebase Auth user to allow retry');
          }
        } catch (deleteError) {
          if (kDebugMode) {
            print('❌ Could not delete Firebase Auth user: $deleteError');
            print('⚠️ This will create a ghost account!');
          }
        }
        
        _blockAuthListener = false;
        _isLoading = false;
        
        return RegistrationResult.failure(
          message: 'Failed to save your profile data. Please try again. Error: ${e.toString()}',
          code: 'data-sync-failed',
        );
      }

      // STEP 4: Update InputProvider session
      if (kDebugMode) {
        print('🔄 Updating session ID...');
      }
      
      inputProvider.setCurrentSessionId(authenticatedUserId);

      // STEP 5: Connect to Stream Chat
      if (kDebugMode) {
        print('💬 Connecting to Stream Chat...');
      }
      
      try {
        final userName = tempData['nameFirst'] ?? 'User';
        if (!_chatService.isUserConnected()) {
          await _chatService.connectUser(
            userId: authenticatedUserId,
            userName: userName,
          );
        }
        
        if (kDebugMode) {
          print('✅ Connected to Stream Chat');
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to connect to Stream Chat: $e');
          print('⚠️ Non-critical error, continuing...');
        }
      }
      
      // STEP 6: NOW update internal state and UNBLOCK listener
      if (kDebugMode) {
        print('✅ Registration complete - updating state and unblocking listener');
      }
      
      _user = userCredential.user;
      _blockAuthListener = false;
      _isLoading = false;
      
      // NOW notify listeners - everything is ready
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ State updated - app can now navigate');
      }
      
      return RegistrationResult.success();
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected registration error: $e');
      }
      
      // Try to clean up
      if (userCredential?.user != null) {
        try {
          await userCredential!.user!.delete();
          if (kDebugMode) {
            print('🗑️ Deleted Firebase Auth user after unexpected error');
          }
        } catch (deleteError) {
          if (kDebugMode) {
            print('❌ Could not delete Firebase Auth user: $deleteError');
          }
        }
      }
      
      _blockAuthListener = false;
      _isLoading = false;
      
      return RegistrationResult.failure(
        message: 'An unexpected error occurred: ${e.toString()}',
        code: 'unexpected-error',
      );
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email. Try logging in instead.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      default:
        return 'Registration failed: $code. Please try again.';
    }
  }

  /* = = = = = = = =
  Dispose App
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