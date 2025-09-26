// users_in_review collection structure:
// users_in_review/{userId}
// {
//   ...originalUserData,
//   "reviewEvents": [
//     {
//       "id": "auto_generated_unique_id",
//       "reason": "flagged_by_user",
//       "timestamp": Timestamp,
//       "flaggedBy": "user_id_who_flagged", // optional
//       "details": "inappropriate photos"
//     },
//     {
//       "id": "auto_generated_unique_id_2", 
//       "reason": "missed_payment",
//       "timestamp": Timestamp,
//       "paymentId": "payment_123",
//       "details": "3rd consecutive failed payment"
//     }
//   ],
//   "approved": false,
//   "approvedAt": null,
//   "approvedBy": null,
//   "createdAt": Timestamp // when first moved to review
// }

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class UserReviewService {
  static const String reviewCollection = 'users_in_review';
  static const String usersCollection = 'users';
  
  // Move user to review with reason
  static Future<void> moveUserToReview({
    required String userId,
    required String reason,
    String? flaggedBy,
    String? details,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Get original user document
      final userDoc = await FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(userId)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('User not found');
      }
      
      final userData = userDoc.data()!;
      
      // Check if user is already in review
      final existingReviewDoc = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .get();
      
      if (existingReviewDoc.exists) {
        // User already in review - add new event to array
        await _addReviewEvent(
          userId: userId,
          reason: reason,
          flaggedBy: flaggedBy,
          details: details,
          additionalData: additionalData,
        );
      } else {
        // Create new review document
        final reviewEvent = {
          'id': const Uuid().v4(),
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
          if (flaggedBy != null) 'flaggedBy': flaggedBy,
          if (details != null) 'details': details,
          if (additionalData != null) ...additionalData,
        };
        
        await FirebaseFirestore.instance
            .collection(reviewCollection)
            .doc(userId)
            .set({
          ...userData,
          'reviewEvents': [reviewEvent],
          'approved': false,
          'approvedAt': null,
          'approvedBy': null,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Remove from active users collection
        await FirebaseFirestore.instance
            .collection(usersCollection)
            .doc(userId)
            .delete();
      }
      
      print('User $userId moved to review for: $reason');
      
    } catch (e) {
      print('Error moving user to review: $e');
      rethrow;
    }
  }
  
  // Add additional review event to existing review user
  static Future<void> _addReviewEvent({
    required String userId,
    required String reason,
    String? flaggedBy,
    String? details,
    Map<String, dynamic>? additionalData,
  }) async {
    final newEvent = {
      'id': const Uuid().v4(),
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      if (flaggedBy != null) 'flaggedBy': flaggedBy,
      if (details != null) 'details': details,
      if (additionalData != null) ...additionalData,
    };
    
    await FirebaseFirestore.instance
        .collection(reviewCollection)
        .doc(userId)
        .update({
      'reviewEvents': FieldValue.arrayUnion([newEvent]),
    });
  }
  
  // Approve user and move back to active users
  static Future<void> approveUser({
    required String userId,
    required String approvedBy,
    String? eventId, // Specify which event to approve, or null for most recent
  }) async {
    try {
      // Get review document
      final reviewDoc = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .get();
      
      if (!reviewDoc.exists) {
        throw Exception('User not found in review');
      }
      
      final reviewData = reviewDoc.data()!;
      List<dynamic> reviewEvents = List.from(reviewData['reviewEvents'] ?? []);
      
      // Find the event to update (most recent if eventId not specified)
      int eventIndex = -1;
      if (eventId != null) {
        eventIndex = reviewEvents.indexWhere((event) => event['id'] == eventId);
      } else {
        eventIndex = reviewEvents.length - 1; // Most recent event
      }
      
      if (eventIndex == -1) {
        throw Exception('Review event not found');
      }
      
      // Update the specific event with approval info
      reviewEvents[eventIndex]['approvedBy'] = approvedBy;
      reviewEvents[eventIndex]['approval_timestamp'] = FieldValue.serverTimestamp();
      
      // Update review data
      reviewData['reviewEvents'] = reviewEvents;
      reviewData['approved'] = true;
      reviewData['approvedAt'] = FieldValue.serverTimestamp();
      reviewData['approvedBy'] = approvedBy;
      
      // Move back to users collection WITH full audit trail
      await FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(userId)
          .set({
        ...reviewData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Update the review document
      await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .update({
        'approved': true,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': approvedBy,
        'reviewEvents': reviewEvents,
      });
      
      print('User $userId approved and moved back to active users');
      
    } catch (e) {
      print('Error approving user: $e');
      rethrow;
    }
  }
  
  // Method to permanently remove user after upheld flag
  static Future<void> removeUserPermanently({
    required String userId,
    required String removedBy,
    required String eventId,
  }) async {
    try {
      final reviewDoc = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .get();
      
      if (!reviewDoc.exists) {
        throw Exception('User not found in review');
      }
      
      final reviewData = reviewDoc.data()!;
      List<dynamic> reviewEvents = List.from(reviewData['reviewEvents'] ?? []);
      
      // Find the specific upheld event
      int eventIndex = reviewEvents.indexWhere((event) => 
        event['id'] == eventId && event['upheldBy'] != null);
      
      if (eventIndex == -1) {
        throw Exception('Upheld review event not found');
      }
      
      // Update the event with removal info
      reviewEvents[eventIndex]['removedBy'] = removedBy;
      reviewEvents[eventIndex]['removal_timestamp'] = FieldValue.serverTimestamp();
      reviewEvents[eventIndex]['removal_reason'] = 'Permanently removed due to upheld flag';
      
      // Update review data
      reviewData['reviewEvents'] = reviewEvents;
      reviewData['permanentlyRemoved'] = true;
      reviewData['removedAt'] = FieldValue.serverTimestamp();
      reviewData['removedBy'] = removedBy;
      
      // Move to permanent removal collection for legal protection
      await FirebaseFirestore.instance
          .collection('users_removed')
          .doc(userId)
          .set({
        ...reviewData,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Remove from review collection
      await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .delete();
      
      print('User $userId permanently removed and archived');
      
    } catch (e) {
      print('Error permanently removing user: $e');
      rethrow;
    }
  }
  
  // Method to delete user account (for payment issues, non-approval, etc.)
  static Future<void> deleteUserAccount({
    required String userId,
    required String deletedBy,
    String reason = 'Account deletion',
  }) async {
    try {
      // Check if user is in review
      final reviewDoc = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .get();
      
      if (reviewDoc.exists) {
        // Delete from review collection
        await FirebaseFirestore.instance
            .collection(reviewCollection)
            .doc(userId)
            .delete();
      }
      
      // Check if user is in active users
      final userDoc = await FirebaseFirestore.instance
          .collection(usersCollection)
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        // Delete from users collection  
        await FirebaseFirestore.instance
            .collection(usersCollection)
            .doc(userId)
            .delete();
      }
      
      // Optional: Log deletion for admin records
      await FirebaseFirestore.instance
          .collection('user_deletions')
          .doc(userId)
          .set({
        'deletedBy': deletedBy,
        'deletedAt': FieldValue.serverTimestamp(),
        'reason': reason,
        'userId': userId,
      });
      
      print('User $userId account deleted for: $reason');
      
    } catch (e) {
      print('Error deleting user account: $e');
      rethrow;
    }
  }
  
  // Convenience method for handling flagged users workflow
  static Future<void> handleUpheldFlag({
    required String userId,
    required String adminId,
    required String eventId,
    required bool shouldRemovePermanently,
  }) async {
    // First uphold the flag
    await upholdFlag(
      userId: userId,
      upheldBy: adminId,
      eventId: eventId,
    );
    
    if (shouldRemovePermanently) {
      // Move to users_removed for legal protection
      await removeUserPermanently(
        userId: userId,
        removedBy: adminId,
        eventId: eventId,
      );
    } else {
      // Just delete the account (e.g., minor violation, first offense)
      await deleteUserAccount(
        userId: userId,
        deletedBy: adminId,
        reason: 'Upheld flag - account terminated',
      );
    }
  }
  
  // Integration with your Auth Provider
  static Future<void> flagUserForInappropriateContent({
    required String userId,
    required String flaggedBy,
    String details = 'Inappropriate content reported',
  }) async {
    await moveUserToReview(
      userId: userId,
      reason: 'flagged_by_user',
      flaggedBy: flaggedBy,
      details: details,
    );
  }

  static Future<void> upholdFlag({
    required String userId,
    required String upheldBy,
    required String eventId,
  }) async {
    try {
      final reviewDoc = await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .get();
      
      if (!reviewDoc.exists) {
        throw Exception('User not found in review');
      }
      
      final reviewData = reviewDoc.data()!;
      List<dynamic> reviewEvents = List.from(reviewData['reviewEvents'] ?? []);
      
      // Find the specific event
      int eventIndex = reviewEvents.indexWhere((event) => event['id'] == eventId);
      
      if (eventIndex == -1) {
        throw Exception('Review event not found');
      }
      
      // Update the event with upheld info
      reviewEvents[eventIndex]['upheldBy'] = upheldBy;
      reviewEvents[eventIndex]['upheld_timestamp'] = FieldValue.serverTimestamp();
      
      // Update the document
      await FirebaseFirestore.instance
          .collection(reviewCollection)
          .doc(userId)
          .update({
        'reviewEvents': reviewEvents,
      });
      
      print('Flag upheld for user $userId, event $eventId');
      
    } catch (e) {
      print('Error upholding flag: $e');
      rethrow;
    }
  }
  
  static Future<void> flagUserForMissedPayment({
    required String userId,
    required String paymentId,
    int consecutiveFailures = 1,
  }) async {
    await moveUserToReview(
      userId: userId,
      reason: 'missed_payment',
      details: 'Failed payment: $consecutiveFailures consecutive failure(s)',
      additionalData: {
        'paymentId': paymentId,
        'consecutiveFailures': consecutiveFailures,
      },
    );
  }
  
  static Future<void> flagUserForFakeProfile({
    required String userId,
    required String reportedBy,
    String details = 'Suspected fake profile',
  }) async {
    await moveUserToReview(
      userId: userId,
      reason: 'fake_profile',
      flaggedBy: reportedBy,
      details: details,
    );
  }
}