import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../functions/compatibilityCalcService.dart';

class Input {
  final String title;
  final List<dynamic> possibleValues; 
  final String type;
  dynamic currentValue;
  
  Input({
    required this.title, 
    required this.possibleValues, 
    required this.type, 
    this.currentValue,
  });
  
  Map<String, dynamic> toJson() {
    return {'Title': title, 'PossibleValues': possibleValues, 'Type': type, };
  }
  
  factory Input.fromJson(Map<String, dynamic> json) {
    return Input(
      title: json['Title'] ?? '', 
      possibleValues: json['PossibleValues'] != null 
          ? List<dynamic>.from(json['PossibleValues']) 
          : [], 
      type: json['Type'] ?? '',
    );
  }

}

class InputPhoto {
  final Uint8List? croppedBytes;
  final String? localPath;
  InputPhoto({this.croppedBytes, this.localPath});
  Map<String, dynamic> toJson() => {};
}

class InputState extends ChangeNotifier {
  Map<String, dynamic> _cachedInputs = {};
  String _currentSessionId = '';
  String get userId => _currentSessionId;

  /* = = = = = = = = =
  Save Inputs 
  = = = = = = = = = */

  Future<void> saveNeedLocally(Map<String, dynamic>? needData) async {
    try {
      // Use the session ID we already have from AuthProvider
      if (_currentSessionId.isEmpty) {
        throw Exception("No session ID available");
      }
      
      if (needData == null || needData.isEmpty) {
        print('⚠️ No data to save');
        return;
      }

      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      final key = 'inputs_$_currentSessionId';
      
      // Get existing data if any
      String? existingDataJson = prefs.getString(key);
      Map<String, dynamic> existingData = {};
      
      if (existingDataJson != null && existingDataJson.isNotEmpty) {
        Map rawData = json.decode(existingDataJson);
        rawData.forEach((k, v) => existingData[k.toString()] = v);
      }

      // Merge new data with existing data
      final mergedData = {
        ...existingData,
        ...needData,
        'session_id': _currentSessionId,
        'last_updated': DateTime.now().toIso8601String(),
      };

      // Save merged data back to SharedPreferences
      await prefs.setString(key, json.encode(mergedData));
      
      // Update local cache as well
      _cachedInputs.addAll(needData);
      notifyListeners();
      
      print('✅ Data saved locally under key "$key"');
      
    } catch (e) {
      print('❌ saveNeedLocally: Failed - $e');
      throw e;
    }
  }

  /* = = = = = = = = =
  I'm not even sure
  = = = = = = = = = */

  void setCurrentSessionId(String userId) {
    _currentSessionId = userId;
    notifyListeners();
  }

  void clearCurrentSessionId() {
    _currentSessionId = '';
    notifyListeners();
  }

  void clearAllData() {
    _cachedInputs.clear();
    _currentSessionId = '';
    photoInputs.clear();
    currentSessionList.clear();
    ignoreList.clear();
    deniedList.clear();
  }
  
  Future<Map<String, dynamic>> getAllInputs() async {
    try {
      if (_currentSessionId.isEmpty) {
        print('InputState: No session ID for getting inputs');
        return {};
      }
      
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$_currentSessionId');
      
      if (inputsJson != null) {
        return jsonDecode(inputsJson);
      }
      
      // No inputs cached - return empty map
      return {};
    } catch (e) {
      print('InputState Error: Failed to get all inputs - $e');
      return {};
    }
  }



