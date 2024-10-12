import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_slider.dart';
import '../../controllers/data_functions.dart';
import '../../controllers/data_object.dart';
import '../../controllers/data_inputs.dart';

class Logistics extends StatefulWidget {
  const Logistics({super.key, required this.title});
  final String title;
  @override
  State<Logistics> createState() => _Logistics();
}

class _Logistics extends State<Logistics> {
  /* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  VALUES
   - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */
  Map<String, double> inputValues = {};
  DataService dataService = DataService();
  @override
  void initState() {
    super.initState();
    for (var input in logisticsInputs) {
      inputValues[input.title] = input.possibleValues[1]; // Set initial value to the midpoint
    }
  }

  @override
  Widget build(BuildContext context) { 

    return Scaffold( 
      appBar: CustomAppBar(
        title: widget.title,
        isLoggedIn: true,
        hasSubmittedForm: true,
      ),
      endDrawer: CustomDrawer(), 
      body: ListView(
        children: <Widget>[
          for (var input in logisticsInputs)
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

          MaterialButton(
            onPressed: () {
              DynamicData data = DynamicData(inputValues: inputValues);
              dataService.handleSubmit(data);
              Navigator.pushNamed(context, AppRoutes.labor);
            },
            child: const Text('Continue'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),

    );

  }
}
