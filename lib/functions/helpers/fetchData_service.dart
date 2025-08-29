import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/inputState.dart';

class FetchDataService {

  /* = = = = = = = = =
  Fetch Matches From 
  SharedPreferences / Firebase
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> fetchMatchesFromSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('user_data_')).toList();

    List<Map<String, dynamic>> cachedUsers = [];

    for (var key in keys) {
      final userJson = prefs.getString(key);
      if (userJson != null) {
        try {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          cachedUsers.add(userData);
        } catch (e) {
          print('❌ Error decoding user data for key $key: $e');
        }
      }
    }

    print('📦 Loaded ${cachedUsers.length} profiles from SharedPreferences cache');
    return cachedUsers;
  }

  Future<List<Map<String, dynamic>>> fetchMatchesFromFirebase({
    bool onlyWithPhotos = false,
    List<String>? userIds,
    Map<String, dynamic>? additionalFilters,
  }) async {
    
    try {
      Query query = FirebaseFirestore.instance.collection('users');

      /* = = = = = = = = = =
      By UserIDs
      = = = = = = = = = = */
      if (userIds != null && userIds.isNotEmpty) {
        if (userIds.length <= 10) {
          query = query.where(
            FieldPath.documentId, 
            whereIn: userIds
            );
        } else {
          print('❌ Error: More than 10 userIds provided');
        }
      }

      /* = = = = = = = = = =
      By Additional Filters
      = = = = = = = = = = */
      if (additionalFilters != null) {
        additionalFilters.forEach((field, value) {
          query = query.where(
            field, 
            isEqualTo: value
            );
        });
      }

      /* = = = = = = = = = =
      Debug: Check all users first
      = = = = = = = = = = */
      if (onlyWithPhotos) {
        QuerySnapshot allSnapshot = await FirebaseFirestore.instance.collection('users').get();
        print('🔍 Total users in Firebase: ${allSnapshot.docs.length}');
        
        for (var doc in allSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
        }
      }

      /* = = = = = = = = = =
      Get Results and Filter Photos in Dart
      = = = = = = = = = = */
      QuerySnapshot snapshot = await query.get();
      List<Map<String, dynamic>> allResults = snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();

      if (onlyWithPhotos) {
        
        // Filter users with photos in Dart (more reliable than Firestore query)
        List<Map<String, dynamic>> usersWithPhotos = allResults.where((user) {
          final photos = user['photos'];
          bool hasPhotos = false;
          
          if (photos != null) {
            if (photos is List && photos.isNotEmpty) {
              hasPhotos = true;
            } else if (photos is Map && photos.isNotEmpty) {
              hasPhotos = true;
            } else if (photos is String && photos.isNotEmpty) {
              hasPhotos = true;
            }
          }
          return hasPhotos;
        }).toList();
        
        print('✅ Found ${usersWithPhotos.length} users with photos out of ${allResults.length} total');
        return usersWithPhotos;
      }

