import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<dynamic> fetchUserField(String field) async {
  try {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      
      if (userDoc.exists && userDoc.data()!.containsKey(field)) {
        return userDoc[field];
      } else {
        print('Field "$field" not found in user document');
        return null;
      }
    }
  } catch (e) {
    print("Error loading field '$field': $e");
    return null;
  }
}

Future<List<Map<String, dynamic>>> fetchUsersWithPhotos() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('Gender', arrayContains: 'Woman')
        .where('photos', isNotEqualTo: null) 
        .get();

    List<Map<String, dynamic>> usersWithPhotos = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      // Validate 'photos' field
      if (data['photos'] != null &&
          data['photos'] is List &&
          (data['photos'] as List).isNotEmpty) {
        final validPhotos = (data['photos'] as List)
            .where((photo) => photo is String && Uri.tryParse(photo)?.isAbsolute == true)
            .toList();

        if (validPhotos.isNotEmpty) {
          usersWithPhotos.add({
            'UID': doc.id,
            'photo': validPhotos[0], // Pass the first valid photo URL
          });
          
        } else {
          print("Invalid or empty photo URLs for UID: ${doc.id}");
        }
      } else {
        //print("Missing or null 'photos' field for UID: ${doc.id}");
      }
    }

    /*print("Filtered users with first photo:");
    usersWithPhotos.forEach((user) {print("UID: ${user['UID']}, Photo: ${user['photo']}");});*/

    return usersWithPhotos;
  } catch (e) {
    print("Error fetching users: $e");
    return [];
  }
}
