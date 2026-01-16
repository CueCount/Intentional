import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../functions/chatService.dart';
import '../../providers/inputState.dart';

class DebugChatPage extends StatefulWidget {
  const DebugChatPage({Key? key}) : super(key: key);

  @override
  State<DebugChatPage> createState() => _DebugChatPageState();
}

class _DebugChatPageState extends State<DebugChatPage> {
  final TextEditingController _controller = TextEditingController();
  String _status = '';
  bool _isLoading = false;
  bool _isResetting = false;

  Future<void> _deleteChannel() async {
    final matchId = _controller.text.trim();
    
    if (matchId.isEmpty) {
      setState(() => _status = '❌ Please enter a match ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = '⏳ Deleting...';
    });

    try {
      final chatService = StreamChatService();
      
      // Make sure we're connected
      if (!chatService.isUserConnected()) {
        setState(() => _status = '❌ Not connected to Stream Chat. Open a chat first.');
        setState(() => _isLoading = false);
        return;
      }
      
      final channel = chatService.client.channel('messaging', id: matchId);
      
      // Initialize the channel first
      await channel.watch();
      
      // Then delete
      await channel.delete();
      
      setState(() {
        _status = '✅ Channel deleted: $matchId';
        _controller.clear();
      });
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resetLastRefresh() async {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      setState(() => _status = '❌ Not logged in');
      return;
    }

    setState(() {
      _isResetting = true;
      _status = '⏳ Resetting last_refresh...';
    });

    try {
      final tenHoursAgo = DateTime.now().subtract(const Duration(hours: 10)).toIso8601String();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'last_refresh': tenHoursAgo});
      
      final inputState = Provider.of<InputState>(context, listen: false);
      await inputState.saveInputsToLocalFromRemote(user.uid);
      
      setState(() => _status = '✅ last_refresh reset to 10 hours ago');
    } catch (e) {
      setState(() => _status = '❌ Error: $e');
    } finally {
      setState(() => _isResetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Tools'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chat deletion section
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Match ID / Channel ID',
                hintText: 'e.g. userId1-userId2',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _deleteChannel,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isLoading ? 'Deleting...' : 'Delete Channel',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // Reset refresh section
            ElevatedButton(
              onPressed: _isResetting ? null : _resetLastRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _isResetting ? 'Resetting...' : 'Reset last_refresh (-10 hours)',
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 24),
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _status,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}