import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/inputCheckbox.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Chemistry extends StatefulWidget {
  const Chemistry({super.key});
  @override
  State<Chemistry> createState() => _chemistry();
}

class _chemistry extends State<Chemistry> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, dynamic> inputValues = {};
  Map<String, bool> selectedValues = {};
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExistingValues();
    });
  }

  Future<void> _loadExistingValues() async {
    final inputState = Provider.of<InputState>(context, listen: false);
    
    // Initialize all possible values as false first
    for (var input in inputState.emotionalNeeds) {
      for (var value in input.possibleValues) {
        selectedValues[value] = false; 
      }
    }
    
    try {
      // Get existing emotional needs from provider
      final existingEmotionalNeeds = await inputState.getInput('EmotionalNeed');
      
      if (existingEmotionalNeeds != null && existingEmotionalNeeds is List) {
        // Mark existing selections as true
        for (String selectedValue in existingEmotionalNeeds) {
          if (selectedValues.containsKey(selectedValue)) {
            selectedValues[selectedValue] = true;
          }
        }
      }
    } catch (e) {
      print('Chemistry: Error loading existing values - $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    return {
      "EmotionalNeed": selectedValues.entries
          .where((entry) => entry.value)  
          .map((entry) => entry.key)       
          .toList(),                       
    };
  }

  bool isFormComplete() {
    int selectedCount = selectedValues.values.where((v) => v).length;
    return selectedCount >= 1;
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SCAFFOLD
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  @override
  Widget build(BuildContext context) {
    final inputState = Provider.of<InputState>(context);
    Map<String, dynamic> inputData = getSelectedAttributes();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(),
              Container (
                padding: const EdgeInsets.all(32), 
                child: Column(
                  children: [
                    Text(
                      'Choose 3 Personality Traits You Value',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10.0, // horizontal spacing between items
                      runSpacing: 10.0, // vertical spacing between rows
                      children: inputState.emotionalNeeds.isNotEmpty 
                      ? inputState.emotionalNeeds[0].possibleValues.map<Widget>((attribute) {
                        int selectedCount = selectedValues.values.where((v) => v).length;
                          return SizedBox(
                            width: MediaQuery.of(context).size.width - 32, // Full width minus padding
                            child: CustomCheckbox(
                              attribute: CheckboxAttribute(
                                title: attribute,
                                description: '',
                                isSelected: selectedValues[attribute] ?? false,
                              ),
                              isHorizontal: true,
                              maxSelections: 3, // Set the limit to 3
                              currentSelectionCount: selectedCount,
                              onChanged: (isSelected) {
                                setState(() {
                                  selectedValues[attribute] = isSelected;
                                });
                              },
                              isSelected: selectedValues[attribute] ?? false,
                            ),
                          );
                        }).toList()
                      : [],
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
        final inputData = getSelectedAttributes();
        bool isComplete = isFormComplete();
        
        return CustomAppBar(
          buttonText: isLoggedIn ? 'Save' : 'Continue',
          buttonIcon: isLoggedIn ? Icons.save : Icons.arrow_forward,
          isEnabled: isComplete,  

          onPressed: () async {
            if (isLoggedIn) {
              await inputState.saveNeedLocally(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {
              await inputState.saveNeedLocally(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.relationship);
              }
            }
          },
        );
      }(),
    );
  }
}