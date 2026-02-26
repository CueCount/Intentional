import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles.dart';
import '../providers/matchState.dart';
import '../providers/inputState.dart';
import '../router/router.dart';

enum RequestStatus { loading, available, pending, received, matched }

class MatchCTA extends StatelessWidget {
  final String targetUserId;
  final Map<String, dynamic> matchInstance;
  
  const MatchCTA({
    Key? key,
    required this.targetUserId,
    required this.matchInstance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final matchSync = Provider.of<MatchSyncProvider>(context);
    final inputState = Provider.of<InputState>(context, listen: false);
    final currentSessionId = inputState.userId;

    final matchInstanceId = matchInstance['matchInstanceId'] as String?;
    final instanceStatus = matchInstance['status'] as String? ?? 'active';
    final log = List<Map<String, dynamic>>.from(matchInstance['log'] ?? []);
    final lastLogBy = log.isNotEmpty ? log.last['by'] : null;

    // Derive the display status from the match_instance data
    RequestStatus status;
    if (instanceStatus == 'matched') {
      status = RequestStatus.matched;
    } else if (instanceStatus == 'chat_requested') {
      status = (lastLogBy == currentSessionId)
          ? RequestStatus.pending
          : RequestStatus.received;
    } else {
      status = RequestStatus.available;
    }

    // No Consumer wrapper needed anymore
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
            color: ColorPalette.peachLite,
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
                'You and this person are exclusively connected. Start chatting!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.chat,
                    arguments: {
                      'matchInstanceId': matchInstanceId,
                      'otherUserName': targetUserId,
                    },
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  overlayColor: Colors.transparent,
                ),
                child: Text(
                  'Go to Chat',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: ColorPalette.peach,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  if (matchInstanceId != null) {
                    final updateResult = await matchSync.unmatch(matchInstanceId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(updateResult['Unmatched — no hard feelings, just new beginnings ✨'])),
                      );
                    }
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  overlayColor: Colors.transparent,
                ),
                child: Text(
                  'Unmatch',
                  style: AppTextStyles.headingMedium.copyWith(
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
            color: ColorPalette.peachLite,
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
                'Someone’s interested 👀 Accept to spark an exclusive connection—or swipe them away.',
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
                        if (matchInstanceId != null) {
                          final result = await matchSync.acceptMatch(matchInstanceId, currentSessionId, targetUserId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['It’s a match! 💫'])),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: ColorPalette.greenLite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Accept',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: ColorPalette.green,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        if (matchInstanceId != null) {
                          final result = await matchSync.rejectMatch(matchInstanceId, targetUserId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['You kept it moving 👋'])),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: ColorPalette.violetLite,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Reject',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: ColorPalette.violet,
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
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: ColorPalette.peachLite,
            borderRadius: BorderRadius.circular(20),
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
                'Once your request is accepted, you\'ll both be matched exclusively.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  if (targetUserId.isNotEmpty) {
                    try {
                      final result = await matchSync.chatRequest(matchInstanceId!);
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
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  overlayColor: Colors.transparent,
                ),
                child: Row(
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
              const SizedBox(height: 14), 

              TextButton(
                onPressed: () async {
                  if (targetUserId.isNotEmpty) {
                    try {
                      await inputState.saveByAddingToArrayToRemoteThenLocal('ignoreList', targetUserId);
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User filtered from future matches')),
                        );
                        Navigator.pop(context);
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
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  overlayColor: Colors.transparent,
                ),
                child: Row(
                  children: [
                    Text(
                      'Not My Type Filter Out in Future Refreshes',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.person_off, color: ColorPalette.peach, size: 24),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}