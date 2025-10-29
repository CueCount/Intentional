import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '/router/router.dart';
import '../../styles.dart';
import '../../providers/userState.dart';
import '../../providers/inputState.dart';

class GuideAvailableMatches extends StatefulWidget {
  const GuideAvailableMatches({super.key});
  @override
  State<GuideAvailableMatches> createState() => _GuideAvailableMatches();
}

class _GuideAvailableMatches extends State<GuideAvailableMatches> {
  bool _isLoading = true;
  List<String?> _userPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadInitialUsers();
  }

  Future<void> _loadInitialUsers() async {
    final userProvider = Provider.of<UserSyncProvider>(context, listen: false);
    final inputState = Provider.of<InputState>(context, listen: false);
    
    await userProvider.fetchInitialUsers(inputState);
    
    final prefs = await SharedPreferences.getInstance();
    final currentSessionId = inputState.userId;
    final usersList = prefs.getStringList('users_$currentSessionId') ?? [];
    
    List<String?> photos = [];
    for (String userJson in usersList) {
      final userData = jsonDecode(userJson);
      if (userData['photos'] != null && 
          userData['photos'] is List && 
          (userData['photos'] as List).isNotEmpty) {
        photos.add(userData['photos'][0]);
      } else {
        photos.add(null); // Placeholder for users without photos
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 300,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 20,
                        runSpacing: 20,
                        children: List.generate(
                          _userPhotos.length > 7 ? 7 : _userPhotos.length,
                          (index) => _buildPhotoCircle(_userPhotos[index]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Potential Matches are In!',
                      style: AppTextStyles.headingLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Access match requests once you verify your identity.',
                      style: AppTextStyles.headingSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.photos);
                      },
                      icon: Text(
                        'Complete Verification',
                        style: AppTextStyles.headingMedium.copyWith(color: Colors.white),
                      ),
                      label: const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildPhotoCircle(String? photoUrl) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
        image: photoUrl != null 
          ? DecorationImage(
              image: NetworkImage(photoUrl),
              fit: BoxFit.cover,
            )
          : null,
      ),
      child: photoUrl == null 
        ? const Icon(Icons.person, color: Colors.grey, size: 40)
        : null,
    );
  }

}