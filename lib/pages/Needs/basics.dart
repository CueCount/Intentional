import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/inputCheckbox.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Basics extends StatefulWidget {
  const Basics({super.key});
  @override
  State<Basics> createState() => _basics();
}

class _basics extends State<Basics> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, dynamic> inputValues = {};
  // Separate maps for each checkbox group
  Map<String, bool> basicsSelected = {};
  Map<String, bool> relationshipTypeSelected = {};
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
    
    // Initialize basics (first input)
    for (var value in inputState.basics[0].possibleValues) {
      basicsSelected[value] = false; 
    }
    
    // Initialize relationshipType (second input)
    for (var value in inputState.basics[1].possibleValues) {
      relationshipTypeSelected[value] = false; 
    }
    
    try {
      final existingBasics = await inputState.fetchInputFromLocal('basics');
      if (existingBasics != null && existingBasics is List) {
        for (String selectedValue in existingBasics) {
          if (basicsSelected.containsKey(selectedValue)) {
            basicsSelected[selectedValue] = true;
          }
        }
      }
      
      final existingRelType = await inputState.fetchInputFromLocal('relationshipType');
      if (existingRelType != null && existingRelType is List) {
        for (String selectedValue in existingRelType) {
          if (relationshipTypeSelected.containsKey(selectedValue)) {
            relationshipTypeSelected[selectedValue] = true;
          }
        }
      }
    } catch (e) {
      print('basics: Error loading existing values - $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    return {
      "basics": basicsSelected.entries
          .where((entry) => entry.value)  
          .map((entry) => entry.key)       
          .toList(),    
      "relationshipType": relationshipTypeSelected.entries
          .where((entry) => entry.value)  
          .map((entry) => entry.key)       
          .toList(),                 
    };
  }

  bool isFormComplete() {
    int basicsCount = basicsSelected.values.where((v) => v).length;
    int relTypeCount = relationshipTypeSelected.values.where((v) => v).length;
    return basicsCount == 1 && relTypeCount == 1;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What kind of relationship are you looking for?',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10.0, 
                      runSpacing: 10.0,
                      children: inputState.basics.isNotEmpty 
                      ? inputState.basics[0].possibleValues.map<Widget>((attribute) {
                          int selectedCount = basicsSelected.values.where((v) => v).length;
                          return SizedBox(
                            width: MediaQuery.of(context).size.width - 32, // Full width minus padding
                            child: CustomCheckbox(
                              attribute: CheckboxAttribute(
                                title: attribute,
                                description: '',
                                isSelected: basicsSelected[attribute] ?? false,
                              ),
                              isHorizontal: true,
                              maxSelections: 1,
                              currentSelectionCount: selectedCount,
                              onChanged: (isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    basicsSelected.updateAll((key, value) => false);
                                  }
                                  basicsSelected[attribute] = isSelected;
                                });
                              },
                              isSelected: basicsSelected[attribute] ?? false,
                            ),
                          );
                        }).toList()
                      : [],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'And in what partnership style?',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10.0, 
                      runSpacing: 10.0,
                      children: inputState.basics.isNotEmpty 
                      ? inputState.basics[1].possibleValues.map<Widget>((attribute) {
                          int selectedCount = relationshipTypeSelected.values.where((v) => v).length;
                          return SizedBox(
                            width: MediaQuery.of(context).size.width - 32, // Full width minus padding
                            child: CustomCheckbox(
                              attribute: CheckboxAttribute(
                                title: attribute,
                                description: '',
                                isSelected: relationshipTypeSelected[attribute] ?? false,
                              ),
                              isHorizontal: true,
                              maxSelections: 1, 
                              currentSelectionCount: selectedCount,
                              onChanged: (isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    relationshipTypeSelected.updateAll((key, value) => false);
                                  }
                                  relationshipTypeSelected[attribute] = isSelected;
                                });
                              },
                              isSelected: relationshipTypeSelected[attribute] ?? false,
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
              await inputState.saveInputToRemoteThenLocal(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {
              await inputState.saveInputToRemoteThenLocalInOnboarding(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.guideOnboardingNeeds);
              }
            }
          },
        );
      }(),
    );
  }
}