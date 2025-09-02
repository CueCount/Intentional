import 'package:flutter/material.dart';
import '../styles.dart';
import '../functions/matchesService.dart';
import '../router/router.dart';

enum RequestStatus { loading, available, pending }

class MatchCTA extends StatelessWidget {
  final RequestStatus status;
  final String targetUserId;
  
  const MatchCTA({
    Key? key,
    required this.status,
    required this.targetUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case RequestStatus.loading:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 20),
          child: const Center(child: CircularProgressIndicator()),
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
              // CTA Here
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
  }
}