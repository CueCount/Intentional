import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _tempUserId;

  Future<void> handleSubmit(Map<String, dynamic> inputValues) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      String documentId;

      if (currentUser != null) {
        // User is logged in, use their auth ID
        documentId = currentUser.uid;
      } else {
        // User not logged in, use/create temp ID
        if (_tempUserId == null) {
          DocumentReference newUserRef = await _firestore.collection('users').add({
            'created_at': FieldValue.serverTimestamp(),
            ...inputValues,
          });
          _tempUserId = newUserRef.id;
          print('Created new temp document with ID: $_tempUserId');
          documentId = _tempUserId!;
        } else {
          documentId = _tempUserId!;
        }
      }

      // Submit data to appropriate document
      await _firestore.collection('users').doc(documentId).set(
        inputValues,
        SetOptions(merge: true)
      );
      
      print('Updated document $documentId with: $inputValues');

    } catch (e) {
      print('Error submitting to Firestore: $e');
      throw e;
    }
  }

  // Use this when user registers/logs in
  Future<void> associateWithAuthUser(String authUserId) async {
    if (_tempUserId != null) {
      try {
        // Copy temp data to authenticated user document
        DocumentSnapshot tempDoc = await _firestore
            .collection('users')
            .doc(_tempUserId)
            .get();
            
        await _firestore
            .collection('users')
            .doc(authUserId)
            .set(tempDoc.data() as Map<String, dynamic>);

        // Delete temp document
        await _firestore.collection('users').doc(_tempUserId).delete();
        
        _tempUserId = null; // Clear temp ID since we're now using auth ID
        print('Associated temp data with auth user: $authUserId');
      } catch (e) {
        print('Error associating with auth user: $e');
        throw e;
      }
    }
  }

  /// Fetch users based on optional filters.
  /// Default: Only users with at least one photo.
  Future<List<Map<String, dynamic>>> fetchUsers({
    bool onlyWithPhotos = false,
    List<String>? userIds,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // Filter users by a specific list of user IDs if provided
      if (userIds != null && userIds.isNotEmpty) {
        query = query.where(FieldPath.documentId, whereIn: userIds);
      }

      // Default behavior: Only fetch users with at least one photo
      if (onlyWithPhotos) {
        query = query.where('photos' != null);
      }

      QuerySnapshot snapshot = await query.get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              })
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

}