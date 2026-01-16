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
  Save Input
  = = = = = = = = = */

  Future<void> saveInputToRemoteThenLocal(Map<String, dynamic>? needData) async {
    try {
      if (_currentSessionId.isEmpty) {
        throw Exception("No session ID available");
      }
      
      if (needData == null || needData.isEmpty) {
        print('⚠️ No data to save');
        return;
      }

      // 1. Save to Firestore 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentSessionId)
          .set({
            ...needData,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Saved to users/${_currentSessionId}');
      }

      // 2. Save locally to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = 'inputs_$_currentSessionId';
      
      String? existingDataJson = prefs.getString(key);
      Map<String, dynamic> existingData = {};
      
      if (existingDataJson != null && existingDataJson.isNotEmpty) {
        Map rawData = json.decode(existingDataJson);
        rawData.forEach((k, v) => existingData[k.toString()] = v);
      }

      final mergedData = {
        ...existingData,
        ...needData,
        'session_id': _currentSessionId,
        'last_updated': DateTime.now().toIso8601String(),
      };

      await prefs.setString(key, json.encode(mergedData));
      
      _cachedInputs.addAll(needData);
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Saved locally under key "$key"');
      }
      
    } catch (e) {
      print('❌ saveInputToRemoteThenLocal: Failed - $e');
      rethrow;
    }
  }

  Future<void> saveInputToRemoteThenLocalInOnboarding(Map<String, dynamic>? needData) async {
    try {
      if (_currentSessionId.isEmpty) {
        throw Exception("No session ID available");
      }
      
      if (needData == null || needData.isEmpty) {
        print('⚠️ No data to save');
        return;
      }

      // 1. Save to Firestore 'users_onboarding' collection
      await FirebaseFirestore.instance
          .collection('users_onboarding')
          .doc(_currentSessionId)
          .set({
            ...needData,
            'lastUpdated': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Saved to users_onboarding/${_currentSessionId}');
      }

      // 2. Save locally to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final key = 'inputs_$_currentSessionId';
      
      String? existingDataJson = prefs.getString(key);
      Map<String, dynamic> existingData = {};
      
      if (existingDataJson != null && existingDataJson.isNotEmpty) {
        Map rawData = json.decode(existingDataJson);
        rawData.forEach((k, v) => existingData[k.toString()] = v);
      }

      final mergedData = {
        ...existingData,
        ...needData,
        'session_id': _currentSessionId,
        'last_updated': DateTime.now().toIso8601String(),
      };

      await prefs.setString(key, json.encode(mergedData));
      
      _cachedInputs.addAll(needData);
      notifyListeners();
      
      if (kDebugMode) {
        print('✅ Saved locally under key "$key"');
      }
      
    } catch (e) {
      print('❌ saveInputToRemoteThenLocalInOnboarding: Failed - $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveInputsToLocalFromRemote(String userId) async {
    try {
      if (userId.isEmpty) {
        if (kDebugMode) {
          print('❌ fetchInputs: No userId provided');
        }
        return {};
      }

      if (kDebugMode) {
        print('🔄 fetchInputs: Fetching data for user: $userId');
      }

      // Fetch from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        if (kDebugMode) {
          print('⚠️ fetchInputs: No document found for user: $userId');
        }
        return {};
      }

      Map<String, dynamic> userData = doc.data()!;

      if (kDebugMode) {
        print('✅ fetchInputs: Retrieved ${userData.keys.length} fields from Firestore');
      }

      // Prepare data for SharedPreferences (remove non-serializable fields)
      Map<String, dynamic> serializableData = Map<String, dynamic>.from(userData);
      serializableData.removeWhere((key, value) => 
        value is Timestamp ||
        key == 'lastUpdated' ||
        key.startsWith('_')
      );

      // Convert any remaining Timestamps to ISO strings
      serializableData.forEach((key, value) {
        if (value is Timestamp) {
          serializableData[key] = value.toDate().toIso8601String();
        }
      });

      // Save to SharedPreferences, overwriting existing data
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('inputs_$userId', jsonEncode(serializableData));

      if (kDebugMode) {
        print('✅ fetchInputs: Saved to SharedPreferences under inputs_$userId');
      }

      // Update cached inputs and session ID
      _cachedInputs = serializableData;
      _currentSessionId = userId;
      notifyListeners();

      return serializableData;

    } catch (e) {
      if (kDebugMode) {
        print('❌ fetchInputs: Failed - $e');
      }
      return {};
    }
  }

  /* = = = = = = = = =
  Fetch Input
  = = = = = = = = = */

  Future<Map<String, dynamic>> fetchInputsFromLocal() async {
    try {
      if (_currentSessionId.isEmpty) { return {}; }
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$_currentSessionId');
      if (inputsJson != null) { return jsonDecode(inputsJson); }
      return {};
    } catch (e) {
      print('InputState Error: Failed to get all inputs - $e');
      return {};
    }
  }

  Future<dynamic> fetchInputFromLocal(String inputKey) async {
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
          
          // Value exists and is not empty
          return value;
        }
      }
      
      return null;
    } catch (e) {
      print('InputState Error: Failed to get input $inputKey - $e');
      return null;
    }
  }

  /* = = = = = = = = =
  Save/Fetch Photo 
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

  Future<List<String>> uploadPhotosToStorage(List<dynamic> localPhotos, String userId) async {
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

  /* = = = = = = = = =
  Compatibility
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> generateCompatibility(List<Map<String, dynamic>> users) async {
    if (_currentSessionId.isEmpty) return users;
  
    try {
      final currentUserData = await fetchInputsFromLocal();
      final List<Map<String, dynamic>> processedUsers = [];
      
      for (var userData in users) {
        // Check if compatibility is missing
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
            
            'archetypes': result.archetypeAnalysis != null ? {
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
              'summary': result.archetypeAnalysis!['summary'],
              'narrative': result.archetypeAnalysis!['narrative'],
              'traitDistribution': result.archetypeAnalysis!['traitDistribution'],
              'dynamicsPattern': result.archetypeAnalysis!['dynamicsPattern'],
            } : null,
            
            'calculatedAt': DateTime.now().toIso8601String(),
          };
          
          if (kDebugMode) {
            print('Updated compatibility for ${userData['userId']}');
          }
        }
        
        processedUsers.add(userData);
      }
      
      return processedUsers;
      
    } catch (e) {
      if (kDebugMode) {
        print('Error checking compatibility: $e');
      }
      return users;
    }
  }

  /* = = = = = = = = =
  Inputs Definition
  = = = = = = = = = */

  List<Input> basics = [
    Input(
      title: "basics",
      possibleValues: [
        "Short Term Exploration",
        "Long Term But Taking My Time",
        "Long Term & Ready for Relationship Now",
      ],
      type: "checkbox"
    ),
    Input(
      title: "relationshipType",
      possibleValues: [
        "Monogamous",
        "Polyamerous",
        "Monogamous + Open"
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