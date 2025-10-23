import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'apis/streamChat.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StreamChatService {
  static final StreamChatService _instance = StreamChatService._internal();
  factory StreamChatService() => _instance;
  StreamChatService._internal();
  StreamChatClient? _client;
  
  /* = = = = = = = = = = = 
  Getters 
   = = = = = = = = = = = */

  StreamChatClient get client {
    _client ??= StreamChatClient(
      StreamConfig.getApiKey(),
      logLevel: Level.INFO,
    );
    return _client!;
  }
  
  /* = = = = = = = = = = = 
  Connect user to Stream Chat 
   = = = = = = = = = = = */

  Future<void> connectUser({
    required String userId,
    required String userName,
    String? userImage,
  }) async {
    try {
      final token = await _getStreamToken(userId);
      
      await client.connectUser(
        User(
          id: userId,
          name: userName,
          extraData: {
            'lastActive': DateTime.now(),
          },
        ),
        token,
      );
      
      print('User $userId connected to Stream Chat');
    } catch (e) {
      print('Error connecting user to Stream Chat: $e');
      throw e;
    }
  }
  
  /* = = = = = = = = = = = 
  Disconnect current user
   = = = = = = = = = = = */

  Future<void> disconnectUser() async {
    try {
      await client.disconnectUser();
      print('User disconnected from Stream Chat');
    } catch (e) {
      print('Error disconnecting user: $e');
    }
  }
  
  /* = = = = = = = = = = = 
  Create a new chat channel for a match
   = = = = = = = = = = = */

  Future<Channel> createMatchChannel({
    required String matchId,
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      // Use matchId as the channel ID for consistency
      final channel = client.channel(
        'messaging',
        id: matchId, 
        extraData: {
          'matchId': matchId,
          'members': [currentUserId, otherUserId],
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Create and watch the channel
      await channel.create();
      await channel.watch();
      
      // Send initial match message (optional)
      await channel.sendMessage(
        Message(
          text: "You matched! Start a conversation 💕",
          type: 'system',
          extraData: {'isMatchNotification': true},
        ),
      );
      
      print('Chat channel created for match: $matchId');
      return channel;
    } catch (e) {
      print('Error creating match channel: $e');
      throw e;
    }
  }
  
  /* = = = = = = = = = = = 
  Get existing channel by match ID
   = = = = = = = = = = = */

  Future<Channel?> getChannelByMatchId(String matchId) async {
    try {
      final channel = client.channel(
        'messaging',
        id: matchId,
      );
      
      // Try to query the channel
      await channel.query();
      
      // Check if channel exists - updated syntax for newer SDK
      if (channel.state != null && channel.cid != null) {
        await channel.watch();
        return channel;
      }
      
      return null;
    } catch (e) {
      print('Error getting channel for match $matchId: $e');
      return null;
    }
  }
      
  /* = = = = = = = = = = = 
  Send a message to a match
   = = = = = = = = = = = */

  Future<void> sendMessage({
    required String matchId,
    required String text,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final channel = await getChannelByMatchId(matchId);
      if (channel != null) {
        await channel.sendMessage(
          Message(
            text: text,
            extraData: extraData ?? {},
          ),
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }
  
  /* = = = = = = = = = = = 
  Check if user is connected
   = = = = = = = = = = = */

  bool isUserConnected() {
    return client.state.currentUser != null;
  }
  
  /* = = = = = = = = = = = 
  Get stream token from your backend
   = = = = = = = = = = = */

  Future<String> _getStreamToken(String userId) async {
    try {
      // For development, just use the dev token directly
      return client.devToken(userId).rawValue;
    } catch (e) {
      print('Error getting Stream token: $e');
      throw e;
    }
  }

}