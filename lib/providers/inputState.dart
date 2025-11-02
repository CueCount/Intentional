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
  final String? networkUrl;  // For Firebase Storage URLs
  InputPhoto({this.croppedBytes, this.localPath, this.networkUrl});
  Map<String, dynamic> toJson() => {};
}

class InputState extends ChangeNotifier {
  Map<String, dynamic> _cachedInputs = {};
  String _currentSessionId = '';
  String get userId => _currentSessionId;

  /* = = = = = = = = =
  Save Inputs Onboarding 
  = = = = = = = = = */

  Future<void> inputsSaveOnboarding(Map<String, dynamic>? needData) async {
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
  Current Session Id
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
  
  /* = = = = = = = = =
  Loading Input
  = = = = = = = = = */

  Future<Map<String, dynamic>> inputsLoad() async {
    try {
      if (_currentSessionId.isEmpty) {
        return {};
      }
      
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$_currentSessionId');

      // if 

      // if

      // if
      
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

  Future<dynamic> getSpecificInputForUserQuery(String inputKey) async {
    try {
      if (_currentSessionId.isEmpty) return null;
      
      // First check SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final existingJson = prefs.getString('inputs_$_currentSessionId');
      
      if (existingJson != null) {
        final cached = jsonDecode(existingJson);
        if (cached[inputKey] != null) {
          return cached[inputKey];  // Return cached value
        }
      }
      
      // If not cached, fetch from Firebase
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentSessionId)
          .get();
      
      if (!docSnap.exists) return null;
      
      final firebaseData = docSnap.data()!;
      return firebaseData[inputKey];  // Return the specific value
      
    } catch (e) {
      print('InputState Error: Failed to get input - $e');
      return null;
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
        // Network URL (Firebase Storage or other) - preserve as-is
        if (photo.networkUrl != null) {
          photoPaths.add(photo.networkUrl!);
        }
        // For web, store the bytes as a data URI
        else if (kIsWeb && photo.croppedBytes != null) {
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
        if (path.startsWith('http://') || path.startsWith('https://')) {
          // Firebase Storage URL or other network URL
          photoInputs.add(InputPhoto(networkUrl: path));
        } else if (kIsWeb && path.startsWith('data:')) {
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
      final currentUserData = await inputState.inputsLoad();
      
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
            includeArchetypes: true,
          );
          
          // Full data structure with complete archetype analysis
          userData['compatibility'] = {
            // Core compatibility data
            'percentage': result.percentage,
            'matchQuality': result.matchQuality,
            'topReasons': result.topReasons,
            
            // Category breakdowns
            'personality': {
              'score': result.breakdown['personality']?.score ?? 0,
              'percentage': result.breakdown['personality']?.percentage ?? 0,
              'matches': result.breakdown['personality']?.matches ?? [],
              'reason': result.breakdown['personality']?.reason ?? '',
            },
            'relationship': {
              'score': result.breakdown['relationship']?.score ?? 0,
              'percentage': result.breakdown['relationship']?.percentage ?? 0,
              'matches': result.breakdown['relationship']?.matches ?? [],
              'reason': result.breakdown['relationship']?.reason ?? '',
            },
            'interests': {
              'score': result.breakdown['interests']?.score ?? 0,
              'percentage': result.breakdown['interests']?.percentage ?? 0,
              'matches': result.breakdown['interests']?.matches ?? [],
              'reason': result.breakdown['interests']?.reason ?? '',
            },
            'goals': {
              'score': result.breakdown['goals']?.score ?? 0,
              'percentage': result.breakdown['goals']?.percentage ?? 0,
              'matches': result.breakdown['goals']?.matches ?? [],
              'reason': result.breakdown['goals']?.reason ?? '',
            },
            
            // NEW: Complete archetype analysis
            'archetypes': result.archetypeAnalysis != null ? {
              // Primary archetypes
              'personality': result.archetypeAnalysis!['personalityArchetype'] != null ? {
                'name': result.archetypeAnalysis!['personalityArchetype']['name'],
                'description': result.archetypeAnalysis!['personalityArchetype']['description'],
                'strengths': result.archetypeAnalysis!['personalityArchetype']['strengths'] ?? [],
                'watchOuts': result.archetypeAnalysis!['personalityArchetype']['watchOuts'] ?? [],
              } : null,
              'relationship': result.archetypeAnalysis!['relationshipStyle'] != null ? {
                'name': result.archetypeAnalysis!['relationshipStyle']['name'],
                'description': result.archetypeAnalysis!['relationshipStyle']['description'],
                'characteristics': result.archetypeAnalysis!['relationshipStyle']['characteristics'] ?? [],
                'idealDate': result.archetypeAnalysis!['relationshipStyle']['idealDate'],
                'longTermOutlook': result.archetypeAnalysis!['relationshipStyle']['longTermOutlook'],
              } : null,
              // Summary data
              'summary': result.archetypeAnalysis!['summary'],
              'narrative': result.archetypeAnalysis!['narrative'],
              // Distribution analysis
              'traitDistribution': result.archetypeAnalysis!['traitDistribution'],
              'dynamicsPattern': result.archetypeAnalysis!['dynamicsPattern'],
            } : null,
            
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

  List<Input> personality = [
    Input(
      title: "personality",
      possibleValues: [
        "Empathetic",
        "Proactive",
        "Introspective",
        "Outgoing",
        "Romantic",
        "Honest",
        "Intelligent",
        "Curious",
        "Loyal",
        "Confident",
        "Patient",
        "Playful",
        "Ambitious",
        "Generous",
      ],
      type: "checkbox"
    ),
  ];

  List<Input> relationship = [
    Input(
      title: "relationship",
      possibleValues: [
        "We’re Best Friends",
        "We Explore the World",
        "We Run a Business Together",
        "Let’s Be Homebodies",
        "We’re a Career Couple",
        "I Financially Provide for Them",
        "They Financially Provide for Me",
        "We’re Romantic Lovers",
        "We’re Feisty Freaks",
        "We Share Religious Faith",
        "We’re a Parenting Team",
        "We’re a Fitness Couple",
      ],
      type: "checkbox"
    ),
  ];

  List<Input> interests = [
    Input(
      title: "interests",
      possibleValues: [
        "Hiking",
        "Camping",
        "Surfing",
        "Rock Climbing",
        "Biking",
        "Scuba Diving",
        "Road Trips",
        "Skiing / Snowboarding",
        "Painting / Drawing",
        "Music",
        "Photography",
        "Writing",
        "Theatre",
        "Dance",
        "Design",
        "Film",
        "Reading",
        "Meditation",
        "Personal Development",
        "Psychology",
        "Philosophy",
        "Road Trips",
        "Journaling",
        "Languages",
        "Gym",
        "Running",
        "Yoga",
        "Martial Arts",
        "CrossFit",
        "Nutrition",
        "Team Sports",
        "Swimming",
        "Tennis",
        "Journaling",
        "Cooking",
        "Wine Tasting",
        "Coffee Culture",
        "Fashion",
        "Gardening",
        "Traveling",
        "Collecting Art",
        "Restaurants",
        "Coding",
        "AI & Future Tech",
        "Gaming",
        "Investing",
        "Gadgets",
        "History",
        "Religion",
        "Volunteering",
        "Spirituality",
        "Family",
        "Activism",
      ],
      type: "checkbox"
    ),
  ];

  List<Input> lifeGoalNeeds = [
    Input(
      title: "lifeGoals",
      possibleValues: [
        "Visit Every Country",
        "Raise a Family",
        "Maximize Social Status",
        "Build an Empire",
        "Chill Out and Enjoy Life",
        "Live Sustainably",
        "Gain Financial Freedom",
        "Discover Inner Peace",
        "Cultivate Community",
        "Become Wealthy",
      ],
      type: "checkbox"
    ),
  ];

  // Extra Needs

  List<Input> personalityQ1 = [
    Input(
      title: "When you're recharging after a long week, which you do prefer?",
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

  List<Input> personalityQ4 = [
    Input(
      title: "How do you prefer to experience life?",
      possibleValues: [
        "Seeking new adventures and experiences",
        "Finding comfort in routines and traditions"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> relationshipQ1 = [
    Input(
      title: "How do you prefer to handle conflict?",
      possibleValues: [
        "Address issues immediately and directly",
        "Take time to process before discussing"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> relationshipQ2 = [
    Input(
      title: "Your ideal amount of together time?",
      possibleValues: [
        "Most of our free time together",
        "Healthy balance of together and apart"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> relationshipQ3 = [
    Input(
      title: "How do you show and receive love best?",
      possibleValues: [
        "Words of affirmation and quality time",
        "Physical touch and acts of service"
      ],
      type: "checkbox"
    ),
  ];
  
  List<Input> relationshipQ4 = [
    Input(
      title: "What's your communication style?",
      possibleValues: [
        "Share everything, full transparency",
        "Some privacy, independence is healthy"
      ],
      type: "checkbox"
    ),
  ];

  List<InputPhoto> photoInputs = [];

  List<String> currentSessionList = [];

  List<String> ignoreList = [];

  List<String> deniedList = [];

}