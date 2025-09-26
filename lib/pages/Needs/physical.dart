import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/inputSlider.dart';
import '../../widgets/customRangeSlider.dart';
import '../../providers/inputState.dart';
import '../../functions/onboardingService.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../functions/uiService.dart';

class Physical extends StatefulWidget {
  const Physical({super.key});
  @override
  State<Physical> createState() => _physical();
}

class _physical extends State<Physical> {
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
    
    // Initialize with default values first
    for (var input in inputState.physicalNeeds) {
      if (input.type == "rangeSlider") {
        // Default to middle range
        double min = input.possibleValues[0].toDouble();
        double max = input.possibleValues[1].toDouble();
        inputValues[input.title] = [min + (max - min) * 0.25, min + (max - min) * 0.75];
      } else if (input.type == "slider") {
        // Default to middle value
        double min = input.possibleValues[0].toDouble();
        double max = input.possibleValues[1].toDouble();
        inputValues[input.title] = min + (max - min) * 0.5;
      }
    }
    
    try {
      // Get existing physical needs from provider
      for (var input in inputState.physicalNeeds) {
        final existingValue = await inputState.getInput(input.title);
        
        if (existingValue != null) {
          inputValues[input.title] = existingValue;
        }
      }
    } catch (e) {
      print('Physical: Error loading existing values - $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  Map<String, dynamic> getSelectedAttributes() {
    return inputValues;
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SCAFFOLD
  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

  @override
  Widget build(BuildContext context) { 
    final inputState = Provider.of<InputState>(context, listen: false);
    return Scaffold( 
      body: SafeArea(
        child: SingleChildScrollView(            
          child: Column(
            children: [
              const CustomStatusBar(),
              Container(
                child: Column(
                  children: <Widget>[
                    const SizedBox(height: 30),  
                    for (var input in inputState.physicalNeeds)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Physical',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.headingLarge.copyWith(
                                color: ColorPalette.peach,
                              ),
                            ),
                          ), 
                          if (input.type == "slider") ...[
                            CustomSlider(
                              label: input.title,
                              initialValue: inputValues[input.title]!,
                              min: input.possibleValues[0].toDouble(),
                              max: input.possibleValues[1].toDouble(),
                              divisions: 20,
                              onChanged: (value) {
                                setState(() {
                                  inputValues[input.title] = value; 
                                });
                              },
                            ),
                          ] else if (input.type == "rangeSlider") ...[
                            CustomRangeSlider(
                              label: input.title,
                              min: input.possibleValues[0].toDouble(),
                              max: input.possibleValues[1].toDouble(),
                              divisions: 20,
                              onChanged: (RangeValues value) {
                                setState(() {
                                  inputValues[input.title] = [value.start, value.end];
                                });
                              },
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
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
        final inputData = inputValues;
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
                Navigator.pushNamed(context, AppRoutes.relationship);
              }
            }
          },
        );
      }(),
    );
  }
}
