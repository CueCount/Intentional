import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:flutter/foundation.dart';

class StreamChatService {
  static StreamChatClient? _client;
  static const String _apiKey = 'YOUR_STREAM_CHAT_API_KEY'; // Replace with your actual API key

  /// Get Stream Chat client instance (singleton)
  static StreamChatClient get client {
    _client ??= StreamChatClient(_apiKey);
    return _client!;
  }

  /// Initialize Stream Chat client with user
  Future<void> initializeUser(String userId, String userName, {String? userImage}) async {
    try {
      final user = User(
        id: userId,
        name: userName,
        image: userImage,
        extraData: {
          'last_active': DateTime.now().toIso8601String(),
        },
      );

      // Connect user to Stream Chat (you'll need to generate token on your backend)
      final token = await _generateUserToken(userId); // Implement this method
      await client.connectUser(user, token);
      
      print('✅ Stream Chat user connected: $userId');
    } catch (e) {
      print('❌ Error initializing Stream Chat user: $e');
      rethrow;
    }
  }

  /// Create a match channel between two users
  Future<Channel?> createMatchChannel(String user1Id, String user2Id) async {
    try {
      final channelId = _generateChannelId(user1Id, user2Id);
      
      final channel = client.channel(
        'messaging',
        id: channelId,
        extraData: {
          'type': 'match',
          'matched_users': [user1Id, user2Id],
          'matched_at': DateTime.now().toIso8601String(),
          'status': 'active',
        },
      );

      await channel.create();
      print('✅ Stream Chat channel created: $channelId');
      return channel;
    } catch (e) {
      print('❌ Error creating Stream Chat channel: $e');
      return null;
    }
  }

  /// Remove/hide a match channel
  Future<void> removeMatchChannel(String user1Id, String user2Id) async {
    try {
      final channelId = _generateChannelId(user1Id, user2Id);
      final channel = client.channel('messaging', id: channelId);
      
      // Hide channel for both users
      await channel.hide();
      
      print('✅ Stream Chat channel hidden: $channelId');
    } catch (e) {
      print('❌ Error removing Stream Chat channel: $e');
    }
  }

  /// Get a specific match channel
  Future<Channel?> getMatchChannel(String user1Id, String user2Id) async {
    try {
      final channelId = _generateChannelId(user1Id, user2Id);
      final channel = client.channel('messaging', id: channelId);
      
      // Watch channel to get latest state
      await channel.watch();
      return channel;
    } catch (e) {
      print('❌ Error getting Stream Chat channel: $e');
      return null;
    }
  }

  /// Get all match channels for a user
  Future<List<Channel>> getUserMatchChannels(String userId) async {
    try {
      final filter = Filter.and([
        Filter.equal('type', 'match'),
        Filter.in_('members', [userId]),
      ]);

      final channels = await client.queryChannels(filter: filter).first;
      return channels;
    } catch (e) {
      print('❌ Error getting user match channels: $e');
      return [];
    }
  }

  /// Send a message in a match channel
  Future<void> sendMessage(String user1Id, String user2Id, String messageText) async {
    try {
      final channel = await getMatchChannel(user1Id, user2Id);
      if (channel != null) {
        await channel.sendMessage(Message(text: messageText));
        print('✅ Message sent in channel: ${channel.id}');
      }
    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }

  /// Listen to messages in a match channel
  Stream<List<Message>> listenToMessages(String user1Id, String user2Id) {
    try {
      final channelId = _generateChannelId(user1Id, user2Id);
      final channel = client.channel('messaging', id: channelId);
      
      return channel.state!.messagesStream;
    } catch (e) {
      print('❌ Error listening to messages: $e');
      return Stream.empty();
    }
  }

  /// Mark messages as read
  Future<void> markChannelRead(String user1Id, String user2Id) async {
    try {
      final channel = await getMatchChannel(user1Id, user2Id);
      if (channel != null) {
        await channel.markRead();
      }
    } catch (e) {
      print('❌ Error marking channel as read: $e');
    }
  }

  /// Disconnect user from Stream Chat
  Future<void> disconnectUser() async {
    try {
      await client.disconnectUser();
      print('✅ Stream Chat user disconnected');
    } catch (e) {
      print('❌ Error disconnecting Stream Chat user: $e');
    }
  }

  /// Generate consistent channel ID from two user IDs
  String _generateChannelId(String user1Id, String user2Id) {
    List<String> ids = [user1Id, user2Id]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Generate user token (IMPLEMENT ON YOUR BACKEND)
  /// This is a placeholder - you need to implement token generation on your backend
  Future<String> _generateUserToken(String userId) async {
    // TODO: Replace with actual backend call to generate Stream Chat token
    // Your backend should call Stream Chat's server-side API to generate tokens
    
    // For development only - DO NOT use in production
    if (kDebugMode) {
      // This is a development token - replace with proper backend implementation
      return 'DEVELOPMENT_TOKEN_REPLACE_WITH_BACKEND_CALL';
    }
    
    throw UnimplementedError(
      'Token generation must be implemented on your backend. '
      'See Stream Chat documentation for server-side token generation.'
    );
  }

  /// Check if user is connected to Stream Chat
  bool get isUserConnected {
    return client.state.currentUser != null;
  }

  /// Get current connected user
  User? get currentUser {
    return client.state.currentUser;
  }
}