import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/matchState.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/requestCard.dart';

class RequestSent extends StatefulWidget {
  final bool shouldUpdate;
  const RequestSent({Key? key, this.shouldUpdate = true}) : super(key: key);

  @override
  State<RequestSent> createState() => _RequestSentState();
}

class _RequestSentState extends State<RequestSent> {
  String? userId;
  List<Map<String, dynamic>> outgoingRequests = [];
  bool isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _ensureListenersActive();
      DebugPrefs.debugPrintAllStorage();
      _initialized = true;
    }
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
                    Text(
                      'Sent',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Consumer<MatchSyncProvider>(
                      builder: (context, matchSync, child) {
                        return Text(
                          'You\'ve used ${matchSync.pendingRequestsCount}/3 match Requests',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: ColorPalette.peach,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                    
                    Consumer<MatchSyncProvider>(
                      builder: (context, matchSync, child) {
                        final outgoingRequests = matchSync.sentRequests;
                        final isLoading = !matchSync.isListening && outgoingRequests.isEmpty;
                        
                        return Column(
                          children: [
                            if (isLoading)
                              const Center(
                                child: CircularProgressIndicator(
                                  color: ColorPalette.peach,
                                ),
                              ),
                            
                            if (!isLoading && outgoingRequests.isEmpty)
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
                                      'No requests sent yet',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            
                            if (!isLoading && outgoingRequests.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: outgoingRequests.length,
                                itemBuilder: (context, index) {
                                  final request = outgoingRequests[index];
                                  
                                  return RequestCard(
                                    request: request,
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