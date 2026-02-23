import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/inputCheckbox.dart';  
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
class Relationship extends StatefulWidget {
  const Relationship({super.key});
  @override
  State<Relationship> createState() => _relationship();
}

class _relationship extends State<Relationship> {
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
    for (var input in inputState.relationship) {
      for (var value in input.possibleValues) {
        selectedValues[value] = false; 
      }
    }
    
    try {
      // Get existing chemistry needs from provider
      final existingRelationship = await inputState.fetchInputFromLocal('relationship');
      
      if (existingRelationship != null && existingRelationship is List) {
        // Mark existing selections as true
        for (String selectedValue in existingRelationship) {
          if (selectedValues.containsKey(selectedValue)) {
            selectedValues[selectedValue] = true;
          }
        }
      }
    } catch (e) {
      print('Relationship: Error loading existing values - $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    return {
      "relationship": selectedValues.entries
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
    final inputState = Provider.of<InputState>(context, listen: false);
    Map<String, dynamic> inputData = getSelectedAttributes();
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
                      'Prioritize 5 Expectations You Have of a Relationship',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),

                    const SizedBox(height: 30),
                    
                    Wrap(
                      spacing: 10.0, // horizontal spacing between items
                      runSpacing: 10.0, // vertical spacing between rows
                      alignment: WrapAlignment.start,
                      children: inputState.relationship.isNotEmpty 
                        ? inputState.relationship[0].possibleValues.map<Widget>((attribute) {
                            int selectedCount = selectedValues.values.where((v) => v).length;
                            return SizedBox(
                              width: double.infinity,  // Add this
                              child: CustomCheckbox(
                                attribute: CheckboxAttribute(
                                  title: attribute,
                                  description: '',  
                                  isSelected: selectedValues[attribute] ?? false,
                                ),
                                isHorizontal: true,
                                shrinkWrap: true, 
                                maxSelections: 5, 
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
              await inputState.saveInputToRemoteThenLocal(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {
              await inputState.saveInputToRemoteThenLocalInOnboarding(inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.interests);
              }
            }
          },
        );
        
      }(),
    );
  }
}