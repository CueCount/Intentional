import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/input_slider.dart';
import '../../widgets/CustomRangeSlider.dart';
import '../../data/inputState.dart';
import '../../functions/onboardingService.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../functions/userActionsService.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inputState = Provider.of<InputState>(context, listen: false); 
      for (var input in inputState.physicalNeeds) {
        for (var value in input.possibleValues) {
          selectedValues[value] = input.possibleValues[1].toDouble();
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) { 
    final inputState = Provider.of<InputState>(context);
    return Scaffold( 
      body: SafeArea(
        child: SingleChildScrollView(            
          child: Column(
            children: [
              const CustomStatusBar(messagesCount: 2,likesCount: 5,),
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
                              input.title, 
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: ColorPalette.dark,
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
              await UserActions().saveNeedLocally(context, inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.editNeeds, arguments: inputData);
              }
            } else {
              await AirTrafficController().saveNeedInOnboardingFlow(context, inputData);
              if (context.mounted) {
                Navigator.pushNamed(context, AppRoutes.relationship, arguments: inputData);
              }
            }
          },
        );
      }(),
    );
  }
}
