import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/profileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../providers/userState.dart'; 
import '../../providers/matchState.dart'; 
import '../../providers/inputState.dart';

class Matches extends StatefulWidget {
  final bool shouldUpdate;
  const Matches({Key? key, this.shouldUpdate = false}) : super(key: key);
  
  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {
  List<Map<String, dynamic>> _userData = [];
  bool _isLoading = true;
  bool _hasLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasLoaded) {
      _loadUsers();
      _hasLoaded = true;
    }
  }

  void _loadUsers() async {
    try {
      final matchSync = Provider.of<MatchSyncProvider>(context, listen: false);
      final userSync = Provider.of<UserSyncProvider>(context, listen: false);
      final inputState = Provider.of<InputState>(context, listen: false);
      
      final activeMatchUser = await matchSync.getActiveMatchUser();
      
      if (activeMatchUser.isNotEmpty) {
        _userData = activeMatchUser;
      } else {
        _userData = await userSync.loadUsers(inputState);
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _userData = [];
          _isLoading = false;
        });
      }
    }
  }

  /* 
    Function here to loop through Input Provider, loop through inputs_[currentSessionId] key in shared preferences 
    Get first 2 Inputs that exist in Input Provider, but are not in inputs_[currentSessionId] key.
    pass the input names of those 2 Inputs, pass through return inputData
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomStatusBar(),
            Expanded(
              child: ProfileCarousel(
                userData: _userData,
                // inputData: _inputData
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}