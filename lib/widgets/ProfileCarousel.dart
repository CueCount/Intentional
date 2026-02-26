import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; 
import 'dart:async';
import '../providers/inputState.dart';
import '../router/router.dart';
import '../functions/miscService.dart';
import '../../widgets/pill.dart'; 
import '../styles.dart';
import '../widgets/errorDialog.dart';
import '../widgets/feedback.dart';
import '../providers/userState.dart';

class ProfileCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> matchInstances;
  final bool isLoading;

  const ProfileCarousel({
    Key? key,
    required this.matchInstances,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ProfileCarousel> createState() => _ProfileCarouselState();
}

class _ProfileCarouselState extends State<ProfileCarousel> {
  final Map<String, Map<String, dynamic>> _userCache = {};

  Timer? _countdownTimer;
  bool _canRefresh = true;
  String _countdownText = '';
  bool _isRefreshing = false;

  String? _getOtherUserId(Map<String, dynamic> matchInstance) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final userIds = List<String>.from(matchInstance['userIds'] ?? []);
    return userIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  Future<Map<String, dynamic>?> _loadUser(String otherUserId) async {
    if (_userCache.containsKey(otherUserId)) {return _userCache[otherUserId];}
    final userSync = Provider.of<UserSyncProvider>(context, listen: false);
    Map<String, dynamic>? userData = await userSync.getUser(otherUserId,);
    if (userData != null) {_userCache[otherUserId] = userData;}
    return userData;
  }

  Future<void> _checkRefreshStatus() async {
    final inputState = Provider.of<InputState>(context, listen: false);
    final lastRefreshString = await inputState.fetchInputFromLocal('last_refresh');

    if (lastRefreshString == null) {
      if (mounted) {
        setState(() {
          _canRefresh = true;
          _countdownText = '';
        });
      }
      return;
    }

    try {
      final lastRefresh = DateTime.parse(lastRefreshString);
      final now = DateTime.now();
      final difference = now.difference(lastRefresh);
      const cooldownDuration = Duration(hours: 10);

      if (difference >= cooldownDuration) {
        if (mounted) {
          setState(() {
            _canRefresh = true;
            _countdownText = '';
          });
        }
      } else {
        final remaining = cooldownDuration - difference;
        if (mounted) {
          setState(() {
            _canRefresh = false;
            if (remaining.inHours > 0) {
              final hours = remaining.inHours;
              final minutes = remaining.inMinutes % 60;
              if (hours == 1 && minutes == 0) {
                _countdownText = '1 hour';
              } else if (minutes > 0) {
                _countdownText = '${hours}h ${minutes}m';
              } else {
                _countdownText = '$hours hours';
              }
            } else {
              final minutes = remaining.inMinutes;
              if (minutes <= 1) {
                _countdownText = '1 minute';
              } else {
                _countdownText = '$minutes minutes';
              }
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _canRefresh = true;
          _countdownText = '';
        });
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (!_canRefresh || _isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final userSync = Provider.of<UserSyncProvider>(context, listen: false);
      await userSync.fetchUsersForMatch(context);
      await _checkRefreshStatus();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final instances = widget.matchInstances;
    print("ProfileCarousel building with ${instances.length} profiles");

    List<Widget> carouselItems = [];

    for (var instance in instances) {
      carouselItems.add(_buildProfileCard(instance, context));
    }

    carouselItems.add(_buildRefreshCard(context));
    carouselItems.add(_buildQuestionsCard(context));
    carouselItems.add(_buildFeedbackCard(context));

    return CarouselSlider(
      options: CarouselOptions(
        height: 700,
        autoPlay: false,
        enlargeCenterPage: true,
        enableInfiniteScroll: false,
      ),
      items: carouselItems,
    );
  }
  
  Widget _buildProfileCard(Map<String, dynamic> matchInstance, BuildContext context) {
    final otherUserId = _getOtherUserId(matchInstance);
    if (otherUserId == null || otherUserId.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: _loadUser(otherUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_userCache.containsKey(otherUserId)) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = snapshot.data;
        if (profile == null) {
          return const Center(child: Text("Could not load profile"));
        }

        String? imageUrl;

      if (profile['photos'] != null) {
        if (profile['photos'] is List && (profile['photos'] as List).isNotEmpty) {
          imageUrl = (profile['photos'] as List)[0];
        } else if (profile['photos'] is Map && (profile['photos'] as Map).containsKey(0)) {
          imageUrl = (profile['photos'] as Map)[0];
        } else if (profile['photos'] is String) {
          imageUrl = profile['photos'];
        }
      }

      return Align(
        alignment: Alignment.topRight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                imageUrl != null
                ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1 / 1.15,  // width / height ratio (0.8)
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // IMAGE
                        Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print("Image error: $error");
                            return Container(
                              width: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                            );
                          },
                        ),
                        // GRADIENT
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.0),  // Transparent at top
                                  Colors.black.withOpacity(0.5),  // 50% opacity at bottom
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),)
                : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 1 / 1.25,  // Same ratio for the error state
                    child: Container(
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  ),
                ),

                // Name & Age Display
                Positioned(
                  bottom: 20,
                  left: 20,
                  child: Text(
                    "${profile['nameFirst'] ?? 'Unknown'}, ${MiscService().calculateAge(profile['birthDate'])}",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.white,
                    ),
                  ),
                ),

                // Badge
                if (_getStatusBadge(matchInstance) != null)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _getStatusBadge(matchInstance)!,
                  ),
              ],
            ),
                                
            Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profile['compatibility']?['percentage'] != null
                  ? Text(
                      '${profile['compatibility']?['percentage']?.toInt()}% Match',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    )
                  : TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => RefreshDataWidget(
                            errorContext: 'Missing compatibility data',
                            onComplete: () => setState(() {}),
                          ),
                        );
                      },
                      child: Text(
                        'Data Missing - Refresh',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  if (profile['compatibility']?['topReasons'] != null && 
                      (profile['compatibility']['topReasons'] as List).isNotEmpty)
                    PillText(
                      text: profile['compatibility']['topReasons'][0],
                      colorVariant: "peachLite",
                    ),

                  const SizedBox(height: 8),

                  if (profile['compatibility']?['topReasons'] != null && 
                      (profile['compatibility']['topReasons'] as List).length > 1)
                    PillText(
                      text: profile['compatibility']['topReasons'][1],
                      colorVariant: "violetLite",
                    ),

                  const SizedBox(height: 8),

                  if (profile['compatibility']?['interests'] != null && 
                      profile['compatibility']['interests']['matches'] != null &&
                      (profile['compatibility']['interests']['matches'] as List).isNotEmpty)
                    PillText(
                      text: profile['compatibility']['interests']['reason'],
                      colorVariant: "greenLite",
                    ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user == null) {
                        Navigator.pushNamed(context, AppRoutes.register);
                      } else {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.match,
                          arguments: {
                            'matchInstance': matchInstance,
                            'profile': profile,
                          },
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      overlayColor: Colors.transparent,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 3),
                        Text(
                          'Explore',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: ColorPalette.peach,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.open_in_full,
                          color: ColorPalette.peach,
                          size: 24, // Adjust size to match your text style
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },);
  }

  Widget _buildRefreshCard(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: ColorPalette.peach,
          image: DecorationImage(
            image: AssetImage('assets/compressed_refreshCard.jpg'),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Icon changes based on state
              _isRefreshing
                ? const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : Icon(
                    _canRefresh ? Icons.refresh : Icons.hourglass_top,
                    size: 48,
                    color: ColorPalette.white,
                  ),

              const SizedBox(height: 16),

              // Title text changes based on refresh availability
              Text(
                _canRefresh
                    ? 'Ready for New Profiles?'
                    : 'Next Refresh in $_countdownText',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: ColorPalette.white,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Fewer profiles, deeper connections. We believe in quality over quantity.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.white,
                ),
              ),

              const Spacer(),

              // Action button — only tappable when refresh is available
              if (_canRefresh)
                ElevatedButton.icon(
                  onPressed: _isRefreshing ? null : _handleRefresh,
                  icon: const Icon(Icons.refresh, size: 20),
                  label: Text(
                    'Refresh Profiles',
                    style: AppTextStyles.headingMedium.copyWith(
                      color: ColorPalette.peach,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ColorPalette.peach,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                ),

              if (!_canRefresh)
                Text(
                  'Check back soon',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: ColorPalette.peachLite,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(
                Icons.settings,
                size: 32,
                color: ColorPalette.peach,
              ),
              const SizedBox(height: 16),
              Text(
                'We Love Hearing From You!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us what is working and what can be improved about this experience.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Our mission is to transform dating into an intentional experience for everyone.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => const FeedbackDialog(),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  overlayColor: Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Leave Feedback',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: ColorPalette.peach,
                      size: 20,
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

  Widget _buildQuestionsCard(BuildContext context) {    
     return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ColorPalette.violet,
                  ColorPalette.peach,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Unlock Better Matches',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: Colors.white,
                      fontSize: 28,
                    ),
                  ),
                                
                  const Spacer(),
                  
                  Text(
                    'The more we know about you, the better we can find your perfect match.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  
                  const Spacer(),
                 
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.unansweredQuestions);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ColorPalette.peach,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Answer Questions',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: ColorPalette.peach,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: ColorPalette.peach,
                          size: 20,
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

  Widget? _getStatusBadge(Map<String, dynamic> matchInstance) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final status = matchInstance['status'] as String? ?? 'active';
    final log = List<Map<String, dynamic>>.from(matchInstance['log'] ?? []);
    final lastLogBy = log.isNotEmpty ? log.last['by'] : null;

    String? label;
    IconData? icon;
    Color? bgColor;
    Color? textColor;

    if (status == 'chat_requested' && lastLogBy == currentUserId) {
      label = 'Request Sent';
      icon = Icons.arrow_upward;
      bgColor = ColorPalette.peach;
      textColor = Colors.white;
    } else if (status == 'chat_requested' && lastLogBy != currentUserId) {
      label = 'Request Received';
      icon = Icons.arrow_downward;
      bgColor = ColorPalette.green;
      textColor = Colors.white;
    } else if (status == 'matched') {
      label = 'Matched';
      icon = Icons.favorite;
      bgColor = ColorPalette.pink;
      textColor = Colors.white;
    }

    if (label == null) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

}