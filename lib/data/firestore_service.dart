import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import '../functions/photo_service.dart';
import 'package:flutter/widgets.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _tempUserId;

  /*Future<void> handleSubmit(BuildContext context, Map<String, dynamic> inputValues) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      String documentId;
      if (currentUser != null) {
        documentId = currentUser.uid;
      } else {
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
      final photoUrls = await PhotoService.uploadAllPhotos(context, documentId);
      inputValues.remove('photoInputs');
      inputValues = {
        ...inputValues,
        'photos': photoUrls,
      };
      await _firestore.collection('users').doc(documentId).set(
        inputValues,
        SetOptions(merge: true)
      );
      print('Updated document $documentId with: $inputValues');
    } catch (e) {
      print('Error submitting to Firestore: $e');
      throw e;
    }
  }*/

  /// Fetch users based on optional filters.
  /*Future<List<Map<String, dynamic>>> fetchUsers({
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
  }*/
}