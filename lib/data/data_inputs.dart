import 'package:flutter/foundation.dart';

class Input {
  final String title;
  final List<dynamic> possibleValues; 
  final String type;
  dynamic currentValue;
  Input({
    required this.title, 
    required this.possibleValues, 
    required this.type, 
    this.currentValue,
  });
  Map<String, dynamic> toJson() {
    return {'Title': title, 'PossibleValues': possibleValues, 'Type': type, };
  }
  factory Input.fromJson(Map<String, dynamic> json) {
    return Input(title: json['Title'], possibleValues: List<int>.from(json['PossibleValues']), type: json['Type'],);
  }
}
class InputState extends ChangeNotifier {
  Map<String, dynamic> _cachedInputs = {}; // Local cache for inputs
  // Cache inputs locally
  void cacheInputs(Map<String, dynamic> inputs) {
    _cachedInputs.addAll(inputs); 
    print('Cached Inputs: $_cachedInputs');
    notifyListeners(); 
  }
  // Retrieve cached inputs
  Map<String, dynamic> getCachedInputs() {
    return _cachedInputs;
  }
  // Clear cached inputs (if needed)
  void clearCachedInputs() {
    _cachedInputs.clear();
    notifyListeners();
  }

  List<Input> qual = [
    Input(
      title: "Gender",
      possibleValues: [
        "Man",
        "Woman",
      ],
      type: "checkbox"),

    Input(
      title: "Seeking",
      possibleValues: [
        "Man",
        "Woman",
      ],
      type: "checkbox"),
  ];

  List<Input> location = [
    Input(
      title: "Location",
      possibleValues: [],
      type: "geopoint",)
  ];

  List<Input> emotionalNeeds = [
    Input(
      title: "Emotional Needs",
      possibleValues: [
        "High Empathy and Sensitivity",
        "Exceptionally Proactive, Takes Action",
        "Introspective and Self Aware",
        "Socially Commanding and Experienced",
        "Sweet, Romantic, and Affectionate",
        "Book Smart and Highly Intelligent"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> physicalNeeds = [
    Input(
      title: "How Tall?",
      possibleValues: [0, 100],
      type: "rangeSlider",
    ),
    Input(
      title: "Body Type?",
      possibleValues: [0, 100],
      type: "rangeSlider",
    ),
    Input(
      title: "Muscles?",
      possibleValues: [0, 100],
      type: "rangeSlider",
    ),
    Input(
      title: "Age?",
      possibleValues: [0, 100],
      type: "rangeSlider",
    ),
  ];

  List<Input> chemistryNeeds = [
    Input(
      title: "Chemistry Needs",
      possibleValues: [
        "Best Friends",
        "Power Couple",
        "The Provider and Provided For",
        "Romantic Lovers",
        "Feisty Sex Freaks",
        "Wanderlust Explorers"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> logisticNeeds = [
    Input(
      title: "How much time per week should you spend together in a committed relationship?",
      possibleValues: [0, 100],
      type: "slider",
    ),
    Input(
      title: "Who should do more chores?",
      possibleValues: [0, 100],
      type: "slider",
    ),
    Input(
      title: "Who should earn (significantly) more?",
      possibleValues: [0, 100],
      type: "slider",
    ),
    Input(
      title: "How often should each partner plan dates, trips and other events together?",
      possibleValues: [0, 100],
      type: "slider",
    ),
  ];

  List<Input> lifeGoalNeeds = [
    Input(
      title: "Prompts",
      possibleValues: [
        "Travel Frequently and Extensively",
        "Own a Nice Home, Car, and Toys",
        "Maximize Freedom and Flexibility",
        "Maximize Financial and Retirement Security",
        "Build a Business, An Empire",
        "Be Supported While You Pursue Your Dream"
      ],
      type: "checkbox"
    ),
  ];

  List<Input> prompts = [
    Input(
      title: "Prompts",
      possibleValues: [
        "Your favorite band",
        "Your favorite travel destination",
        "Your typical weekend",
        "Your favorite car you owned",
        "Dream home location",
      ],
      type: "text"
    ),
  ];
}