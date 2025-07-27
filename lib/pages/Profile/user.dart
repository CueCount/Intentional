import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../../widgets/shortcarousel.dart'; 
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/profile_info_carousel.dart';
import '../../widgets/pill.dart'; 
import 'package:firebase_auth/firebase_auth.dart';


class UserProfile extends StatefulWidget {
  const UserProfile({super.key});
  @override
  State<UserProfile> createState() => _userProfile();
}

class _userProfile extends State<UserProfile> {
  Map<String, dynamic>? profile; 
  int _currentImageIndex = 1; 
  int _currentMatchQualityIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final Map<String, dynamic>? profileData = 
      ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;

      if (profileData == null) {
        print("❌ Error: Profile data is null!");
        return;
      }

      setState(() {
        profile = profileData;
      });
    });
  }

  bool _isOwnProfile(String? profileUserId) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return currentUserId != null && currentUserId == profileUserId;
  }

  String? getNextImage() {
    if (profile == null) return null;
    final photos = profile!['photos'] as List;
    if (_currentImageIndex >= photos.length) {
      _currentImageIndex = 0; // Loop back to start if we run out
    }
    final imageUrl = photos[_currentImageIndex];
    _currentImageIndex++; // Increment for next call
    return imageUrl;
  }

  Map<String, dynamic>? getNextMatchQuality() {
    final matchQualities = getMatchQualities();
    if (_currentMatchQualityIndex >= matchQualities.length) {
      _currentMatchQualityIndex = 0; // Loop back to start if we run out
    }
    final quality = matchQualities[_currentMatchQualityIndex];
    _currentMatchQualityIndex++; // Increment for next call
    return quality;
  }

  List<Map<String, dynamic>> getMatchQualities() {
    return [
      {
        'percentage': '80% Personality Match',
        'description': 'You each have complimenting emotional qualities. You each have complimenting emotional qualities.',
        'color': ColorPalette.peach,
      },
      {
        'percentage': '58% Lifestyle Match',
        'description': 'You each have complimenting emotional qualities',
        'color': ColorPalette.violet,
      },
      {
        'percentage': '40% Dynamic Match',
        'description': 'You each have complimenting emotional qualities',
        'color': ColorPalette.green,
      },
      {
        'percentage': '75% Interest Match',
        'description': 'Shared passions and hobbies that bring you together',
        'color': ColorPalette.peach,
      },
      {
        'percentage': '62% Values Match',
        'description': 'Similar life goals and moral compass alignment',
        'color': ColorPalette.violet,
      },
    ];
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
        child: Container(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const CustomStatusBar(messagesCount: 2,likesCount: 5,),

                // First Photo
                Container(
                  width: double.infinity,
                  height: 400,
                  padding: const EdgeInsets.all(16),
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

                // Match Info Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '95% Match',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: ColorPalette.peach,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PillText(text: 'complimenting emotional qualities'),
                      const SizedBox(height: 8),
                      PillText(text: 'best friend in a partner'),
                      const SizedBox(height: 8),
                      PillText(text: 'bar hopping'),
                    ],
                  ),
                ),

                // Dynamic Carousels
                TwoItemCarousel(
                  type: CarouselType.matchQualityImage,
                  alignment: CarouselAlignment.left,
                  getNextImage: getNextImage,
                  getNextMatchQuality: getNextMatchQuality,
                ),

                TwoItemCarousel(
                  type: CarouselType.imageMatchQuality,
                  alignment: CarouselAlignment.right,
                  getNextImage: getNextImage,
                  getNextMatchQuality: getNextMatchQuality,
                ),
                
                TwoItemCarousel(
                  type: CarouselType.matchQualityImage,
                  alignment: CarouselAlignment.left,
                  getNextImage: getNextImage,
                  getNextMatchQuality: getNextMatchQuality,
                ),

                // Profile Info Carousel - uses profile data directly
                ProfileInfoCarousel(
                  profileData: profile!,
                  height: 150, 
                ),

                // Other Matching Qualities Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  margin: const EdgeInsets.only(bottom: 20),
                  child:
                    Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '5 Other Matching Qualities',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: ColorPalette.peach,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SizedBox(height: 8),
                      PillText(text: 'complimenting emotional qualities'),
                      const SizedBox(height: 8),
                      PillText(text: 'best friend in a partner'),
                      const SizedBox(height: 8),
                      PillText(text: 'bar hopping'),
                    ],
                  ),
                ),

                // Additional Images
                TwoItemCarousel(
                  type: CarouselType.imageImage,
                  alignment: CarouselAlignment.left,
                  getNextImage: getNextImage,
                ),

                // 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Like What You See?',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: ColorPalette.peach,
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Find out if it’s mutual. If she accepts your request you will be exclusively matched with her. ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Hopefully she gets to you before someone else does ;) ',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),
                    ],
                  ),
                ),
              
              ],
            ),
          ),
        ),
      ),
    );
  }
}