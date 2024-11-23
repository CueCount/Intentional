import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '/router/router.dart';
import '../../data/data_inputs.dart';
import '../../widgets/input_text.dart';

class PromptsPage extends StatefulWidget {
  const PromptsPage({Key? key}) : super(key: key);
  @override
  State<PromptsPage> createState() => _PromptsPageState();
}

class _PromptsPageState extends State<PromptsPage> {
  final Map<String, TextEditingController> _controllers = {};
  @override
  void initState() {
    super.initState();
    for (var input in prompts) {  
      for (var value in input.possibleValues) {
        _controllers[value] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  int get filledPromptsCount {
    return _controllers.values
        .where((controller) => controller.text.isNotEmpty)
        .length;
  }

  Map<String, dynamic> getInputData() {
    Map<String, dynamic> filledPrompts = {};
    _controllers.forEach((prompt, controller) {
      if (controller.text.isNotEmpty) {
        filledPrompts[prompt] = controller.text;
      }
    });
    return {'prompts': filledPrompts};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: CustomDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Life',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      'Fill out at least 3',
                      style: TextStyle(
                        color: filledPromptsCount >= 3 ? Colors.green : Colors.black,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.edit,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: prompts[0].possibleValues.length,
                  itemBuilder: (context, index) {
                    final prompt = prompts[0].possibleValues[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomTextInput(
                          labelText: prompt,
                          controller: _controllers[prompt]!,
                          suffixIcon: Icon(
                            Icons.edit,
                            color: Colors.grey.shade400,
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (filledPromptsCount > 5)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Please select no more than 5 prompts',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.match,
        inputValues: filledPromptsCount >= 3 && filledPromptsCount <= 5 
            ? getInputData() 
            : null,
      ),
    );
  }
}