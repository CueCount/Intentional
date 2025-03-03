import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_checkbox.dart';  
import '../../data/data_inputs.dart';
import '../../styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/profileLoop.dart';

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
      endDrawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: ColorPalette.peachGradient,
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 16,
                            top: 16,
                            child: SvgPicture.asset(
                              'lib/assets/Int.svg',
                              height: 20,
                              width: 20,
                            ),
                          ),
                          const Align(
                            alignment: Alignment.topCenter,
                            child: ProfileGrid(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container (
                decoration: const BoxDecoration(color: ColorPalette.peach),
                child: Container (
                  decoration: const BoxDecoration(
                    color: ColorPalette.lite, 
                    borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'What Emotional Qualities do you prioritize in a partner?',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: ColorPalette.dark,
                          ),
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 20), // Adjust this value for desired spacing
                        GridView.builder(
                          shrinkWrap: true, // Important!
                          physics: const NeverScrollableScrollPhysics(), // Important!
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: inputState.emotionalNeeds.isNotEmpty ? inputState.emotionalNeeds[0].possibleValues.length : 0,
                          itemBuilder: (context, index) {
                            if (inputState.emotionalNeeds.isEmpty || index >= inputState.emotionalNeeds[0].possibleValues.length) {
                              return const SizedBox.shrink();
                            }
                            String attribute = inputState.emotionalNeeds[0].possibleValues[index];
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.physicalNeeds,
        inputValues: inputData,
        submitToFirestore: false,
      ),
    );
  }
}
