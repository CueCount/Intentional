import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/profileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../providers/userState.dart'; 
import '../../providers/matchState.dart'; 
import '../../providers/inputState.dart';
import '../../router/router.dart';

class Matches extends StatefulWidget {
  final bool shouldUpdate;
  const Matches({Key? key, this.shouldUpdate = false}) : super(key: key);
  
  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {

  List<Map<String, dynamic>> _userData = [];
  List<Map<String, dynamic>> _inputData = [];
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

      _inputData = await _getMissingInputs(inputState);
      
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

  Future<List<Map<String, dynamic>>> _getMissingInputs(InputState inputState) async {
    try {
      // Get all saved inputs from SharedPreferences
      final savedInputs = await inputState.getAllInputs();
      
      // Define all input types to check
      final allInputTypes = [
        'personalityQ1',
        'personalityQ2', 
        'personalityQ3',

        'emotionalNeeds',
        'chemistryNeeds',
        'logisticNeeds',
        'lifeGoalNeeds',
      ];
      
      // Find inputs that are not in saved data
      List<Map<String, dynamic>> missingInputs = [];
      
      for (String inputType in allInputTypes) {
        // Check if this input type is not saved or is empty
        if (!savedInputs.containsKey(inputType) || 
            (savedInputs[inputType] is List && (savedInputs[inputType] as List).isEmpty)) {
          
          // Get the actual Input object from provider
          Input? input = _getInputByName(inputState, inputType);
          
          if (input != null) {
            missingInputs.add({
              'type': 'input',
              'inputName': inputType,
              'title': input.title,
              'possibleValues': input.possibleValues,
              'nextRoute': AppRoutes.matches,
            });
          }
          
          if (missingInputs.length >= 2) break;
        }
      }
      
      return missingInputs;
    } catch (e) {
      print('Error getting missing inputs: $e');
      return [];
    }
  }
  
  // Helper method to get Input by name
  Input? _getInputByName(InputState inputState, String name) {
    final Map<String, List<Input>> allInputs = {
      'personalityQ1': inputState.personalityQ1,
      'personalityQ2': inputState.personalityQ2,
      'personalityQ3': inputState.personalityQ3,
      
      'emotionalNeeds': inputState.emotionalNeeds,
      'physicalNeeds': inputState.physicalNeeds,
      'chemistryNeeds': inputState.chemistryNeeds,
      'logisticNeeds': inputState.logisticNeeds,
      'lifeGoalNeeds': inputState.lifeGoalNeeds,
    };
    
    final inputList = allInputs[name];
    return (inputList != null && inputList.isNotEmpty) ? inputList[0] : null;
  }

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
                inputData: _inputData,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

}