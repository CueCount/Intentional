import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'localData_service.dart';

/// Service for managing user data in Firestore
class UserDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Get current user ID (auth ID if logged in, temp ID if not)
  Future<String> getCurrentUserId() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return currentUser.uid;
    } else {
      return await LocalDataService.createUserId();
    }
  }
  
  /// Determines if the user is authenticated
  bool isUserAuthenticated() {
    return _auth.currentUser != null;
  }
  
  /// Get user data from Firestore for the specified user ID
  /// If no ID is provided, it uses the current user's ID
  /*Future<Map<String, dynamic>?> getUserData({String? userId}) async {
    try {
      String targetUserId = userId ?? await getCurrentUserId();
      bool isAuth = isUserAuthenticated();
      
      // If not authenticated and no specific ID, check local cache first
      if (!isAuth && userId == null) {
        Map<String, dynamic>? localData = await LocalDataService.fetchFromInputState(context);
        if (localData != null) {
          return localData;
        }
      }
      
      // Fetch from Firestore
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(targetUserId)
          .get();
          
      if (doc.exists) {
        Map<String, dynamic> userData = {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>
        };
        return userData;
      } else {
        print('User document not found for ID: $targetUserId');
        return null;
      }
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }*/
  
  /// Save user data to Firestore
  /// Merges with existing data rather than overwriting
  Future<bool> saveUserData(Map<String, dynamic> data, {String? userId}) async {
    try {
      String targetUserId = userId ?? await getCurrentUserId();
      bool isAuth = isUserAuthenticated();
      
      // Add timestamp
      data['updated_at'] = FieldValue.serverTimestamp();
      
      // If authenticated user doesn't exist yet, add created_at timestamp
      if (isAuth && userId == null) {
        DocumentSnapshot doc = await _firestore
            .collection('users')
            .doc(targetUserId)
            .get();
            
        if (!doc.exists) {
          data['created_at'] = FieldValue.serverTimestamp();
          data['email'] = _auth.currentUser?.email;
        }
      }
      
      // Save to Firestore with merge option
      await _firestore
          .collection('users')
          .doc(targetUserId)
          .set(data, SetOptions(merge: true));
          
      print('Updated user data for ID $targetUserId: $data');
      return true;
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }
  
  /// Fetch multiple users based on optional filters
  Future<List<Map<String, dynamic>>> fetchUsers({
    bool onlyWithPhotos = false,
    List<String>? userIds,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // Filter users by a specific list of user IDs if provided
      if (userIds != null && userIds.isNotEmpty) {
        // Firestore can only query up to 10 items in a whereIn clause
        if (userIds.length <= 10) {
          query = query.where(FieldPath.documentId, whereIn: userIds);
        } else {
          // For larger lists, we'll filter after fetching
          print('Warning: More than 10 userIds provided. Performing client-side filtering.');
        }
      }

      // Apply additional filters if provided
      if (additionalFilters != null) {
        additionalFilters.forEach((field, value) {
          query = query.where(field, isEqualTo: value);
        });
      }

      // Only fetch users with at least one photo if specified
      if (onlyWithPhotos) {
        query = query.where('photos', isNull: false);
      }

      QuerySnapshot snapshot = await query.get();

      List<Map<String, dynamic>> results = snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
          
      // Apply client-side filtering for large userIds lists if needed
      if (userIds != null && userIds.length > 10) {
        results = results.where((user) => userIds.contains(user['id'])).toList();
      }

      return results;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }
  
  /*
    Check is these save functions and upload have accomidations for photos
  */

}