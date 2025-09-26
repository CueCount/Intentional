import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/inputCheckbox.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../functions/onboardingService.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../functions/uiService.dart';

class Interests extends StatefulWidget {
  const Interests({super.key});
  @override
  State<Interests> createState() => _interests();
}

class _interests extends State<Interests> {
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
    for (var input in inputState.logisticNeeds) {
      for (var value in input.possibleValues) {
        selectedValues[value] = false; 
      }
    }
    
    try {
      // Get existing logistics/interests from provider using new array format
      final existingLogisticNeeds = await inputState.getInput('LogisticNeed');
      
      if (existingLogisticNeeds != null && existingLogisticNeeds is List) {
        // Mark existing selections as true
        for (String selectedValue in existingLogisticNeeds) {
          if (selectedValues.containsKey(selectedValue)) {
            selectedValues[selectedValue] = true;
          }
        }
      } else {
        // If LogisticNeed array doesn't exist, this might be a new user
        // Just start with all false values (already initialized above)
        print('Interests: No existing LogisticNeed array found, starting fresh');
      }
    } catch (e) {
      print('Interests: Error loading existing values - $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    return {
      "LogisticNeed": selectedValues.entries
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
  final inputState = Provider.of<InputState>(context);
  return Scaffold(
    body: SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const CustomStatusBar(),
            Container(
              padding: const EdgeInsets.all(16), // Add some padding around the content
              child: Column(
                children: [
                  Text(
                    'Interests',
                    style: AppTextStyles.headingLarge.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10.0, // horizontal spacing between items
                    runSpacing: 10.0, // vertical spacing between rows
                    children: inputState.logisticNeeds.isNotEmpty
                        ? inputState.logisticNeeds[0].possibleValues.map<Widget>((attribute) {
                            return SizedBox(
                              width: (MediaQuery.of(context).size.width - 42) / 2, // 2 columns with padding and spacing
                              child: CustomCheckbox(
                                attribute: CheckboxAttribute(
                                  title: attribute,
                                  description: '',
                                  isSelected: selectedValues[attribute] ?? false,
                                ),
                                isHorizontal: true, 
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
        return CustomAppBar(
          buttonText: isLoggedIn ? 'Save' : 'Continue',
          buttonIcon: isLoggedIn ? Icons.save : Icons.arrow_forward,
          onPressed: () async {
            if (isLoggedIn) {
              
              await inputState.saveNeedLocally(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {

              await inputState.saveNeedLocally(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.goals);
              }
            }
          },
        );
      }(),
    );
  }
}