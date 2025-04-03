import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/input_checkbox.dart';
import '../../data/inputState.dart';
import '../../styles.dart';
import '../../functions/airTrafficControler_service.dart';
import '../../widgets/navigation.dart';

class LogisticNeeds extends StatefulWidget {
  const LogisticNeeds({super.key, required this.title});
  final String title;
  @override
  State<LogisticNeeds> createState() => _logisticNeeds();
}

class _logisticNeeds extends State<LogisticNeeds> {
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
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
        child: Column(
          children: [
            const CustomStatusBar(
              messagesCount: 2,
              likesCount: 5,
            ),
            Text(
              'Interests',
              style: AppTextStyles.headingMedium.copyWith(
                color: ColorPalette.dark,
              ),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),
            // Wrapping GridView in Expanded allows scrolling
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(), // Enable scrolling
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 3,
                ),
                itemCount: inputState.logisticNeeds.isNotEmpty
                    ? inputState.logisticNeeds[0].possibleValues.length
                    : 0,
                itemBuilder: (context, index) {
                  if (inputState.logisticNeeds.isEmpty ||
                      index >= inputState.logisticNeeds[0].possibleValues.length) {
                    return const SizedBox.shrink();
                  }
                  String attribute = inputState.logisticNeeds[0].possibleValues[index];
                  return CustomCheckbox(
                    attribute: CheckboxAttribute(
                      title: attribute,
                      description: '',
                      isSelected: selectedValues[attribute] ?? false,
                    ),
                    onChanged: (isSelected) {
                      setState(() {
                        selectedValues[attribute] = isSelected;
                      });
                    },
                    isSelected: selectedValues[attribute] ?? false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: CustomAppBar(
      onPressed: () async {
        final inputData = inputValues;
        await AirTrafficController().addedNeed(context, inputData);
        if (context.mounted) {
          Navigator.pushNamed(context, AppRoutes.lifeGoalNeeds, arguments: inputData);
        }
      },
    ),
  );
}

}
