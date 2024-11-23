import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_checkbox.dart';  
import '../../data/data_inputs.dart';
import '../../styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChemistryNeeds extends StatefulWidget {
  const ChemistryNeeds({super.key, required this.title});
  final String title;
  @override
  State<ChemistryNeeds> createState() => _chemistryNeeds();
}

class _chemistryNeeds extends State<ChemistryNeeds> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, dynamic> inputValues = {};
  Map<String, bool> selectedValues = {};
  @override
  void initState() {
    super.initState();
    for (var input in chemistryNeeds) {
      for (var value in input.possibleValues) {
        selectedValues[value] = false;
      }
    }
  }

  Map<String, dynamic> getSelectedAttributes() {
    return {
      "ChemistryNeed": selectedValues.entries
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
    Map<String, dynamic> inputData = getSelectedAttributes();
    return Scaffold(
      endDrawer: const CustomDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          Container(
                            width: 250,  
                            height: 60,
                            decoration: const BoxDecoration(
                              // Optional decoration for visualizing the container
                            ),
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
                          'What Chemistry Qualities matter most to you?',
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
                            itemCount: chemistryNeeds.isNotEmpty ? chemistryNeeds[0].possibleValues.length : 0,
                            itemBuilder: (context, index) {
                              if (chemistryNeeds.isEmpty || index >= chemistryNeeds[0].possibleValues.length) {
                                return const SizedBox.shrink();
                              }
                              String attribute = chemistryNeeds[0].possibleValues[index];
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
              ),
            ],
          ),
        ),
      ),
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.logisticNeeds, 
        inputValues: inputData,
      ),
    );
  }
}
