import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles.dart';
import '../functions/matchesService.dart';
import '../providers/matchState.dart';
import '../router/router.dart';

enum RequestStatus { loading, available, pending, received, matched }

class MatchCTA extends StatelessWidget {
  final String targetUserId;
  
  const MatchCTA({
    Key? key,
    required this.targetUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<MatchSyncProvider>(
      builder: (context, matchSync, child) {
        // Determine status based on provider data
        final result = _getRequestStatus(matchSync, targetUserId);
        final status = result['status'] as RequestStatus;
        final matchId = result['matchId'] as String?;
        
        switch (status) {
          case RequestStatus.loading:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              child: const Center(child: CircularProgressIndicator()),
            );

          case RequestStatus.matched:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You\'re Matched!',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: ColorPalette.peach,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You and this person are exclusively connected. Start chatting to get to know each other better!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.chat);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: ColorPalette.peach.withOpacity(0.2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Go to Chat',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      if (matchId != null) {
                        final updateResult = await matchSync.updateMatchStatus(matchId, 'unmatched');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(updateResult['message'])),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Unmatch',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            );

          case RequestStatus.pending:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Pending',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: ColorPalette.peach,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have already sent a match request to this person. Wait for their response!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                ],
              ),
            );

          case RequestStatus.received:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'You Have a Match Request!',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: ColorPalette.peach,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This person wants to match with you - accept to start an exclusive connection or reject to pass.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            if (matchId != null) {
                              final result = await matchSync.updateMatchStatus(matchId, 'active');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'])),
                                );
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Accept',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          onPressed: () async {
                            if (matchId != null) {
                              final result = await matchSync.updateMatchStatus(matchId, 'rejected');
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(result['message'])),
                                );
                              }
                            }
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            'Reject',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

          case RequestStatus.available:
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Like What You See?',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: ColorPalette.peach,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Find out if it\'s mutual. If she accepts your request you will be exclusively matched with her. ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hopefully she gets to you before someone else does ;) ',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Check if user has exceeded limit
                  if (matchSync.hasExceededOutgoingLimit())
                    Text(
                      'You have reached your limit of 3 match requests. Wait for responses or view your sent requests.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.red,
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () async {
                        if (targetUserId.isNotEmpty) {
                          try {
                            final result = await MatchesService.sendMatchRequest(targetUserId);
                            if (context.mounted) {
                              if (result['success']) {
                                Navigator.pushNamed(context, AppRoutes.guideRequestSent);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${result['message']}')),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Send Match Request',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.favorite_outline, color: ColorPalette.peach, size: 24),
                        ],
                      ),
                    ),
                ],
              ),
            );
        }
      },
    );
  }
  
  // Helper method to determine request status from provider data
  Map<String, dynamic> _getRequestStatus(MatchSyncProvider matchSync, String targetUserId) {
    // If provider isn't listening yet, show loading
    if (!matchSync.isListening) {
      return {'status': RequestStatus.loading, 'matchId': null};
    }
    
    // Check if there's already a pending request to this user (sent by current user)
    final existingRequest = matchSync.sentRequests.any((request) =>
      request['requestedUserId'] == targetUserId &&
      request['matchData']['status'] == 'pending'
    );

    // Check if there's a pending request FROM this user TO current user (received by current user)
    final receivedRequest = matchSync.receivedRequests.firstWhere(
      (request) => 
        request['requesterUserId'] == targetUserId &&
        request['matchData']['status'] == 'pending',
      orElse: () => <String, dynamic>{},
    );

    final matched = matchSync.allMatches.firstWhere(
      (match) => (
        (match['requesterUserId'] == targetUserId && match['requestedUserId'] == matchSync.currentUserId) ||
        (match['requestedUserId'] == targetUserId && match['requesterUserId'] == matchSync.currentUserId)
      ) &&
      match['matchData']['status'] == 'active',
      orElse: () => <String, dynamic>{},
    );
    
    if (receivedRequest.isNotEmpty) {
      return {
        'status': RequestStatus.received, 
        'matchId': receivedRequest['matchData']['matchId']
      };
    } else if (existingRequest) {
      return {'status': RequestStatus.pending, 'matchId': null};
    } else if (matched.isNotEmpty) {
      return {
        'status': RequestStatus.matched, 
        'matchId': matched['matchData']['matchId']
      };
    } else {
      return {'status': RequestStatus.available, 'matchId': null};
    }
  }

}