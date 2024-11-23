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
        .where('Gender', isEqualTo: 'Woman')
        .get();

    List<Map<String, dynamic>> usersWithPhotos = [];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      if (data['photo'] != null &&
          data['photo'].isNotEmpty &&
          Uri.tryParse(data['photo'])?.hasAbsolutePath == true) {
        usersWithPhotos.add(data);
      }
    }

    return usersWithPhotos;
  } catch (e) {
    print("Error fetching users: $e");
    return [];
  }
}

