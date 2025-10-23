import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../functions/miscService.dart';
import '../../widgets/pill.dart'; 
import '../styles.dart';
import '../widgets/errorDialog.dart';

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
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ColorPalette.lite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'More answers = better matches',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                input['title'] ?? 'Question',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '...',
                style: TextStyle(
                  color: ColorPalette.peach,
                  fontSize: 24,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to the personality question page with the input data
                    Navigator.pushNamed(
                      context,
                      AppRoutes.input, // This should be the dynamic personality page
                      arguments: {
                        'inputName': input['inputName'],
                        'nextRoute': input['nextRoute'],
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPalette.peach,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Respond',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ColorPalette.white,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: ColorPalette.white,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: double.infinity,
                    height: 320,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      print("Image error: $error");
                      return Container(
                        width: double.infinity,
                        height: 320,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    width: double.infinity,
                    height: 320,
                    color: Colors.grey[300],
                    child: const Icon(Icons.no_photography, size: 50, color: Colors.grey),
                  ),

                  // Name & Age Display
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Text(
                      "${profile['firstName'] ?? 'Unknown'}, ${MiscService().calculateAge(profile['birthDate'])}",
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
                  ),)
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
                      'Refresh Data',
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        decoration: TextDecoration.underline,
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
                    colorVariant: "peachLite",
                  ),
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
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                  child: const Text('View Profile'),
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
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: ColorPalette.peachLite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                size: 48,
                color: ColorPalette.peach,
              ),
              const SizedBox(height: 40),
              Text(
                'Next Prospect',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 28,
                ),
              ),
              Text(
                'Refresh in 17 Hours',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 28,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'We limit the number of profiles\nseen at once for everyone.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'If you want to explore different\nprofiles revise some of your\nNeeds and they will be applied\non the next Refresh :)',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach.withOpacity(0.8),
                  fontSize: 16,
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
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ColorPalette.peach,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.settings,
                  size: 32,
                  color: ColorPalette.peach,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'We Love Hearing',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 32,
                ),
              ),
              Text(
                'From You!',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 32,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Tell us what is working\nand what can be improved\nabout this experience.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Our mission is to\ntransform dating into an intentional\nexperience for everyone.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: ColorPalette.peach.withOpacity(0.8),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to feedback form or open feedback dialog
                  // Navigator.pushNamed(context, AppRoutes.feedback);
                },
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