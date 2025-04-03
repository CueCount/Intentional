import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/router.dart'; 

class NotificationCTA extends StatefulWidget {
  const NotificationCTA({Key? key}) : super(key: key);

  @override
  State<NotificationCTA> createState() => _NotificationCTAState();
}

class _NotificationCTAState extends State<NotificationCTA> {
  bool _isLoading = true;
  bool _hasProfileGaps = false;

  @override
  void initState() {
    super.initState();
    _checkProfileCompleteness();
  }

  Future<void> _checkProfileCompleteness() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if name is missing
      final nameFirst = prefs.getString('nameFirst') ?? '';
      
      // Check if photos are missing
      final photoUrls = prefs.getStringList('photoUrls') ?? [];
      
      setState(() {
        _hasProfileGaps = nameFirst.isEmpty || photoUrls.isEmpty;
        _isLoading = false;
      });
    } catch (e) {
      print('Error checking profile completeness: $e');
      setState(() {
        _isLoading = false;
        _hasProfileGaps = true; // Default to true if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 48); // Placeholder while loading
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          if (_hasProfileGaps) {
            // If info is missing, navigate to photos page
            Navigator.pushNamed(context, AppRoutes.photos);
          } else {
            // If everything is complete, navigate to profile page
            Navigator.pushNamed(context, AppRoutes.profile);
          }
        },
        child: Text(
          _hasProfileGaps ? 'Update Your Photos/Info' : 'Add Needs',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}