import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../router/router.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';


class ProfileCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> userData; // Accepts user data list
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
  int _currentIndex = 0;
  String _inputMessage = '';

  @override
  Widget build(BuildContext context) {
    // Handle loading state within the carousel
    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    final profiles = widget.userData;
    print("ProfileCarousel building with ${profiles.length} profiles");
    
    // Handle empty profiles
    if (profiles.isEmpty) {
      return Center(child: Text("No matches found", style: TextStyle(color: Colors.white, fontSize: 18)));
    }

    // Build carousel with available profiles
    return CarouselSlider(
      options: CarouselOptions(
        height: 600,
        autoPlay: false,
        enlargeCenterPage: true,
        onPageChanged: (index, reason) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      items: List<Widget>.from(profiles.map<Widget>((profile) {
        // More robust check for photo URL
        String? imageUrl;
        if (profile['photos'] != null) {
          if (profile['photos'] is List && (profile['photos'] as List).isNotEmpty) {
            imageUrl = (profile['photos'] as List)[0];
            print("Getting URL: $imageUrl");
          } else if (profile['photos'] is Map && (profile['photos'] as Map).containsKey(0)) {
            imageUrl = (profile['photos'] as Map)[0];
          } else if (profile['photos'] is String) {
            imageUrl = profile['photos'];
          }
        }

        int index = profiles.indexOf(profile);

        return Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
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
                      // Profile Image with simpler handling
                      imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                                                    
                            errorBuilder: (context, error, stackTrace) {
                              print("Image error: $error");
                              return Container(
                                width: double.infinity,
                                height: 300,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                              );
                            },
                          )
                        : Container(
                            width: double.infinity,
                            height: 300,
                            color: Colors.grey[300],
                            child: const Icon(Icons.no_photography, size: 50, color: Colors.grey),
                          ),

                        // Name & Age Display
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Text(
                            "${profile['firstName'] ?? 'Unknown'}, ${profile['birthDate'] ?? 'Unknown'}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),

                        // Expand Button
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: GestureDetector(
                            onTap: () {
                              if (profiles.isNotEmpty && _currentIndex < profiles.length) {
                                final selectedProfile = profiles[_currentIndex];
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.profile,
                                  arguments: selectedProfile,
                                );
                              } else {
                                print("❌ Error: Trying to navigate with a null or invalid profile.");
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.open_in_full,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  (_currentIndex == index)
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                hintText: 'Optional Message Here',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _inputMessage = value;
                                });
                              },
                            ),

                            const SizedBox(height: 20),

                            TextButton(
                              onPressed: () {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) {
                                  // User is not logged in, navigate to the register page
                                  Navigator.pushNamed(context, AppRoutes.register);
                                } else {
                                  // User is logged in, do nothing
                                  print("User is logged in, staying on the same page.");
                                }
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                              ),
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        })).toList(),
    );
  }
}