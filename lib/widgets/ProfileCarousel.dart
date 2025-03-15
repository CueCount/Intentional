import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/input_message.dart';
import '../router/router.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Make sure this is imported

class ProfileCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> userData; // Accepts user data list
  const ProfileCarousel({Key? key, required this.userData}) : super(key: key);

  @override
  State<ProfileCarousel> createState() => _ProfileCarouselState();
}

class _ProfileCarouselState extends State<ProfileCarousel> {
  List<Map<String, dynamic>> profiles = [];
  Map<String, String> updatedImageUrls = {};
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();

    print("ProfileCarousel received userData: ${widget.userData.length} users");

    if (widget.userData.isNotEmpty) {
      setState(() {
        profiles = widget.userData;
        isLoading = false;
      });

      print("Profiles assigned: ${profiles.length} users");
      
    } else {
      setState(() {
        isLoading = false;
      });

      print("No users found in userData.");
    }
  }

  @override
  Widget build(BuildContext context) {
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
      items: profiles.isEmpty
  ? [const Center(child: Text("No matches found."))]
  : List<Widget>.from(profiles.map<Widget>((profile) {
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
                    // ✅ Profile Image with simpler handling
                    imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.cover,
                                                  
                          errorBuilder: (context, error, stackTrace) {
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
                          "${profile['firstName']}, ${profile['birthDate']}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                          ),
                        ),
                      ),

                      // Expand Button
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () {
                            print("Expand Profile Clicked");
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

                const SizedBox(height: 40),

                // Message Input Box for the Active Profile
                (_currentIndex == index)
                ? MessageInputBox(
                    onSaved: (value) {
                      print("Saved input: $value");
                    },
                    onNextPressed: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                  )
                : const SizedBox.shrink(),
              ],
            ),
          ),
        );
      })).toList(),
    );
  }
}