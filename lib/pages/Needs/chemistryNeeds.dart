import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/input_checkbox.dart';  
import '../../data/data_inputs.dart';
import '../../styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/navigation.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inputState = Provider.of<InputState>(context, listen: false); 
      for (var input in inputState.chemistryNeeds) {
        for (var value in input.possibleValues) {
          selectedValues[value] = false; 
        }
      }
      setState(() {});
    });
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
    final inputState = Provider.of<InputState>(context);
    Map<String, dynamic> inputData = getSelectedAttributes();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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

              Container (
                child: Container (
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Text(
                          'Relationship Type',
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
                              crossAxisCount: 1,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 5.0,
                            ),
                            itemCount: inputState.chemistryNeeds.isNotEmpty ? inputState.chemistryNeeds[0].possibleValues.length : 0,
                            itemBuilder: (context, index) {
                              if (inputState.chemistryNeeds.isEmpty || index >= inputState.chemistryNeeds[0].possibleValues.length) {
                                return const SizedBox.shrink();
                              }
                              String attribute = inputState.chemistryNeeds[0].possibleValues[index];
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
