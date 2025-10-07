import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/inputState.dart';
import '../functions/userReviewService.dart';

class FlagUserWidget extends StatefulWidget {
  final String targetUserId;
  final String? chatId;

  const FlagUserWidget({
    Key? key,
    required this.targetUserId,
    this.chatId,
  }) : super(key: key);

  @override
  State<FlagUserWidget> createState() => _FlagUserWidgetState();
}

class _FlagUserWidgetState extends State<FlagUserWidget> {
  final ReviewCaseService _caseService = ReviewCaseService();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  bool _isSubmitting = false;

  final List<String> _flagReasons = [
    'Inappropriate content',
    'Fake profile',
    'Harassment',
    'Spam',
    'Underage user',
    'Other',
  ];

  Future<void> _submitFlag() async {
    if (_selectedReason == null) return;

    setState(() => _isSubmitting = true);

    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      final currentUserId = inputState.userId;
      
      final reason = _selectedReason == 'Other'
          ? _reasonController.text.trim()
          : _selectedReason!;

      await _caseService.createFlaggedCase(
        userId: widget.targetUserId,
        flaggedByUserId: currentUserId,
        reason: reason,
        chatId: widget.chatId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User has been reported. Thank you for helping keep our community safe.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reporting user: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Report User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why are you reporting this user?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            ...(_flagReasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: _selectedReason,
              onChanged: (value) {
                setState(() {
                  _selectedReason = value;
                });
              },
            ))),
            if (_selectedReason == 'Other') ...[
              const SizedBox(height: 16),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Please describe the issue...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting || _selectedReason == null
              ? null
              : _submitFlag,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit Report'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}