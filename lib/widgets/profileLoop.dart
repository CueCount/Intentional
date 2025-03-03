import 'package:flutter/material.dart';
import '../functions/fetchData.dart';

class ProfileGrid extends StatelessWidget {
  const ProfileGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120, 
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchUsersWithPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No profiles found.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final users = snapshot.data!;
          final displayedUsers = users.take(10).toList();
          final totalProfiles = users.length;

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5, // Show 5 items per row
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedUsers.length + 1, // Add 1 for total count
            itemBuilder: (context, index) {
              if (index < displayedUsers.length) {
                final user = displayedUsers[index];
                return CircleAvatar(
                  radius: 30,
                  backgroundImage: user['photo'] != null ? NetworkImage(user['photo']) : null,
                  onBackgroundImageError: (error, stackTrace) {
                    print('Error loading image: $error');
                  },
                  backgroundColor: Colors.grey[200],
                  child: user['photo'] == null || user['photo'].isEmpty
                      ? const Icon(Icons.broken_image, color: Colors.grey)
                      : null, // Remove fallback icon if the image is loadin
                );
              } else {
                return CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey[200],
                  child: Text(
                    '$totalProfiles+',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
