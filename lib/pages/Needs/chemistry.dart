import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/input_checkbox.dart';
import '../../data/inputState.dart';
import '../../styles.dart';
import '../../functions/airTrafficControler_service.dart';
import '../../widgets/navigation.dart';

class EmotionalNeeds extends StatefulWidget {
  const EmotionalNeeds({super.key, required this.title});
  final String title;
  @override
  State<EmotionalNeeds> createState() => _emotionalNeeds();
}

class _emotionalNeeds extends State<EmotionalNeeds> {
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
      for (var input in inputState.emotionalNeeds) {
        for (var value in input.possibleValues) {
          selectedValues[value] = false; 
        }
      }
      setState(() {});
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
              const CustomStatusBar(messagesCount: 2,likesCount: 5,),
              Container (
                padding: const EdgeInsets.all(16), // Add some padding around the content
                child: Column(
                  children: [
                    Text(
                      'Chemistry',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 10.0, // horizontal spacing between items
                      runSpacing: 10.0, // vertical spacing between rows
                      children: inputState.emotionalNeeds.isNotEmpty 
                        ? inputState.emotionalNeeds[0].possibleValues.map<Widget>((attribute) {
                            return SizedBox(
                              width: MediaQuery.of(context).size.width - 32, // Full width minus padding
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
      bottomNavigationBar: CustomAppBar(
        onPressed: () async {
          final inputData = getSelectedAttributes();
          await AirTrafficController().addedNeed(context, inputData);
          if (context.mounted) {
            final inputState = Provider.of<InputState>(context, listen: false);
            if (inputState.userId.isNotEmpty) {
              Navigator.pushNamed(context, AppRoutes.profile, arguments: inputData);
            } else {
              Navigator.pushNamed(context, AppRoutes.physicalNeeds, arguments: inputData);
            }
          }
        },
      ),
    );
  }
}