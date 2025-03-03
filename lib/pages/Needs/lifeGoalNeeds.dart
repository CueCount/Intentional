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

class LifeGoalNeeds extends StatefulWidget {
  const LifeGoalNeeds({super.key, required this.title});
  final String title;
  @override
  State<LifeGoalNeeds> createState() => _lifeGoalNeeds();
}

class _lifeGoalNeeds extends State<LifeGoalNeeds> {
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
                            left: 16.0,
                            top: 16.0,
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


              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'What Life Goals do you prioritize in a partner?',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.dark,
                      ),
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: inputState.lifeGoalNeeds.isNotEmpty ? inputState.lifeGoalNeeds[0].possibleValues.length : 0,
                        itemBuilder: (context, index) {
                          if (inputState.lifeGoalNeeds.isEmpty || index >= inputState.lifeGoalNeeds[0].possibleValues.length) {
                            return const SizedBox.shrink();
                          }
                          String attribute = inputState.lifeGoalNeeds[0].possibleValues[index];
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
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.register, 
        inputValues: inputData,
      ),
    );
  }
}
