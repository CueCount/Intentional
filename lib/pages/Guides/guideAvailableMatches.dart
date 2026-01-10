import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '/router/router.dart';
import '../../styles.dart';
import '../../providers/userState.dart';
import '../../providers/inputState.dart';
import '../../providers/userState.dart';

class GuideAvailableMatches extends StatefulWidget {
  const GuideAvailableMatches({super.key});
  @override
  State<GuideAvailableMatches> createState() => _GuideAvailableMatches();
}

class _GuideAvailableMatches extends State<GuideAvailableMatches> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  List<String?> _userPhotos = [];

  @override
  void initState() {
    super.initState();
    _isLoggedIn = FirebaseAuth.instance.currentUser != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialUsers();
    });
  }

  Future<void> _loadInitialUsers() async {
    final userSync = Provider.of<UserSyncProvider>(context, listen: false);
    final inputState = Provider.of<InputState>(context, listen: false);
    final users = await userSync.loadUsers(inputState);
    
    List<String?> photos = [];
    for (Map<String, dynamic> userData in users) {
      if (userData['photos'] != null && 
          userData['photos'] is List && 
          (userData['photos'] as List).isNotEmpty) {
        photos.add(userData['photos'][0]);
      } else {
        photos.add(null); 
      }
    }
    
    setState(() {
      _userPhotos = photos;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    void noOperation() {}
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: ColorPalette.peach,
          padding: const EdgeInsets.all(32),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    // Overlapping profile images
                    _buildOverlappingProfiles(),
                    const SizedBox(height: 16),
                    Text(
                      'Potential\nMatches are\nWaiting!',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoggedIn
                          ? 'Your new potential matches\nhave been found!'
                          : 'Send match requests\nonce you verify your identity.',
                      style: AppTextStyles.headingSmall.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        if (_isLoggedIn) {
                          Navigator.pushNamed(context, AppRoutes.matches);
                        } else {
                          Navigator.pushNamed(context, AppRoutes.photos);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      icon: Text(
                        _isLoggedIn ? 'Start Exploring' : 'Verify Yourself',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      label: const Icon(
                        Icons.arrow_forward, 
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildOverlappingProfiles() {
    final displayCount = _userPhotos.length > 7 ? 7 : _userPhotos.length;
    final overlapOffset = 40.0;
    final totalWidth = 60.0 + (overlapOffset * (displayCount - 1));
    
    return SizedBox(
      height: 70,
      width: totalWidth,
      child: Stack(
        children: List.generate(
          displayCount,
          (index) {
            // Reverse the index so the first image appears on top
            final reversedIndex = displayCount - 1 - index;
            return Positioned(
              left: reversedIndex * overlapOffset,
              child: _buildPhotoCircle(_userPhotos[reversedIndex]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPhotoCircle(String? photoUrl) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorPalette.peach,
        border: Border.all(
          color: ColorPalette.peach,
          width: 5,
        ),
      ),
      child: ClipOval(
        child: photoUrl != null 
          ? Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.grey, size: 40),
                );
              },
            )
          : Container(
              color: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey, size: 40),
            ),
      ),
    );
  }

}