      print('✅ Found ${allResults.length} total users');
      return allResults;

    } catch (e) {
      print('❌ Error fetching users from Firebase: $e');
      return [];
    }
  }

  /* = = = = = = = = =
  Fetch User Data from 
  Provider / Shared Preferences / Firebase
  = = = = = = = = = */

  static Map<String, dynamic> fetchFromInputState(
    BuildContext context
  ) {
    final inputState = Provider.of<InputState>(context, listen: false);
    final data = inputState.getCachedInputs();
    print('📥 Data fetched from InputState:\n$data');
    return data;
  }

  static Future<Map<String, dynamic>> fetchUserFromSharedPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_data_$userId';
      final userDataString = prefs.getString(key);
      
      if (userDataString != null) {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        print('📥 Found user data for: $userId');
        return userData;
      } else {
        print('⚠️ No user data found for: $userId');
        return {};
      }
      
    } catch (e) {
      print('❌ getUserDataFromSharedPref: Failed - $e');
      return {};
    }
  }
  
  static Future<Map<String, dynamic>> fetchUserFromFirebase(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final docSnapshot = await firestore.collection('users').doc(userId).get();
      
      if (docSnapshot.exists) {
        final userData = docSnapshot.data() as Map<String, dynamic>;
        print('✅ Fetched session data from Firebase for user: $userId');
        return userData;
      } else {
        print('⚠️ No session data found in Firebase for user: $userId');
        return {};
      }
      
    } catch (e) {
      print('❌ fetchSessionDataFromFirebase: Failed - $e');
      return {};
    }
  }

  /* = = = = = = = = =
  Fetch Sent Requests From 
  SharedPreferences / Firebase
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> fetchSentRequestsFromSharedPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList('sent_requests_$userId') ?? [];
      final requests = requestsJson.map((requestStr) => 
        Map<String, dynamic>.from(jsonDecode(requestStr))
      ).toList();
      
      print('📦 Loaded ${requests.length} sent requests from SharedPreferences cache');
      return requests;
    } catch (e) {
      print('❌ Error fetching sent requests from SharedPreferences: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchSentRequestsFromFirebase(String userId) async {
    try {
      // Query matches collection for outgoing requests
      final querySnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('requesterUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      List<Map<String, dynamic>> requests = [];
      
      // Loop through each match document
      for (var matchDoc in querySnapshot.docs) {
        Map<String, dynamic> matchData = matchDoc.data();
        String requestedUserId = matchData['requestedUserId'];
        
        // Get the requested user's profile
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(requestedUserId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // Add structured data
          requests.add({
            'matchId': matchDoc.id,
            'matchData': matchData,
            'userData': userData,
            'requestedUserId': requestedUserId,
          });
        }
      }
      
      return requests;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sent requests: $e');
      }
      return [];
    }
  }

  /* = = = = = = = = =
  Fetch Received Requests From 
  SharedPreferences / Firebase
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> fetchReceivedRequestsFromSharedPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final requestsJson = prefs.getStringList('received_requests_$userId') ?? [];
      final requests = requestsJson.map((requestStr) => 
        Map<String, dynamic>.from(jsonDecode(requestStr))
      ).toList();
      
      print('📦 Loaded ${requests.length} received requests from SharedPreferences cache');
      return requests;
    } catch (e) {
      print('❌ Error fetching received requests from SharedPreferences: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> fetchReceivedRequestsFromFirebase(String userId) async {
    try {
      // Query matches collection for outgoing requests
      final querySnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('requestedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      List<Map<String, dynamic>> requests = [];
      
      // Loop through each match document
      for (var matchDoc in querySnapshot.docs) {
        Map<String, dynamic> matchData = matchDoc.data();
        String requesterUserId = matchData['requesterUserId'];
        
        // Get the requested user's profile
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(requesterUserId)
            .get();
        
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          // Add structured data
          requests.add({
            'matchId': matchDoc.id,
            'matchData': matchData,
            'userData': userData,
            'requesterUserId': requesterUserId,
          });
        }
      }
      
      return requests;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching receieved requests: $e');
      }
      return [];
    }
  }

  /* = = = = = = = = =
  Clean User Data
  = = = = = = = = = */

  Map<String, dynamic> cleanUserData(Map<String, dynamic> user) {
    Map<String, dynamic> cleanUser = {};
    user.forEach((key, value) {
      if (value is Timestamp) {
        cleanUser[key] = value.millisecondsSinceEpoch;
      } else if (value is DateTime) {
        cleanUser[key] = value.millisecondsSinceEpoch;
      } else if (value is GeoPoint) {
        cleanUser[key] = {
          'latitude': value.latitude,
          'longitude': value.longitude,
        };
      } else if (value is List) {
        cleanUser[key] = List.from(value);
      } else if (value is Map) {
        cleanUser[key] = Map<String, dynamic>.from(value);
      } else {
        cleanUser[key] = value;
      }
    });
    return cleanUser;
  }

}