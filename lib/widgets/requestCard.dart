import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../styles.dart';
import '../router/router.dart';

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onProfileTap;

  const RequestCard({
    super.key,
    required this.request,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final userData = request['userData'] as Map<String, dynamic>;
    final matchData = request['matchData'] as Map<String, dynamic>;
    String? imageUrl;
    if (userData['photos'] != null) {
      if (userData['photos'] is List && (userData['photos'] as List).isNotEmpty) {
        imageUrl = (userData['photos'] as List)[0];
      } else if (userData['photos'] is Map && (userData['photos'] as Map).containsKey(0)) {
        imageUrl = (userData['photos'] as Map)[0];
      } else if (userData['photos'] is String) {
        imageUrl = userData['photos'];
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [

            // Profile Picture
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.grey[400],
                      );
                    },
                  )
                : Icon(
                    Icons.person,
                    size: 30,
                    color: Colors.grey[400],
                  ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // User Info and Match Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Age
                  Text(
                    '${userData['nameFirst'] ?? 'Unknown'} ${_calculateAge(userData['birthDate'])}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Match Percentage (placeholder)
                  Text(
                    '95% Match',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: ColorPalette.peach,
                      fontSize: 24,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Time Left (calculated from createdAt)
                  Text(
                    _getTimeLeft(matchData['createdAt']),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                ],
              ),
            ),
            
            // Profile Icon
            GestureDetector(
              onTap: onProfileTap ?? () => _openUserProfile(context, request['requestedUserId']),
              child: const Icon(
                Icons.open_in_full,
                color: ColorPalette.peach,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper function to calculate age from birthDate
  int _calculateAge(dynamic birthDate) {
    if (birthDate == null) return 0;
    
    DateTime birth;
    if (birthDate is Timestamp) {
      birth = birthDate.toDate();
    } else if (birthDate is String) {
      birth = DateTime.parse(birthDate);
    } else {
      return 0;
    }
    
    DateTime now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  // Helper function to calculate time left from createdAt
  String _getTimeLeft(dynamic createdAt) {
    if (createdAt == null) return '1.5 Days Left';
    
    DateTime created;
    if (createdAt is Timestamp) {
      created = createdAt.toDate();
    } else if (createdAt is String) {
      created = DateTime.parse(createdAt);
    } else {
      return '1.5 Days Left';
    }
    
    // Calculate days since creation (assuming 3 day expiry)
    DateTime now = DateTime.now();
    Duration difference = now.difference(created);
    int daysElapsed = difference.inDays;
    double daysLeft = 3.0 - daysElapsed;
    
    if (daysLeft <= 0) {
      return 'Expired';
    } else if (daysLeft < 1) {
      int hoursLeft = (daysLeft * 24).round();
      return '$hoursLeft Hours Left';
    } else {
      return '${daysLeft.toStringAsFixed(1)} Days Left';
    }
  }

  void _openUserProfile(BuildContext context, String userId) {
    final userData = request['userData'] as Map<String, dynamic>;
    Navigator.pushNamed(
      context,
      AppRoutes.match,
      arguments: userData,
    );
  }
}