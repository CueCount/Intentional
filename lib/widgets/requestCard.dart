import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/matchState.dart';
import '../styles.dart';
import '../router/router.dart';

class RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final Map<String, dynamic> userData;
  final VoidCallback? onProfileTap;

  RequestCard({
    super.key,
    required this.request,
    required this.userData,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {

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
                    '${userData['nameFirst'] ?? 'Unknown'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Match Percentage (placeholder)
                  Text(
                    'Match ${userData['compatibility']?['percentage']?.toInt() ?? 0}%',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: ColorPalette.peach,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Time Left (calculated from createdAt)
                  Text(
                    _getTimeLeft(request['createdAt'], context),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                ],
              ),
            ),
            
            // Profile Icon
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.match,
                  arguments: userData,
                );
              },
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

  String _getTimeLeft(dynamic createdAt, BuildContext context) {
    if (createdAt == null) return 'null';
    
    DateTime created;
    if (createdAt is Timestamp) {
      created = createdAt.toDate();
    } else if (createdAt is String) {
      created = DateTime.parse(createdAt);
    } else {
      return 'null';
    }
    
    // Calculate days since creation (assuming 1 day expiry)
    DateTime now = DateTime.now();
    Duration difference = now.difference(created);
    int daysElapsed = difference.inDays;
    double daysLeft = 1.0 - daysElapsed;
    
    if (daysLeft <= 0) {
      final matchProvider = Provider.of<MatchSyncProvider>(context, listen: false);
      final matchId = request['id'] ?? request['matchId'];
      
      if (matchId != null) {
        matchProvider.ignore(matchId);
      }
      return 'Expired';
    } else if (daysLeft < 1) {
      int hoursLeft = (daysLeft * 24).round();
      return '$hoursLeft Hours Left';
    } else {
      return '${daysLeft.toStringAsFixed(1)} Days Left';
    }
  }

}