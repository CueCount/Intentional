import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'photo_service.dart';

class SaveDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static String? _tempUserId;
  
  /* = = = = = = = = = 
  Save to Firebase 
  = = = = = = = = = */

  // This might be able to be handled by an existing function in input Provider, or Auth Provider, if not will move
  Future<void> saveToFirebaseOnRegister(BuildContext context, Map<String, dynamic> inputValues) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      String documentId;
      
      if (currentUser != null) {
        // User is authenticated - use their UID
        documentId = currentUser.uid;
        print('✅ Using authenticated user ID: $documentId');
        
        // If we had a temp document, we should transfer its data
        if (_tempUserId != null && _tempUserId != documentId) {
          await _transferTempDataToAuthUser(_tempUserId!, documentId, inputValues);
          _tempUserId = null; // Clear temp ID
        }
      } else {
        // No authenticated user - create temp document
        if (_tempUserId == null) {
          DocumentReference newUserRef = await _firestore.collection('users').add({
            'created_at': FieldValue.serverTimestamp(),
            'is_temp': true,
            ...inputValues,
          });
          _tempUserId = newUserRef.id;
          print('📝 Created new temp document with ID: $_tempUserId');
        }
        documentId = _tempUserId!;
      }

      // Upload photos
      final photoUrls = await PhotoService.uploadAllPhotos(context, documentId);
      
      // Prepare final data
      Map<String, dynamic> finalData = Map.from(inputValues);
      finalData.remove('photoInputs');
      finalData['photos'] = photoUrls;
      finalData['last_updated'] = FieldValue.serverTimestamp();
      
      if (currentUser != null) {
        finalData['userId'] = currentUser.uid;
        finalData['email'] = currentUser.email;
        finalData.remove('is_temp'); // Remove temp flag for authenticated users
      }

      // Save to Firestore
      await _firestore.collection('users').doc(documentId).set(
        finalData,
        SetOptions(merge: true)
      );
      
      print('✅ Updated document $documentId with: ${finalData.keys.toList()}');
    } catch (e) {
      print('❌ Error submitting to Firestore: $e');
      throw e;
    }
  }
  
  // This should be handled by the merge function in Input Provider
  Future<void> _transferTempDataToAuthUser(String tempId, String authUserId, Map<String, dynamic> currentData) async {
    try {
      // Get temp document data
      DocumentSnapshot tempDoc = await _firestore.collection('users').doc(tempId).get();
      
      if (tempDoc.exists) {
        Map<String, dynamic> tempData = tempDoc.data() as Map<String, dynamic>;
        
        // Merge temp data with current data (current data takes precedence)
        Map<String, dynamic> mergedData = {
          ...tempData,
          ...currentData,
          'userId': authUserId,
          'transferred_from_temp': tempId,
          'is_temp': FieldValue.delete(), // Remove temp flag
        };
        
        // Save merged data to authenticated user document
        await _firestore.collection('users').doc(authUserId).set(
          mergedData,
          SetOptions(merge: true)
        );
        
        // Delete temp document
        await _firestore.collection('users').doc(tempId).delete();
        
        print('✅ Transferred data from temp document $tempId to authenticated user $authUserId');
      }
    } catch (e) {
      print('❌ Error transferring temp data: $e');
      // Continue anyway - don't let this block the main flow
    }
  }

  // only photos uses this. Consoldate and move to Input Provider
  static Future<void> saveToFirestore({
    required Map<String, dynamic> data, 
    required String userId
  }) async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Prepare data for Firestore (exclude photos and other non-serializable data)
      Map<String, dynamic> firestoreData = Map.from(data);
      firestoreData['last_updated'] = FieldValue.serverTimestamp();
      firestoreData['userId'] = userId;
      
      // Save to Firestore with merge
      await firestore.collection('users').doc(userId).set(
        firestoreData,
        SetOptions(merge: true)
      );
      
      print('✅ saveToFirestore: Success for user $userId');
      
    } catch (e) {
      print('❌ saveToFirestore: Failed - $e');
      throw e;
    }
  }
  
  
}