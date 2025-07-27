import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class FetchDataService {

  /* = = = = = = = = = =
  Fetch Users From SharedPreferences
  = = = = = = = = = */
  Future<List<Map<String, dynamic>>> fetchUserProfilesFromSharedPreferences() async {
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

  /* = = = = = = = = = =
  Fetch Users From Firebase (with better debugging)
  = = = = = = = = = */
  Future<List<Map<String, dynamic>>> fetchUsersFromFirebase({
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
          print('👤 User ${doc.id}: photos = ${data['photos']} (type: ${data['photos'].runtimeType})');
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
        print('🔍 Filtering ${allResults.length} users for photos...');
        
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
          
          print('👤 User ${user['id']}: hasPhotos = $hasPhotos, photos = $photos');
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

  /* = = = = = = = = = =
  Check Data In SharedPreferences
  = = = = = = = = = */
  static Future<bool> checkProfileCompleteness() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('❌ No logged-in user found.');
        return true;
      }

      final userId = currentUser.uid;
      final prefs = await SharedPreferences.getInstance();
      final key = 'user_data_$userId';
      final userJson = prefs.getString(key);

      if (userJson == null || userJson.isEmpty) {
        print('⚠️ No cached data found for user $userId');
        return true;
      }

      final userData = json.decode(userJson) as Map<String, dynamic>;

      final firstName = userData['firstName'] ?? '';
      print('firstName: $firstName');
      final birthDate = userData['birthDate'] ?? 0;
      print('birthDate: $birthDate');
      final gender = userData['Gender'] ?? ''; 
      print('gender: $gender');

      final hasGaps = firstName.isEmpty || birthDate == 0 || gender.isEmpty;

      print('👤 Profile check for $userId → hasGaps: $hasGaps');
      return hasGaps;
    } catch (e) {
      print('❌ Error checking profile completeness: $e');
      return true;
    }
  }
}

Map<String, dynamic> cleanUserData(Map<String, dynamic> user) {
  Map<String, dynamic> cleanUser = {};
  user.forEach((key, value) {
    if (value is Timestamp) {
      cleanUser[key] = value.millisecondsSinceEpoch;
    } else if (value is DateTime) {
      cleanUser[key] = value.millisecondsSinceEpoch;
    } else if (value is GeoPoint) {
      // Convert GeoPoint to a serializable format
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