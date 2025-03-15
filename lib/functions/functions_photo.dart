import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoUploadHelper {
  final BuildContext context;
  final Function(bool) onLoadingChanged;
  final Function(List<String>) onPhotosUpdated;
  final List<String> photoUrls;

  PhotoUploadHelper({
    required this.context,
    required this.onLoadingChanged,
    required this.onPhotosUpdated,
    required this.photoUrls,
  });

  Future<void> pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      onLoadingChanged(true);
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('user_photos')
          .child(userId)
          .child(fileName);

      // Upload the image
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await storageRef.putData(bytes);
        await Future.delayed(Duration(seconds: 2));
      } else {
        await storageRef.putFile(File(image.path));
        await Future.delayed(Duration(seconds: 2));
      }

      // Get the download URL with retry logic
      String downloadUrl = '';
      int attempts = 0;
      while (attempts < 3) {
        try {
          downloadUrl = await storageRef.getDownloadURL();
          print('Download URL obtained: $downloadUrl');
          break;
        } catch (e) {
          attempts++;
          print('Attempt $attempts to get download URL failed: $e');
          if (attempts == 3) throw e;
          await Future.delayed(Duration(seconds: 1));
        }
      }

      // Fetch current photos from Firestore first
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      List<String> currentPhotos = [];
      if (userDoc.exists && userDoc.data()!.containsKey('photos')) {
        currentPhotos = List<String>.from(userDoc.data()!['photos'] ?? []);
      }

      // Add new photo URL
      List<String> updatedPhotos = [...currentPhotos, downloadUrl];

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photos': updatedPhotos,
      });

      print('Firestore updated, notifying UI with updated photos: $updatedPhotos');
      onPhotosUpdated(updatedPhotos);
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    } finally {
      onLoadingChanged(false);
    }
  }

  static Future<List<String>> fetchExistingPhotos({
    String? targetUid,
    dynamic selection = "all",
  }) async {
    try {
      // Use the provided UID, or default to the current user's UID
      final userId = targetUid ?? FirebaseAuth.instance.currentUser!.uid;
      print('Fetching photos for user: $userId');

      // Fetch the user's document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Check if photos exist in the user's document
      if (userDoc.exists && userDoc.data()!.containsKey('photos')) {
        final photos = List<String>.from(userDoc.data()!['photos'] ?? []);
        
        // Return based on the selection parameter
        if (selection == "all") {
          return photos; // Return all photos
        } else if (selection == "last_uploaded") {
          return photos.isNotEmpty ? [photos.last] : [];
        } else if (selection is int && selection >= 0 && selection < photos.length) {
          return [photos[selection]]; 
        } else {
          print('Invalid selection parameter: $selection');
          return [];
        }
      } else {
        print('No photos found in document');
        return [];
      }
    } catch (e) {
      print('Error fetching photos: $e');
      throw Exception('Error loading photos: $e');
    }
  }
  
  Future<void> removePhoto(int index) async {
    try {
      if (index < 0 || index >= photoUrls.length) {
        print('Invalid index: $index, photoUrls length: ${photoUrls.length}');
        return;
      }
      final url = photoUrls[index];
      final userId = FirebaseAuth.instance.currentUser!.uid;
      List<String> updatedPhotos = List<String>.from(photoUrls);
      updatedPhotos.removeAt(index);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photos': updatedPhotos,
      });
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      print('Photo removed, notifying UI with updated photos');
      onPhotosUpdated(updatedPhotos);
    } catch (e) {
      print('Error removing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing photo: $e')),
      );
    }
  }
}