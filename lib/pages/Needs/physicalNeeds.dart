import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_slider.dart';
import '../../widgets/CustomRangeSlider.dart';
import '../../data/data_inputs.dart';
import '../../styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../widgets/profileLoop.dart';

class PhysicalNeeds extends StatefulWidget {
  const PhysicalNeeds({super.key, required this.title});
  final String title;
  @override
  State<PhysicalNeeds> createState() => _physicalNeeds();
}

class _physicalNeeds extends State<PhysicalNeeds> {
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

              Container(
                decoration: const BoxDecoration(color: ColorPalette.peach),
                child: Container (
                  decoration: const BoxDecoration(
                    color: ColorPalette.lite, 
                    borderRadius: BorderRadius.only(topRight: Radius.circular(30)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'What Physical Needs do you have from a partner?',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: ColorPalette.dark,
                          ),
                          textAlign: TextAlign.left,
                        ),
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
                              ] else if (input.type == "checkbox") ...[
                                CheckboxListTile(
                                  title: Text(input.title),
                                  value: inputValues[input.title] == 1,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      inputValues[input.title] = value! ? 1 : 0;
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
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.chemistryNeeds,
        inputValues: inputValues,
        submitToFirestore: false,
      ),
    );
  }
}
