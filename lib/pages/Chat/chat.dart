import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../functions/chatService.dart';
import '../../providers/userState.dart';
import '../../providers/inputState.dart';

class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserName;
  final String? otherUserImage;
  
  const ChatScreen({
    Key? key,
    required this.matchId,
    required this.otherUserName,
    this.otherUserImage,
  }) : super(key: key);
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  Channel? _channel;
  bool _isLoading = true;
  String? _error;
  String? _otherUserDisplayName;
  String? _otherUserImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadChannel();
  }
  
  Future<void> _loadChannel() async {
    try {
      final chatService = StreamChatService();
      
      // Ensure user is connected to Stream Chat
      if (!chatService.isUserConnected()) {
        final inputState = Provider.of<InputState>(context, listen: false);
        final currentUserId = inputState.userId;
        
        if (currentUserId.isEmpty) {
          setState(() {
            _error = 'User not logged in';
            _isLoading = false;
          });
          return;
        }
        
        // Get current user's data for connection
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('inputs_$currentUserId');
        final userData = userJson != null ? jsonDecode(userJson) : {};
        
        await chatService.connectUser(
          userId: currentUserId,
          userName: userData['nameFirst'] ?? 'User',
          userImage: userData['photos']?[0],
        );
      }
      
      // Get channel using match ID
      final channel = await chatService.getChannelByMatchId(widget.matchId);
      
      if (channel == null) {
        setState(() {
          _error = 'Chat not found';
          _isLoading = false;
        });
        return;
      }
      
      // Extract the other user's ID from channel members
      final currentUserId = chatService.client.state.currentUser?.id;
      final members = channel.state?.members ?? [];
      final otherMember = members.where((m) => m.userId != currentUserId).firstOrNull;
      
      String? displayName = otherMember?.user?.name;
      String? imageUrl = otherMember?.user?.image;
      
      // If Stream doesn't have the name (or it's just the userId), fetch from cache/Firebase
      if ((displayName == null || displayName == otherMember?.userId) && otherMember?.userId != null) {
        final userSync = Provider.of<UserSyncProvider>(context, listen: false);
        
        // Try cache first
        Map<String, dynamic>? userData = await userSync.getUserFromCache(
          otherMember!.userId!, 
          currentUserId!,
        );
        
        // If not in cache, fetch from Firebase
        if (userData == null) {
          final inputState = Provider.of<InputState>(context, listen: false);
          userData = await userSync.getUserByID(
            otherMember.userId!, 
            currentUserId,
            inputState,
          );
        }
        
        displayName = userData?['nameFirst'] ?? widget.otherUserName;
        imageUrl = imageUrl ?? userData?['photoURL'];
      }
      
      setState(() {
        _channel = channel;
        _otherUserDisplayName = displayName ?? widget.otherUserName;
        _otherUserImageUrl = imageUrl ?? widget.otherUserImage;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _error = 'Error loading chat: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _otherUserDisplayName ?? widget.otherUserName,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_error != null || _channel == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _otherUserDisplayName ?? widget.otherUserName,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error ?? 'Unable to load chat'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadChannel,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return StreamChat(
      client: StreamChatService().client,
      child: StreamChannel(
        channel: _channel!,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                if (_otherUserImageUrl != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(_otherUserImageUrl!),
                    radius: 16,
                  ),
                SizedBox(width: 8),
                Text(
                  _otherUserDisplayName ?? widget.otherUserName,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamMessageListView(
                  messageBuilder: (context, details, messages, defaultMessage) {
                    // Custom styling for match notification
                    if (details.message.extraData['isMatchNotification'] == true) {
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.pink[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              details.message.text ?? '',
                              style: TextStyle(
                                color: Colors.pink[700],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    
                    return defaultMessage.copyWith(
                      showUsername: false,
                      showTimestamp: true,
                      showSendingIndicator: true,
                    );
                  },
                ),
              ),
              StreamMessageInput(
                showCommandsButton: false,
                sendButtonLocation: SendButtonLocation.inside,
                idleSendButton: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                activeSendButton: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}