import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import '../../functions/chatService.dart';

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
  
  @override
  void initState() {
    super.initState();
    _loadChannel();
  }
  
  Future<void> _loadChannel() async {
    try {
      // Get channel using match ID
      final channel = await StreamChatService().getChannelByMatchId(widget.matchId);
      
      if (channel == null) {
        setState(() {
          _error = 'Chat not found';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _channel = channel;
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
          title: Text(widget.otherUserName),
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
          title: Text(widget.otherUserName),
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
                if (widget.otherUserImage != null)
                  CircleAvatar(
                    backgroundImage: NetworkImage(widget.otherUserImage!),
                    radius: 16,
                  ),
                SizedBox(width: 8),
                Text(widget.otherUserName),
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