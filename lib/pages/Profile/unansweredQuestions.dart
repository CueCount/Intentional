import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../providers/inputState.dart';
import '../../widgets/navigation.dart';
import '../../styles.dart';
import '../../router/router.dart';

class UnansweredQuestionsPage extends StatefulWidget {
  const UnansweredQuestionsPage({super.key});

  @override
  State<UnansweredQuestionsPage> createState() => _UnansweredQuestionsPageState();
}

class _UnansweredQuestionsPageState extends State<UnansweredQuestionsPage> {
  List<Map<String, dynamic>> _missingInputs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMissingInputs();
  }

  Future<void> _loadMissingInputs() async {

    print('🔄 _loadMissingInputs started');
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      // Get all saved inputs from SharedPreferences
      final savedInputs = await inputState.fetchInputsFromLocal();
      
      // Define all input types to check
      final Map<String, List<Input>> additionalInputs = {
        'personalityQ1': inputState.personalityQ1,
        'personalityQ2': inputState.personalityQ2,
        'personalityQ3': inputState.personalityQ3,
        'personalityQ4': inputState.personalityQ4,
        'relationshipQ1': inputState.relationshipQ1,
        'relationshipQ2': inputState.relationshipQ2,
        'relationshipQ3': inputState.relationshipQ3,
        'relationshipQ4': inputState.relationshipQ4,
        
        'personality': inputState.personality,
        'relationship': inputState.relationship,
        'interests': inputState.interests,
        'lifeGoalNeeds': inputState.lifeGoalNeeds,
      };
      
      // Find inputs that are not in saved data
      List<Map<String, dynamic>> missingInputs = [];

      for (var entry in additionalInputs.entries) {
        String inputName = entry.key;
        List<Input> inputList = entry.value;
        
        // Check if not saved or empty
        if (!savedInputs.containsKey(inputName) || 
            (savedInputs[inputName] is List && (savedInputs[inputName] as List).isEmpty)) {
          
          if (inputList.isNotEmpty) {
            Input input = inputList[0];
            missingInputs.add({
              'type': 'input',
              'inputName': inputName,
              'title': input.title,
              'possibleValues': input.possibleValues,
              'nextRoute': AppRoutes.matches,
            });
          }
        }
      }
      
      print('🔄 Got ${missingInputs.length} missing inputs');
    
      // THIS IS WHAT WAS MISSING:
      setState(() {
        _missingInputs = missingInputs;
        _isLoading = false;
      });
    
    } catch (e) {
      print('Error getting missing inputs: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build carousel items: all input cards + final "back to matches" card
    List<Widget> carouselItems = [];
    
    for (var input in _missingInputs) {
      carouselItems.add(_buildInputCard(input, context));
    }
    
    carouselItems.add(_buildBackToMatchesCard(context));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomStatusBar(),
            Expanded(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 600,
                  autoPlay: false,
                  enlargeCenterPage: true,
                  enableInfiniteScroll: false,
                ),
                items: carouselItems,
              ),
            ),
          ],
        ),
      ),
    );
  
  }

  Widget _buildInputCard(Map<String, dynamic> input, BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          color: ColorPalette.lite,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get better matches',
                style: AppTextStyles.bodySmall.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 16,
                ),
              ),
              Text(
                input['title'] ?? 'Question',
                style: AppTextStyles.headingLarge.copyWith(
                  color: ColorPalette.peach,
                  fontSize: 32,
                ),
              ),
              Text(
                ' ',
                style: TextStyle(
                  color: ColorPalette.peach,
                  fontSize: 24,
                ),
              ),
              SizedBox(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.input,
                      arguments: {
                        'inputName': input['inputName'],
                        'nextRoute': AppRoutes.unansweredQuestions,
                      },
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    overlayColor: Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Respond',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.arrow_forward,
                        color: ColorPalette.peach,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackToMatchesCard(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorPalette.peach,
              ColorPalette.violet,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Great Progress!',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                ),
              ),

              const Spacer(),

              Text(
                'Your answers help us find better matches for you.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.matches,
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ColorPalette.peach,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Back to Matches',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: ColorPalette.peach,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: ColorPalette.peach,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}