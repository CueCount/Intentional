import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/matchState.dart';

class GlobalErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;
  const GlobalErrorScreen({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    // Current route (set your route names when pushing/named routes)
    final routeName = ModalRoute.of(context)?.settings.name ?? '';

    // Only show verbose error text in debug
    var showDetails = false;
    assert(() { showDetails = true; return true; }());

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "An error occured. Try a quick refresh.",
                    textAlign: TextAlign.center,
                  ),
                  if (showDetails) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        details.exceptionAsString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Route-specific actions
                  _RouteActions(routeName: routeName),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteActions extends StatelessWidget {
  final String routeName;
  _RouteActions({required this.routeName});

  @override
  Widget build(BuildContext context) {
    final matchSync = context.read<MatchSyncProvider>();

    // Map your route names to labels and callbacks
    if (routeName == '/requestsSent') {
      return ElevatedButton.icon(
        onPressed: () => matchSync.forceRefresh(matchSync.currentUserId!),
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Sent Requests'),
      );
    }

    if (routeName == '/requestsReceived') {
      return ElevatedButton.icon(
        onPressed: () => matchSync.forceRefresh(matchSync.currentUserId!),
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Received Requests'),
      );
    }

    if (routeName == '/matches') {
      return ElevatedButton.icon(
        onPressed: () => matchSync.forceRefresh(matchSync.currentUserId!),
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh Matches'),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => matchSync.forceRefresh(matchSync.currentUserId!),
      icon: const Icon(Icons.refresh),
      label: const Text('Refresh'),
    );
  }
}
