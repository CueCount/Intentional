import 'package:flutter/material.dart';
import '../styles.dart';
import '../router/router.dart';

class EventCard extends StatelessWidget {
  final Map<String, dynamic> event;

  const EventCard({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.matchesEvent,
          arguments: event['eventId'],
        );
      },

      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Event Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event['eventName'] ?? 'Event',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatEventDate(event['eventTimestamp']),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: ColorPalette.peach.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              const Icon(
                Icons.arrow_forward_ios,
                color: ColorPalette.peach,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEventDate(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime date;
      if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return '';
      }
      return '${_monthName(date.month)} ${date.day}, ${date.year}';
    } catch (e) {
      return '';
    }
  }

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }

}