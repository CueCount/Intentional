import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_slider.dart'; 
import '../../controllers/data_functions.dart';
import '../../controllers/data_object.dart';
import '../../controllers/data_inputs.dart';

class EmotionalDynamic extends StatefulWidget {
  const EmotionalDynamic({super.key, required this.title});
  final String title;
  @override
  State<EmotionalDynamic> createState() => _EmotionalDynamic();
}

class _EmotionalDynamic extends State<EmotionalDynamic> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, double> inputValues = {};
  DataService dataService = DataService();
  @override
  void initState() {
    super.initState();
    for (var input in emotionalInputs) {
      inputValues[input.title] = (input.possibleValues[0] + input.possibleValues[1]) / 2; // Set initial value to the midpoint
    }
  }

  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  SCAFFOLD
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  @override
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: CustomAppBar(title: widget.title, isLoggedIn: true, hasSubmittedForm: true,),
      endDrawer: CustomDrawer(), 
      body: ListView(
        children: <Widget>[
          for (var input in emotionalInputs)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(input.title), 
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
                ],
              ], // Children
            ),

          /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
          Submit
           - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
          MaterialButton(
            onPressed: () {
              DynamicData data = DynamicData(inputValues: inputValues);
              dataService.handleSubmit(data);
              Navigator.pushNamed(context, AppRoutes.status);
            },
            child: const Text('Continue'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),
    );
  }
}
