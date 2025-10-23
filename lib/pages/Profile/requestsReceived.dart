import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/matchState.dart';
import '../../providers/userState.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/requestCard.dart';

class RequestReceived extends StatefulWidget {
  final bool shouldUpdate;
  const RequestReceived({Key? key, this.shouldUpdate = true}) : super(key: key);
  
  @override
  State<RequestReceived> createState() => _RequestReceivedState();
}

class _RequestReceivedState extends State<RequestReceived> {
  bool _initialized = false;
  Map<String, Map<String, dynamic>> _userDataCache = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _ensureListenersActive();
      _initialized = true;
    }
    _loadUserData(); // Load user data whenever dependencies change
  }

  Future<void> _ensureListenersActive() async {
    final matchSync = Provider.of<MatchSyncProvider>(context, listen: false);
    final inputState = Provider.of<InputState>(context, listen: false);

    if (!matchSync.isListening) {
      final userId = inputState.userId;
      if (userId != null && userId.isNotEmpty) {
        await matchSync.startListening(userId);
      }
    }
  }

  Future<void> _loadUserData() async {
    final matchSync = Provider.of<MatchSyncProvider>(context, listen: false);
    final userProvider = Provider.of<UserSyncProvider>(context, listen: false);
    final inputState = Provider.of<InputState>(context, listen: false);
    
    final receivedRequests = matchSync.receivedRequests;
    
    for (var request in receivedRequests) {
      final requesterUserId = request['requesterUserId']; // Get requester, not requested
      if (!_userDataCache.containsKey(requesterUserId)) {
        // Try to get from cache first
        final userData = await userProvider.getUserFromCache(requesterUserId, inputState.userId);
        
        if (userData != null) {
          setState(() {
            _userDataCache[requesterUserId] = userData;
          });
        } else {
          // Fetch from Firebase if not in cache
          final firebaseData = await userProvider.getUserByID(requesterUserId, inputState.userId);
          if (firebaseData != null) {
            setState(() {
              _userDataCache[requesterUserId] = firebaseData;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Header
                    Text(
                      'Received',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accepting will exclusively match you. Requests will stay here until expiration.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: ColorPalette.peach,
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    Consumer<MatchSyncProvider>(
                      builder: (context, matchSync, child) {
                        final receivedRequests = matchSync.receivedRequests;
                        final isLoading = !matchSync.isListening && receivedRequests.isEmpty;
                        
                        return Column(
                          children: [
                            // Loading state
                            if (isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: ColorPalette.peach,
                                ),
                              ),
                            
                            // Empty state
                            if (!isLoading && receivedRequests.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.send_outlined,
                                      size: 80,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No requests received yet',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            // Requests list
                            if (!isLoading && receivedRequests.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: receivedRequests.length,
                                itemBuilder: (context, index) {
                                  final request = receivedRequests[index];
                                  final requesterUserId = request['requesterUserId'];
                                  final userData = _userDataCache[requesterUserId];
                                  
                                  if (userData == null) {
                                    return const SizedBox.shrink(); // Skip if no user data yet
                                  }
                                  
                                  return RequestCard(
                                    request: request,
                                    userData: userData, // Pass userData separately
                                  );
                                },
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}