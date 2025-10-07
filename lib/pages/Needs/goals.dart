import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/inputCheckbox.dart';  
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
class Goals extends StatefulWidget {
  const Goals({super.key});
  @override
  State<Goals> createState() => _goals();
}

class _goals extends State<Goals> {
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
    for (var input in inputState.lifeGoalNeeds) {
      for (var value in input.possibleValues) {
        selectedValues[value] = false; 
      }
    }
    
    try {
      // Get existing life goal needs from provider
      final existingLifeGoalNeeds = await inputState.getInput('LifeGoalNeed');
      
      if (existingLifeGoalNeeds != null && existingLifeGoalNeeds is List) {
        // Mark existing selections as true
        for (String selectedValue in existingLifeGoalNeeds) {
          if (selectedValues.containsKey(selectedValue)) {
            selectedValues[selectedValue] = true;
          }
        }
      }
    } catch (e) {
      print('Goals: Error loading existing values - $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    return {
      "LifeGoalNeed": selectedValues.entries
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
    final inputState = Provider.of<InputState>(context, listen: false);
    Map<String, dynamic> inputData = getSelectedAttributes();
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
                      'Goals',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 10.0, // horizontal spacing between items
                      runSpacing: 10.0, // vertical spacing between rows
                      children: inputState.lifeGoalNeeds.isNotEmpty 
                        ? inputState.lifeGoalNeeds[0].possibleValues.map<Widget>((attribute) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width - 32, // Full width minus padding
                              child: CustomCheckbox(
                                attribute: CheckboxAttribute(
                                  title: attribute,
                                  description: '',  
                                  isSelected: selectedValues[attribute] ?? false,
                                ),
                                isHorizontal: true, // Horizontal layout for single column
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
                Navigator.pushNamed(context, AppRoutes.guideAvailableMatches);
              }
            }
          },
        );
      }(),
    );
  }
}