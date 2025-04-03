import 'package:cloud_firestore/cloud_firestore.dart';
import 'userData_service.dart';
import 'localData_service.dart';

/// Service for handling match-related functionality
class MatchesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserDataService _userDataService = UserDataService();
  
  /// Calculate potential matches for the current user
  /// Returns a list of user data objects that match criteria
  Future<List<Map<String, dynamic>>> calculateMatches({
    int limit = 20,
    bool useCache = true
  }) async {
    try {
      // Check if we have cached matches and should use them
      /*if (useCache) {
        List<Map<String, dynamic>> cachedMatches = await UserDataService.fetchUsers();
        if (cachedMatches.isNotEmpty) {
          print('Returning ${cachedMatches.length} matches from cache');
          return cachedMatches;
        }
      }*/
      
      /* Get current user data to match against
      String currentUserId = await _userDataService.getCurrentUserId();
      Map<String, dynamic>? userData = await _userDataService.fetchUsers();
      
      if (userData == null) {
        print('No user data available to calculate matches');
        return [];
      }
      
      // Extract user preferences for matching
      Map<String, dynamic> preferences = userData['preferences'] ?? {};
      
      // Get existing matches to exclude
      List<String> existingMatchIds = [];
      if (userData.containsKey('matches')) {
        existingMatchIds = List<String>.from(userData['matches'] ?? []);
      }
      
      // Get users that user has already rejected to exclude
      List<String> rejectedIds = [];
      if (userData.containsKey('rejected')) {
        rejectedIds = List<String>.from(userData['rejected'] ?? []);
      }
      
      // Combined list of users to exclude from new matches
      List<String> excludeIds = [...existingMatchIds, ...rejectedIds, currentUserId];
      
      // Build query based on preferences
      Query query = _firestore.collection('users');
      
      // Apply filters based on preferences
      // Add your specific matching criteria here
      if (preferences.containsKey('age_min') && preferences['age_min'] != null) {
        query = query.where('age', isGreaterThanOrEqualTo: preferences['age_min']);
      }
      
      if (preferences.containsKey('age_max') && preferences['age_max'] != null) {
        query = query.where('age', isLessThanOrEqualTo: preferences['age_max']);
      }
      
      if (preferences.containsKey('gender') && preferences['gender'] != null) {
        query = query.where('gender', isEqualTo: preferences['gender']);
      }
      
      // Only users with photos
      query = query.where('photos', isNull: false);
      
      // Execute the query
      QuerySnapshot snapshot = await query.limit(limit + excludeIds.length).get();
      
      // Filter out excluded users and convert to list of user data objects
      List<Map<String, dynamic>> potentialMatches = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .where((userData) => !excludeIds.contains(userData['id']))
          .toList();
      
      // Limit to requested number
      if (potentialMatches.length > limit) {
        potentialMatches = potentialMatches.sublist(0, limit);
      }*/
      
      return [];
    } catch (e) {
      print('Error calculating matches: $e');
      return [];
    }
  }
  
  /// Unmatch with another user
  Future<void> unmatchUser(String targetUserId) async {
    try {
      final currentUserId = await _userDataService.getCurrentUserId();
      
      // Remove from current user's matches
      await _firestore.collection('users').doc(currentUserId).update({
        'matches': FieldValue.arrayRemove([targetUserId]),
      });
      
      // Remove from target user's matches
      await _firestore.collection('users').doc(targetUserId).update({
        'matches': FieldValue.arrayRemove([currentUserId]),
      });
      
      // Add to rejected to prevent future matches
      await _firestore.collection('users').doc(currentUserId).update({
        'rejected': FieldValue.arrayUnion([targetUserId]),
        'rejected_timestamp.${targetUserId}': FieldValue.serverTimestamp(),
      });
      
      // Archive chat
      String chatId = currentUserId.compareTo(targetUserId) < 0
          ? '${currentUserId}_${targetUserId}'
          : '${targetUserId}_${currentUserId}';
          
      await _firestore.collection('chats').doc(chatId).update({
        'archived': true,
        'archived_by': FieldValue.arrayUnion([currentUserId]),
        'archived_at': FieldValue.serverTimestamp(),
      });
      
      print('Unmatched $currentUserId from $targetUserId');
    } catch (e) {
      print('Error unmatching user: $e');
      throw e;
    }
  }
  
}