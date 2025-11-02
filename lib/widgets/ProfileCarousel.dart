import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/miscService.dart';
import '../../widgets/pill.dart'; 
import '../styles.dart';
import '../widgets/errorDialog.dart';
import '../widgets/feedback.dart';

class ProfileCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  final List<Map<String, dynamic>> inputData; 
  final bool isLoading;

  const ProfileCarousel({
    Key? key, 
    required this.userData,
    this.inputData = const [],
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ProfileCarousel> createState() => _ProfileCarouselState();
}

class _ProfileCarouselState extends State<ProfileCarousel> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final profiles = widget.userData;
    print("ProfileCarousel building with ${profiles.length} profiles");

    final inputs = widget.inputData; // Uncommented this
    
    if (profiles.isEmpty) {
      return const Center(child: Text("No matches found", style: TextStyle(color: Colors.white, fontSize: 18)));
    }

    // Build the carousel items list with inputs inserted at positions 4 and 8
    List<Widget> carouselItems = [];
    int inputIndex = 0;
    
    for (int i = 0; i < profiles.length; i++) {
      // Add input card at position 3 (index 2)
      if (i == 2 && inputIndex < inputs.length) {
        carouselItems.add(_buildInputCard(inputs[inputIndex], context));
        inputIndex++;
      }
      
      // Add input card at position 5 (index 4)
      if (i == 4 && inputIndex < inputs.length) {
        carouselItems.add(_buildInputCard(inputs[inputIndex], context));
        inputIndex++;
      }
      
      // Add profile card
      carouselItems.add(_buildProfileCard(profiles[i], context));
    }
    
    // If we have fewer than 4 profiles but still have inputs, add them at the end
    if (profiles.length < 4 && inputIndex < inputs.length) {
      while (inputIndex < inputs.length && inputIndex < 2) {
        carouselItems.add(_buildInputCard(inputs[inputIndex], context));
        inputIndex++;
      }
    }

    carouselItems.add(_buildRefreshCard(context));
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
  
  Widget _buildInputCard(Map<String, dynamic> input, BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: ColorPalette.lite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.max, // Changed from min to max
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Added this
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get better matches',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 16,
                ),
              ),
              Text(
                input['title'] ?? 'Question',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 32,
                ),
              ),
              Text(
                ' ',
                style: TextStyle(
                  color: ColorPalette.peach,
                  fontSize: 24,
                ),
              ),
              SizedBox(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.input, 
                      arguments: {
                        'inputName': input['inputName'],
                        'nextRoute': input['nextRoute'],
                      },
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    overlayColor: Colors.transparent,
                  ),
                  child: Row(                    
                    children: [
                      Text(
                        'Respond',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: ColorPalette.peach,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileCard(Map<String, dynamic> profile, BuildContext context) {
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
      alignment: Alignment.center,
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
                    ),),

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

                  // Expand Button
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.match,
                          arguments: profile,
                        );
                      },
                      child: const Icon(
                        Icons.open_in_full,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
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
                    'Match ${profile['compatibility']?['percentage']?.toInt()}%',
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
                        arguments: profile,
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
  }

  Widget _buildRefreshCard(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: ColorPalette.peachLite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 48,
                color: ColorPalette.peach,
              ),
              const SizedBox(height: 16),
              Text(
                'Next Prospect Refresh in 17 Hours',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: ColorPalette.peach,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We limit the number of profiles seen at once for everyone. If you want to explore different profiles revise some of your Needs and they will be applied on the next Refresh :)',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach.withOpacity(0.8),
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

}