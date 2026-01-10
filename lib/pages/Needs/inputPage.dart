import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/inputCheckbox.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalityQ1 extends StatefulWidget {
  final String inputName; // Add this to specify which Input to use
  final String nextRoute; // Add this to specify where to navigate next
  
  const PersonalityQ1({
    super.key,
    required this.inputName,
    required this.nextRoute,
  });
  
  @override
  State<PersonalityQ1> createState() => _personalityQ1();
}

class _personalityQ1 extends State<PersonalityQ1> {

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, dynamic> inputValues = {};
  Map<String, bool> selectedValues = {};
  bool _isLoading = true;
  Input? currentInput; // Store the current input
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingValues();
    });
  }

  Future<void> _loadExistingValues() async {
    final inputState = Provider.of<InputState>(context, listen: false);
    
    // Get the input based on the inputName parameter
    currentInput = _getInputByName(inputState, widget.inputName);
    
    if (currentInput == null) {
      print('PersonalityQ: Input ${widget.inputName} not found');
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // Initialize all possible values as false first
    for (var value in currentInput!.possibleValues) {
      selectedValues[value] = false; 
    }
    
    try {
      // Get existing values from provider using the input name
      final existingValues = await inputState.fetchInputFromLocal(widget.inputName);
      
      if (existingValues != null && existingValues is List) {
        // Mark existing selections as true
        for (String selectedValue in existingValues) {
          if (selectedValues.containsKey(selectedValue)) {
            selectedValues[selectedValue] = true;
          }
        }
      } else {
        print('PersonalityQ: No existing ${widget.inputName} array found, starting fresh');
      }
    } catch (e) {
      print('PersonalityQ: Error loading existing values - $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  // Helper method to get Input by name from provider
  Input? _getInputByName(InputState inputState, String name) {
    final Map<String, List<Input>> allInputs = {
      'personalityQ1': inputState.personalityQ1,
      'personalityQ2': inputState.personalityQ2,
      'personalityQ3': inputState.personalityQ3,

      'personality': inputState.personality,
      'relationship': inputState.relationship,
      'interests': inputState.interests,
      'lifeGoalNeeds': inputState.lifeGoalNeeds,
    };
    
    final inputList = allInputs[name];
    return (inputList != null && inputList.isNotEmpty) ? inputList[0] : null;
  }

  Map<String, dynamic> getSelectedAttributes() {
    return {
      widget.inputName: selectedValues.entries
          .where((entry) => entry.value)  
          .map((entry) => entry.key)       
          .toList(),                       
    };
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SCAFFOLD
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  @override
  Widget build(BuildContext context) {
    if (_isLoading || currentInput == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(),
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentInput!.title, // Use the title from the Input
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                      textAlign: TextAlign.left,
                    ),

                    const SizedBox(height: 20),

                    Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: currentInput!.possibleValues.map<Widget>((attribute) {
                        return SizedBox(
                          width: double.infinity,
                          child: CustomCheckbox(
                            attribute: CheckboxAttribute(
                              title: attribute,
                              description: '',
                              isSelected: selectedValues[attribute] ?? false,
                            ),
                            isHorizontal: true, 
                            shrinkWrap: true, 
                            onChanged: (isSelected) {
                              setState(() {
                                if (isSelected) {
                                  selectedValues.forEach((key, value) {
                                    selectedValues[key] = false;
                                  });
                                }
                                selectedValues[attribute] = isSelected;
                              });
                            },
                            isSelected: selectedValues[attribute] ?? false,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: () {
        final user = FirebaseAuth.instance.currentUser;
        bool isLoggedIn = user != null;
        final inputState = Provider.of<InputState>(context, listen: false);
        final inputData = getSelectedAttributes();
        
        return CustomAppBar(
          buttonText: isLoggedIn ? 'Save' : 'Continue',
          buttonIcon: isLoggedIn ? Icons.save : Icons.arrow_forward,
          onPressed: () async {
            await inputState.saveInputToRemoteThenLocal(inputData);
            if (context.mounted) {
              Navigator.pushNamed(
                context, 
                isLoggedIn ? AppRoutes.editNeeds : widget.nextRoute,
                arguments: inputData,
              );
            }
          },
        );
      }(),
    );
  }
}