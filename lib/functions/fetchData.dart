import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
        .get();

    print("Fetched ${querySnapshot.docs.length} users from Firestore.");

    if (querySnapshot.docs.isEmpty) {
      print("❌ No users found in Firestore. Check if 'Gender' is stored correctly.");
    }

    List<Map<String, dynamic>> usersWithPhotos = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();

      if (data.containsKey('photos') && data['photos'] is List && data['photos'].isNotEmpty) {
        print("✅ Photos found for user ${doc.id}: ${data['photos']}");

        // Directly use the first URL from Firestore
        String freshUrl = data['photos'][0]; 

        usersWithPhotos.add({
          'UID': doc.id,
          'photo': freshUrl,  // Use stored URL directly
        });
      } else {
        print("⚠ No valid photos for ${doc.id}");
      }
    }

    print("✅ Successfully fetched ${usersWithPhotos.length} users with photos.");
    return usersWithPhotos;
  } catch (e) {
    print("❌ Error fetching users: $e");
    return [];
  }
}
