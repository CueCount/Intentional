import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/input_checkbox.dart';  
import '../../data/inputState.dart';
import '../../styles.dart';
import '../../functions/airTrafficControler_service.dart';
import '../../widgets/navigation.dart';

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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inputState = Provider.of<InputState>(context, listen: false); 
      for (var input in inputState.lifeGoalNeeds) {
        for (var value in input.possibleValues) {
          selectedValues[value] = false; 
        }
      }
      setState(() {});
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
    final inputState = Provider.of<InputState>(context);
    Map<String, dynamic> inputData = getSelectedAttributes();
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
      bottomNavigationBar: CustomAppBar(
        onPressed: () async {
          final inputData = getSelectedAttributes();
          await AirTrafficController().addedNeed(context, inputData);
          if (context.mounted) {
            Navigator.pushNamed(context, AppRoutes.matches, arguments: inputData);
          }
        },
      ),
    );
  }
}