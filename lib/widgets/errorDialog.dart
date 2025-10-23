import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inputState.dart';
import '../../providers/userState.dart';
import '../../providers/matchState.dart';

class RefreshDataWidget extends StatefulWidget {
  final String? errorContext;
  final VoidCallback? onComplete;

  const RefreshDataWidget({
    Key? key,
    this.errorContext,
    this.onComplete,
  }) : super(key: key);

  @override
  State<RefreshDataWidget> createState() => _RefreshDataWidgetState();
}

class _RefreshDataWidgetState extends State<RefreshDataWidget> {
  bool _isRefreshing = false;
  String? _errorMessage;

  Future<void> _performFullRefresh() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });

    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      final userProvider = Provider.of<UserSyncProvider>(context, listen: false);
      final matchProvider = Provider.of<MatchSyncProvider>(context, listen: false);
      
      final currentUserId = inputState.userId;
      
      if (currentUserId.isEmpty) {
        throw Exception('No user ID found. Please login again.');
      }

      // Step 1: Sync Inputs
      await inputState.syncInputs(
        fromId: currentUserId,
        toId: currentUserId,
      );

      // Step 2: Load Users (this triggers checkAndUpdateMissingCompatibility internally)
      await userProvider.loadUsers(inputState);

      // Step 3: Explicitly check compatibility
      await inputState.checkAndUpdateMissingCompatibility(inputState);

      // Step 4: Force Refresh Matches
      await matchProvider.forceRefresh(currentUserId);

      // Success - close dialog and call callback
      if (mounted) {
        Navigator.pop(context, true);
        widget.onComplete?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      setState(() {
        _isRefreshing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Auto-start refresh when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _performFullRefresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Refreshing Data'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.errorContext != null && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.errorContext!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          
          if (_errorMessage != null) ...[
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Please wait while we sync your data...'),
          ],
        ],
      ),
      actions: [
        if (_errorMessage != null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _performFullRefresh,
            child: const Text('Retry'),
          ),
        ],
      ],
    );
  }
}