import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/eventCard.dart';
import '../../widgets/navigation.dart';
import '../../providers/eventState.dart';
import '../../styles.dart';

class Events extends StatelessWidget {
  const Events({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final eventSync = Provider.of<EventSyncProvider>(context);
    final events = eventSync.activeEvents;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomStatusBar(),
            Expanded(
              child: events.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'No events yet',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      return EventCard(event: events[index]);
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }
}