  Future<Map<String, dynamic>> syncInputs({String? fromId, String? toId}) async {
    try {
      final sourceId = fromId ?? _currentSessionId;
      final targetId = toId ?? _currentSessionId;
      
      if (sourceId.isEmpty) {
        print('InputState: No session ID for syncing');
        return {};
      }
      
      final prefs = await SharedPreferences.getInstance();
      
      // Step 1: Always read from SharedPreferences using sourceId
      Map<String, dynamic> localInputs = {};
      final inputsJson = prefs.getString('inputs_$sourceId');
      if (inputsJson != null) {
        localInputs = jsonDecode(inputsJson);
      }
      print('🔍 Local inputs from $sourceId: ${localInputs.keys.toList()}');
      
      // Step 2: Get inputs from Firebase (if not a transfer, get from target)
      Map<String, dynamic> firebaseInputs = {};
      //if (fromId == null) {  // Only fetch from Firebase if not transferring
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(targetId)
              .get();
          
          if (doc.exists && doc.data() != null) {
            firebaseInputs = doc.data()!;
          }
        } catch (e) {
          print('InputState: Error getting Firebase inputs - $e');
        }
      //}

      print('🔍 Firebase inputs retrieved: ${firebaseInputs.keys.toList()}');
      print('📊 Firebase inputs count: ${firebaseInputs.length}');
      
      // Step 3: Merge inputs - local takes priority, but get everything from Firebase
      Map<String, dynamic> mergedInputs = Map<String, dynamic>.from(localInputs);

      // Add all Firebase data, but only for keys that either:
      // 1. Don't exist locally at all, OR
      // 2. Have empty local values
      firebaseInputs.forEach((key, value) {
        if (!mergedInputs.containsKey(key)) {
          // Key doesn't exist locally - add it from Firebase
          mergedInputs[key] = value;
        } else {
          // Key exists locally - only replace if local is empty
          final localValue = mergedInputs[key];
          if (localValue == null ||
              (localValue is String && localValue.trim().isEmpty) ||
              (localValue is List && localValue.isEmpty) ||
              (localValue is Map && localValue.isEmpty)) {
            mergedInputs[key] = value;
          }
        }
      });

      print('🔄 Merged inputs keys: ${mergedInputs.keys.toList()}');
      print('📊 Merged inputs count: ${mergedInputs.length}');
      
      // Step 4: Handle photo uploads if transferring or if photos are local
      if (mergedInputs['photos'] != null && mergedInputs['photos'] is List) {
        final photos = mergedInputs['photos'] as List;
        bool needsUpload = photos.any((photo) => 
          photo is String && (photo.startsWith('data:') || !photo.startsWith('http'))
        );
        
        if (needsUpload) {
          mergedInputs['photos'] = await _uploadPhotosToStorage(photos, targetId);
        }
      }
      
      // Step 5: Write to Firebase with target ID
      try {
        await FirebaseFirestore.instance
        .collection('users')
        .doc(targetId)
        .set({
          ...mergedInputs,
          'userId': targetId,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('InputState: Error updating Firebase - $e');
      }
      
      // Step 6: Save to SharedPreferences with target ID
      try {
        Map<String, dynamic> serializableInputs = Map<String, dynamic>.from(mergedInputs);
        serializableInputs.removeWhere((key, value) => 
          key == 'lastUpdated' || 
          value is Timestamp ||
          key.startsWith('_')
        );
        
        await prefs.setString('inputs_$targetId', jsonEncode(serializableInputs));
      } catch (e) {
        print('InputState: Error updating local inputs - $e');
      }
      
      // Step 7: Clean up source if this was a transfer
      if (fromId != null && fromId != targetId) {
        await prefs.remove('inputs_$fromId');
        print('InputState: Cleaned up source data for $fromId');
      }
      
      return mergedInputs;
      
    } catch (e) {
      print('InputState Error: Failed to sync inputs - $e');
      return {};
    }
  }

  Future<List<String>> _uploadPhotosToStorage(List<dynamic> localPhotos, String userId) async {
    final List<String> uploadedUrls = [];
    
    for (int i = 0; i < localPhotos.length; i++) {
      try {
        final photo = localPhotos[i];
        
        // Skip if already a Firebase URL
        if (photo is String && photo.startsWith('https://firebasestorage.googleapis.com')) {
          uploadedUrls.add(photo);
          continue;
        }
        
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(userId)
            .child('photos')
            .child('photo_$i.jpg');
        
        if (kIsWeb && photo is String && photo.startsWith('data:')) {
          // Web: Convert base64 to bytes and upload
          final base64String = photo.split(',')[1];
          final bytes = base64Decode(base64String);
          
          final uploadTask = await storageRef.putData(
            bytes,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          
          final downloadUrl = await uploadTask.ref.getDownloadURL();
          uploadedUrls.add(downloadUrl);
          
        } else if (!kIsWeb && photo is String) {
          // Mobile: Upload file from path
          final file = File(photo);
          if (await file.exists()) {
            final uploadTask = await storageRef.putFile(
              file,
              SettableMetadata(contentType: 'image/jpeg'),
            );
            
            final downloadUrl = await uploadTask.ref.getDownloadURL();
            uploadedUrls.add(downloadUrl);
          }
        }
      } catch (e) {
        print('Error uploading photo $i: $e');
        // Continue with other photos even if one fails
      }
    }
    
    return uploadedUrls;
  }



  Future<dynamic> getInput(String inputKey) async {
    try {
      if (_currentSessionId.isEmpty) {
        print('InputState: No session ID for getting input');
        return null;
      }
      
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$_currentSessionId');
      
      if (inputsJson != null) {
        final inputs = jsonDecode(inputsJson);
        
        // Check if this specific input exists
        if (inputs[inputKey] != null) {
          final value = inputs[inputKey];
          
          // If it's an empty list, treat it as not found and fetch from Firebase
          if (value is List && value.isEmpty) {
            print('InputState: $inputKey exists but is empty, fetching from Firebase');
            await fetchSpecificInputs([inputKey]);
            
            // Re-read after fetch
            final updatedJson = prefs.getString('inputs_$_currentSessionId');
            if (updatedJson != null) {
              final updated = jsonDecode(updatedJson);
              return updated[inputKey];
            }
            return null;
          }
          
          // Value exists and is not empty
          return value;
        }
      }
      
      // Input not found in cache at all - fetch from Firebase
      print('InputState: $inputKey not in cache, fetching from Firebase');
      await fetchSpecificInputs([inputKey]);
      
      // Try to get it again after fetching
      final updatedJson = prefs.getString('inputs_$_currentSessionId');
      if (updatedJson != null) {
        final updated = jsonDecode(updatedJson);
        return updated[inputKey];
      }
      
      return null;
    } catch (e) {
      print('InputState Error: Failed to get input $inputKey - $e');
      return null;
    }
  }

  Future<void> fetchSpecificInputs(List<String> inputKeys) async {
    try {
      if (_currentSessionId.isEmpty || inputKeys.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing cached inputs
      Map<String, dynamic> existing = {};
      final existingJson = prefs.getString('inputs_$_currentSessionId');
      if (existingJson != null) {
        existing = jsonDecode(existingJson);
      }
      
      // Fetch from Firebase
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentSessionId)
          .get();
      
      if (!docSnap.exists) {
        print('InputState: No Firebase doc for $_currentSessionId');
        return;
      }
      
      final firebaseData = docSnap.data()!;
      
      // Extract only requested inputs
      Map<String, dynamic> fetched = {};
      for (String key in inputKeys) {
        if (firebaseData[key] != null) {
          // Handle special cases for lists stored as JSON strings
          if (key == 'currentSessionList' || key == 'currentSeshList' || 
              key == 'ignoreList' || key == 'deniedList') {
            // Try to decode if it's a JSON string
            final value = firebaseData[key];
            if (value is String) {
              try {
                fetched[key] = jsonDecode(value);
              } catch (_) {
                fetched[key] = value;
              }
            } else {
              fetched[key] = value;
            }
          } else {
            fetched[key] = firebaseData[key];
          }
        }
      }
      
      // Merge with existing and save
      final merged = {...existing, ...fetched};
      await prefs.setString('inputs_$_currentSessionId', jsonEncode(merged));
      
      // Update local state if these are our tracked lists
      if (inputKeys.contains('currentSessionList')) {
        currentSessionList = List<String>.from(fetched['currentSessionList'] ?? []);
      }
      if (inputKeys.contains('ignoreList')) {
        ignoreList = List<String>.from(fetched['ignoreList'] ?? []);
      }
      if (inputKeys.contains('deniedList')) {
        deniedList = List<String>.from(fetched['deniedList'] ?? []);
      }
      
      notifyListeners();
      
      print('InputState: Fetched ${inputKeys.join(", ")} from Firebase');
      print('InputState: Here is what currentSessionIds looks like $currentSessionList');
      
    } catch (e) {
      print('InputState Error: Failed to fetch inputs - $e');
    }
  }

  /* = = = = = = = = =
  Photo Save/Load 
  = = = = = = = = = */

  Future<void> savePhotosLocally() async {
    try {
      if (_currentSessionId.isEmpty) {
        throw Exception("No session ID available");
      }
      
      // Convert InputPhoto objects to string paths
      List<String> photoPaths = [];
      
      for (var photo in photoInputs) {
        // For web, store the bytes as a data URI
        if (kIsWeb && photo.croppedBytes != null) {
          // Create a data URI from the bytes (more portable than blob URLs)
          String base64 = base64Encode(photo.croppedBytes!);
          photoPaths.add('data:image/jpeg;base64,$base64');
        } 
        // For mobile, store the local file path
        else if (!kIsWeb && photo.localPath != null) {
          photoPaths.add(photo.localPath!);
        }
      }
      
      if (photoPaths.isEmpty) {
        print('⚠️ No photos to save locally');
        return;
      }
      
      // Get SharedPreferences instance
      final prefs = await SharedPreferences.getInstance();
      final key = 'inputs_$_currentSessionId';
      
      // Get existing data
      String? existingDataJson = prefs.getString(key);
      Map<String, dynamic> existingData = {};
      
      if (existingDataJson != null && existingDataJson.isNotEmpty) {
        existingData = jsonDecode(existingDataJson);
      }
      
      // Update with photos array
      existingData['photos'] = photoPaths;
      existingData['session_id'] = _currentSessionId;
      existingData['last_updated'] = DateTime.now().toIso8601String();
      
      // Save back to SharedPreferences
      await prefs.setString(key, jsonEncode(existingData));
      
      print('✅ ${photoPaths.length} photos saved locally under key "$key"');
      
    } catch (e) {
      print('❌ savePhotosLocally: Failed - $e');
      throw e;
    }
  }

  Future<void> loadPhotosFromLocal() async {
    try {
      if (_currentSessionId.isEmpty) return;
      
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$_currentSessionId');
      
      if (inputsJson == null) return;
      
      final inputs = jsonDecode(inputsJson);
      final photos = inputs['photos'];
      
      if (photos == null || photos is! List) return;
      
      // Clear existing and rebuild from saved paths
      photoInputs.clear();
      
      for (String path in photos) {
        if (kIsWeb && path.startsWith('data:')) {
          // Extract base64 from data URI and convert back to bytes
          final base64String = path.split(',')[1];
          final bytes = base64Decode(base64String);
          photoInputs.add(InputPhoto(croppedBytes: bytes));
        } else if (!kIsWeb) {
          // Mobile path
          photoInputs.add(InputPhoto(localPath: path));
        }
      }
      
      print('✅ Loaded ${photoInputs.length} photos from local storage');
      notifyListeners();
      
    } catch (e) {
      print('❌ loadPhotosFromLocal: Failed - $e');
    }
  }

  /* = = = = = = = = =
  Compatibility
  = = = = = = = = = */

  Future<void> checkAndUpdateMissingCompatibility(InputState inputState) async {
    if (_currentSessionId == null) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersList = prefs.getStringList('users_$_currentSessionId') ?? [];
      final currentUserData = await inputState.getAllInputs();
      
      bool hasUpdates = false;
      List<String> updatedUsers = [];
      
      for (int i = 0; i < usersList.length; i++) {
        final userData = jsonDecode(usersList[i]);
        
        // Check if compatibility is missing or incomplete (no category data)
        if (userData['compatibility'] == null) {
          // Calculate compatibility
          final result = MatchCalculationService().calculateMatch(
            currentUser: currentUserData,
            potentialMatch: userData,
          );
          
          // Update with flattened structure
          userData['compatibility'] = {
            'percentage': result.percentage,
            'matchQuality': result.matchQuality,
            'topReasons': result.topReasons,
            
            'emotional': {
              'score': result.breakdown['emotional']?.score ?? 0,
              'percentage': result.breakdown['emotional']?.percentage ?? 0,
              'matches': result.breakdown['emotional']?.matches ?? [],
              'reason': result.breakdown['emotional']?.reason ?? '',
            },
            'chemistry': {
              'score': result.breakdown['chemistry']?.score ?? 0,
              'percentage': result.breakdown['chemistry']?.percentage ?? 0,
              'matches': result.breakdown['chemistry']?.matches ?? [],
              'reason': result.breakdown['chemistry']?.reason ?? '',
            },
            'lifestyle': {
              'score': result.breakdown['lifestyle']?.score ?? 0,
              'percentage': result.breakdown['lifestyle']?.percentage ?? 0,
              'matches': result.breakdown['lifestyle']?.matches ?? [],
              'reason': result.breakdown['lifestyle']?.reason ?? '',
            },
            'lifeGoals': {
              'score': result.breakdown['lifeGoals']?.score ?? 0,
              'percentage': result.breakdown['lifeGoals']?.percentage ?? 0,
              'matches': result.breakdown['lifeGoals']?.matches ?? [],
              'reason': result.breakdown['lifeGoals']?.reason ?? '',
            },
            
            'calculatedAt': DateTime.now().toIso8601String(),
          };
          
          updatedUsers.add(jsonEncode(userData));
          hasUpdates = true;
          
          if (kDebugMode) {
            print('Updated compatibility for ${userData['userId']}');
          }
        } else {
          updatedUsers.add(usersList[i]);
        }
      }
      
      if (hasUpdates) {
        await prefs.setStringList('users_$_currentSessionId', updatedUsers);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking compatibility: $e');
      }
    }
  }

  /* = = = = = = = = =
  Inputs Definition
  = = = = = = = = = */

  List<Input> basics = [
    Input(
      title: "Let\’s clear up the basics",
      possibleValues: [
        "Short Term Exploration",
        "Long Term, Taking My Time",
        "Long Term and Ready",
        "Monogamous",
        "Polyamerous",
        "Monogamous & Open"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> basicInfo = [
    Input(
      title: "nameFirst",
      possibleValues: [],
      type: "text",
    ),
    Input(
      title: "birthDate",
      possibleValues: [],
      type: "calendar",
    ),
    Input(
      title: "ageRange",
      possibleValues: [18, 90],  // Min and max age
      type: "rangeSlider",
    ),
  ];

  List<Input> qual = [
    Input(
      title: "Gender",
      possibleValues: [
        "Man",
        "Woman",
      ],
      type: "checkbox"
    ),
    Input(
      title: "Seeking",
      possibleValues: [
        "Man",
        "Woman",
      ],
      type: "checkbox"
    ),
    Input(
      title: "Location",
      possibleValues: [],
      type: "geopoint",
    )
  ];

  List<Input> emotionalNeeds = [
    Input(
      title: "Emotional Needs",
      possibleValues: [
        "High Empathy and Sensitivity",
        "Exceptionally Proactive, Takes Action",
        "Introspective and Self Aware",
        "Socially Commanding and Experienced",
        "Sweet, Romantic, and Affectionate",
        "Book Smart and Highly Intelligent"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> physicalNeeds = [
    Input(
      title: "How Tall?",
      possibleValues: [0, 100],
      type: "rangeSlider",
    ),
  ];

  List<Input> chemistryNeeds = [
    Input(
      title: "Chemistry Needs",
      possibleValues: [
        "Best Friends",
        "Power Couple",
        "The Provider and Provided For",
        "Romantic Lovers",
        "Feisty Sex Freaks",
        "Wanderlust Explorers"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> logisticNeeds = [
    Input(
      title: "Chemistry Needs",
      possibleValues: [
        "Bar Hopping",
        "Playing Sports",
        "Foodie",
        "Arts and Crafts",
        "Binge Watching",
        "Gaming",
        "Music",
        "Nature",
        "Traveling",
        "Reading",
        "Cooking",
        "Shopping",
        "Volunteering",
        "Fitness",
        "Meditation",
      ],
      type: "checkbox"
    ),
  ];

  List<Input> lifeGoalNeeds = [
    Input(
      title: "Prompts",
      possibleValues: [
        "Travel Frequently and Extensively",
        "Own a Nice Home, Car, and Toys",
        "Maximize Freedom and Flexibility",
        "Maximize Financial Security",
        "Build a Business, An Empire",
        "Pursue Our Craziest Dreams"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> personalityQ1 = [
    Input(
      title: "When youre recharging after a long week, which you do prefer?",
      possibleValues: [
        "Going out, meeting people",
        "Quiet time alone / with partner"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> personalityQ2 = [
    Input(
      title: "When solving problems, which do you trust more?",
      possibleValues: [
        "Facts, proven methods",
        "Intuition, future possibilities"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> personalityQ3 = [
    Input(
      title: "You appreciate partners have which qualities?",
      possibleValues: [
        "Reliable, punctual, and decisive",
        "Go with the flow and adapt easily"
      ],
      type: "checkbox"
    ),
  ];

  List<InputPhoto> photoInputs = [];

  List<String> currentSessionList = [];

  List<String> ignoreList = [];

  List<String> deniedList = [];

}