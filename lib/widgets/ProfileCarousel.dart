import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../functions/fetchData.dart'; 
import '../widgets/input_message.dart';
import '../router/router.dart';
import '../../styles.dart';

class ProfileCarousel extends StatefulWidget {
  @override
  _ProfileCarouselState createState() => _ProfileCarouselState();
}

class _ProfileCarouselState extends State<ProfileCarousel> {
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;
  String _inputValue = '';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadProfiles();
  }

  bool hasLoaded = false;

  Future<void> loadProfiles() async {
    if (hasLoaded) return;
    hasLoaded = true;
    final fetchedProfiles = await fetchUsersWithPhotos();
    if (!mounted) return;
    setState(() {
      profiles = fetchedProfiles.take(10).toList();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (profiles.isEmpty && !isLoading) {
      return const Center(child: Text("No matches found."));
    }

    return isLoading
      ? const Center(child: CircularProgressIndicator())
      : CarouselSlider(
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

          items: profiles.isNotEmpty
              ? profiles.map((profile) {
                  String? imageUrl = profile['photo'];
                  int index = profiles.indexOf(profile);

                  Future.delayed(Duration.zero, () {
                    if (imageUrl != null && imageUrl.isNotEmpty) {
                      precacheImage(NetworkImage(imageUrl), context).then((_) {
                        print("🟢 Image successfully preloaded: $imageUrl");
                      }).catchError((error) {
                        print("🚨 Preloading failed: $error \nURL: $imageUrl");
                      });
                    }
                  });

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
                        child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            
                            imageUrl,
                            width: double.infinity,
                            height: 300,
                            fit: BoxFit.cover,
                            headers: {"Cache-Control": "no-cache"}, // Try forcing fresh requests
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(child: CircularProgressIndicator());
                            },
                            errorBuilder: (context, error, stackTrace) {
                              print("🚨 Image failed to load: $error \nURL: $imageUrl");
                              return Container(
                                width: double.infinity,
                                height: 300, // Set the same height as the image
                                color: Colors.grey[300], // Background color when image fails
                                alignment: Alignment.center,
                                child: const Text(
                                  "Image Unavailable",
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(child: Text("No Image Available")),
                      ),

                      const SizedBox(height: 40),

                      if (_currentIndex == index)
                      AnimatedOpacity(
                        opacity: _currentIndex == index ? 1.0 : 0.0, // Fully visible when active
                        duration: const Duration(milliseconds: 500), // 0.5 sec fade-in effect
                        curve: Curves.easeInOut,
                        child: MessageInputBox(
                          onSaved: (value) {
                            print("Saved input: $value");
                          },
                          onNextPressed: () {
                            Navigator.pushNamed(context, AppRoutes.photos);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList()
          : [const Center(child: Text("No profiles found."))], // Prevents crashing when empty
      );
    }

}
