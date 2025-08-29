import 'package:flutter/material.dart';
import '../../functions/matchesService.dart';
import '../../functions/helpers/fetchData_service.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/requestCard.dart';

class RequestReceived extends StatefulWidget {
  final bool shouldUpdate;
  const RequestReceived({Key? key, this.shouldUpdate = true}) : super(key: key);
  
  @override
  State<RequestReceived> createState() => _RequestReceived();
}

class _RequestReceived extends State<RequestReceived> {
  List<Map<String, dynamic>> outgoingRequests = [];
  bool isLoading = true;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      print('🧠 shouldUpdate value for requests: ${widget.shouldUpdate}');
      loadOutgoingRequests();
      _initialized = true;
    }
  }

  Future<void> loadOutgoingRequests() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      List<Map<String, dynamic>> requests = await MatchesService().fetchReceivedRequests(
        fromFirebase: widget.shouldUpdate,
        forceFresh: widget.shouldUpdate,
      );
      
      if (mounted) {
        setState(() {
          outgoingRequests = requests;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading outgoing requests: $e');
      
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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
                    
                    // Loading state
                    if (isLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: ColorPalette.peach,
                        ),
                      ),
                    
                    // Empty state
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
                              'No requests received yet',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Requests list
                    if (!isLoading && outgoingRequests.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: outgoingRequests.length,
                        itemBuilder: (context, index) {
                          final request = outgoingRequests[index];
                          
                          return RequestCard(
                            request: request,
                            onProfileTap: () => _openUserProfile(request['requestedUserId']),
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

  // Navigate to user profile
  void _openUserProfile(String userId) {
    // TODO: Implement navigation to user profile page
    // Example: Navigator.pushNamed(context, '/profile', arguments: userId);
    print('Opening profile for user: $userId');
    
    // Placeholder - you can replace this with your actual profile navigation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile'),
        content: Text('Would open profile for user: $userId'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}