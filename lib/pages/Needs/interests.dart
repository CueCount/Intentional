import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/input_checkbox.dart';
import '../../data/inputState.dart';
import '../../styles.dart';
import '../../functions/onboardingService.dart';
import '../../widgets/navigation.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inputState = Provider.of<InputState>(context, listen: false); 
      for (var input in inputState.logisticNeeds) {
        for (var value in input.possibleValues) {
          selectedValues[value] = false; 
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
                                isHorizontal: false, // Keep vertical layout for 2-column grid
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
        final inputData = selectedValues;
        await AirTrafficController().saveNeedInOnboardingFlow(context, inputData);
        if (context.mounted) {
          Navigator.pushNamed(context, AppRoutes.goals, arguments: inputData);
        }
      },
    ),
  );
}

}