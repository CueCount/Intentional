import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../functions/miscService.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/pill.dart'; 
import '../../widgets/matchCTA.dart';
import '../../widgets/flagUser.dart';

class Match extends StatefulWidget {
  const Match({super.key});
  @override
  State<Match> createState() => _Match();
}

class _Match extends State<Match>  with TickerProviderStateMixin {
  Map<String, dynamic>? profile; 

  // Simple animation tracking - just need one controller per section
  AnimationController? _photoController;
  AnimationController? _overviewController;
  AnimationController? _chemistryController;
  AnimationController? _photo2Controller;
  AnimationController? _physicalController;
  AnimationController? _photo3Controller;
  AnimationController? _interestsController;
  AnimationController? _photo4Controller;
  AnimationController? _goalsController;
  AnimationController? _ctaController;

  @override
  void initState() {
    super.initState();

    // Create all animation controllers upfront (simple!)
    _photoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _overviewController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _chemistryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _photo2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _physicalController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _photo3Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _interestsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _photo4Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _goalsController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _ctaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final Map<String, dynamic>? profileData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (profileData == null) {
        print("❌ Error: Profile data is null!");
        return;
      }

      setState(() {
        profile = profileData;
      });

    });
  
  }

  Widget _buildAnimatedSection({
    required String key,
    required AnimationController? controller,
    required Widget child,
  }) {
    if (controller == null) return child; // Safety check
    
    final AnimationController safeController = controller; // Type promotion
    
    return VisibilityDetector(
      key: Key(key),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.2 && safeController.status == AnimationStatus.dismissed) {
          safeController.forward();
        }
      },
      child: AnimatedBuilder(
        animation: safeController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - safeController.value)),
            child: Opacity(
              opacity: safeController.value,
              child: child,
            ),
          );
        },
        child: child,
      ),
    );
  }
  
  @override
  void dispose() {
    // Clean up all controllers
    _photoController?.dispose();
    _overviewController?.dispose();
    _chemistryController?.dispose();
    _photo2Controller?.dispose();
    _physicalController?.dispose();
    _photo3Controller?.dispose();
    _interestsController?.dispose();
    _photo4Controller?.dispose();
    _goalsController?.dispose();
    _ctaController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final photos = profile!['photos'] as List;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(),
              Container(
                padding: const EdgeInsets.all(16),
                child: Column (

                  children: [
                    
                    /* = = = = = = = = = 
                    First Photo
                    = = = = = = = = = = */
                    if (photos.isNotEmpty)
                      Container(
                        width: double.infinity,
                        height: 400,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photos[0],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Match Overview
                    = = = = = = = = = = */
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Match ${profile?['compatibility']?['percentage']?.toInt() ?? 0}%',
                            style: AppTextStyles.headingLarge.copyWith(
                              color: ColorPalette.peach,
                              fontSize: 48,
                            ),
                          ),
                          Text(
                            "${profile?['nameFirst'] ?? 'Unknown'}, ${MiscService().calculateAge(profile?['birthDate'])}, ${profile?['school']}, ${profile?['career']}",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                        ],
                      ),
                    ),

                    /* = = = = = = = = = 
                    MBTI Overview
                    = = = = = = = = = = */
                    /*Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: ColorPalette.peachLite,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MBTI Match',
                            style: AppTextStyles.headingMedium.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lorium ipsum lorium ipsum',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: ColorPalette.peach,
                            ),
                          ),
                        ],
                      ),
                    ),*/

                    /* = = = = = = = = = 
                    Chemistry Match
                    = = = = = = = = = = */
                    _buildAnimatedSection(
                      key: 'chemistry',
                      controller: _chemistryController,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: ColorPalette.peach,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile?['compatibility']?['chemistry']?['percentage']?.toInt() ?? 0}%',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            Text(
                              'Chemistry Match',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Display the reason
                            if (profile?['compatibility']?['chemistry']?['reason'] != null)
                              Column(
                                children: [
                                  PillText(
                                    text: profile!['compatibility']['chemistry']['reason'],
                                    colorVariant: "peachMedium"
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            
                            // Display all matches (not just the first one)
                            if (profile?['compatibility']?['chemistry']?['matches'] != null)
                              ...((profile!['compatibility']['chemistry']['matches'] as List).map((match) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PillText(
                                    text: match, 
                                    colorVariant: "peachMedium"
                                  ),
                                ),
                              ).toList()),
                          ],
                        ),
                      ),
                    ),

                    /* = = = = = = = = = 
                    Second Photo
                    = = = = = = = = = = */
                    if (photos.length > 1)
                      if (photos.length > 1)
                      _buildAnimatedSection(
                        key: 'photo2',
                        controller: _photo2Controller,
                        child: Container(
                          width: double.infinity,
                          height: 400,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              photos[1],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Personality Match
                    = = = = = = = = = = */       
                    _buildAnimatedSection(
                      key: 'physical',
                      controller: _physicalController,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: ColorPalette.violet,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile?['compatibility']?['personality']?['percentage']?.toInt() ?? 0}%',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            Text(
                              'Personality Match',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (profile?['compatibility']?['personality']?['reason'] != null)
                              Column(
                                children: [
                                  PillText(
                                    text: profile!['compatibility']['personality']['reason'],
                                    colorVariant: "violetMedium"
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),                                  
                            if (profile?['compatibility']?['personality']?['matches'] != null && 
                                (profile!['compatibility']['personality']['matches'] as List).isNotEmpty)
                              ...((profile!['compatibility']['personality']['matches'] as List).map((match) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PillText(
                                    text: match, 
                                    colorVariant: "violetMedium"
                                  ),
                                ),
                              ).toList()),
                          ],
                        ),
                      ),
                    ),

                    /* = = = = = = = = = 
                    Third Photo
                    = = = = = = = = = = */
                    if (photos.length > 2)
                      _buildAnimatedSection(
                        key: 'photo3',
                        controller: _photo3Controller,
                        child: Container(
                          width: double.infinity,
                          height: 400,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              photos[2],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Interests Match
                    = = = = = = = = = = */
                    _buildAnimatedSection(
                      key: 'interests',
                      controller: _interestsController,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: ColorPalette.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile?['compatibility']?['interests']?['percentage']?.toInt() ?? 0}%',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            Text(
                              'Interests Match',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (profile?['compatibility']?['interests']?['reason'] != null)
                              Column(
                                children: [
                                  PillText(
                                    text: profile!['compatibility']['interests']['reason'],
                                    colorVariant: "greenMedium"
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),                                  
                            if (profile?['compatibility']?['interests']?['matches'] != null && 
                                (profile!['compatibility']['interests']['matches'] as List).isNotEmpty)
                              ...((profile!['compatibility']['interests']['matches'] as List).map((match) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PillText(
                                    text: match, 
                                    colorVariant: "greenMedium"
                                  ),
                                ),
                              ).toList()),
                          ],
                        ),
                      ),
                    ),

                    /* = = = = = = = = = 
                    Fourth Photo
                    = = = = = = = = = = */
                    if (photos.length > 3)
                      _buildAnimatedSection(
                        key: 'photo4',
                        controller: _photo4Controller,
                        child: Container(
                          width: double.infinity,
                          height: 400,
                          margin: const EdgeInsets.only(bottom: 20),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              photos[3],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    /* = = = = = = = = = 
                    Goals Match
                    = = = = = = = = = = */
                    _buildAnimatedSection(
                      key: 'goals',
                      controller: _goalsController,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: ColorPalette.pink,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${profile?['compatibility']?['goals']?['percentage']?.toInt() ?? 0}%',
                              style: AppTextStyles.headingLarge.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            Text(
                              'Life Goals Alignment',
                              style: AppTextStyles.headingMedium.copyWith(
                                color: ColorPalette.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (profile?['compatibility']?['goals']?['reason'] != null)
                              Column(
                                children: [
                                  PillText(
                                    text: profile!['compatibility']['goals']['reason'],
                                    colorVariant: "pinkMedium"
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),                                  
                            if (profile?['compatibility']?['goals']?['matches'] != null && 
                                (profile!['compatibility']['goals']['matches'] as List).isNotEmpty)
                              ...((profile!['compatibility']['goals']['matches'] as List).map((match) => 
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: PillText(
                                    text: match, 
                                    colorVariant: "pinkMedium"
                                  ),
                                ),
                              ).toList()),
                          ],
                        ),
                      ),
                    ),

                    /* = = = = = = = = = 
                    Call to Action
                    = = = = = = = = = = */ 
                    MatchCTA(
                      targetUserId: profile?['userId'] ?? '',
                    ),

                    /* = = = = = = = = = 
                    Flag User Button
                    = = = = = = = = = = */ 
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => FlagUserWidget(
                            targetUserId: profile?['userId'] ?? '',
                            chatId: 'optional_chat_id', // Optional - pass if flagging from a chat
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        overlayColor: Colors.transparent,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Flag Profile',
                            style: AppTextStyles.headingSmall.copyWith(
                              color: ColorPalette.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.flag, color: Colors.grey),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                 
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