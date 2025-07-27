import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../styles.dart';

class ProfileCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> userData;
  final bool isLoading;
  const ProfileCarousel({
    Key? key, 
    required this.userData,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<ProfileCarousel> createState() => _ProfileCarouselState();
}

class _ProfileCarouselState extends State<ProfileCarousel> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final profiles = widget.userData;
    print("ProfileCarousel building with ${profiles.length} profiles");
    
    if (profiles.isEmpty) {
      return const Center(child: Text("No matches found", style: TextStyle(color: Colors.white, fontSize: 18)));
    }

    return CarouselSlider(
      options: CarouselOptions(
        height: 600,
        autoPlay: false,
        enlargeCenterPage: true,
      ),

      items: List<Widget>.from(profiles.map<Widget>((profile) {
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
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),

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
                            "${profile['firstName'] ?? 'Unknown'}, ${profile['birthDate'] ?? 'Unknown'}",
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
                                AppRoutes.profile,
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
                  
                  const SizedBox(height: 10),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Match 95%',
                          style: AppTextStyles.headingLarge.copyWith(
                            color: ColorPalette.peach,
                          ),
                        ),
                        Text(
                          'complimenting emotional qualities',
                          style: AppTextStyles.headingSmall.copyWith(
                            color: ColorPalette.peach,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            final user = FirebaseAuth.instance.currentUser;
                            if (user == null) {
                              Navigator.pushNamed(context, AppRoutes.register);
                            } else {
                              print("User is logged in, staying on the same page.");
                            }
                          },
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                          child: const Text('Send Chat Request'),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          );
        })).toList(),
    );
  }
}