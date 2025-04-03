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

class InputPhoto {
  final String base64Data;
  final String? localUrl;
  final String? firestoreUrl;
  final String filename;

  InputPhoto({
    required this.base64Data,
    this.localUrl,
    this.firestoreUrl,
    required this.filename,
  });

  Map<String, dynamic> toJson() => {
    'base64Data': base64Data,
    'localUrl': localUrl,
    'firestoreUrl': firestoreUrl,
    'filename': filename,
  };
}

class InputState extends ChangeNotifier {
  Map<String, dynamic> _cachedInputs = {};
  String _userId = '';
  String get userId => _userId;

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }
  
  void cacheInputs(Map<String, dynamic> data) {
    _cachedInputs.addAll(data);
    notifyListeners();
  }
  
  Map<String, dynamic> getCachedInputs() {
    return _cachedInputs;
  }

  List<Input> basicInfo = [
    Input(
      title: "nameFirst",
      possibleValues: [],
      type: "text",),
    
    Input(
      title: "birthDate",
      possibleValues: [],
      type: "calendar",),
  ];

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
      title: "Chemistry Needs",
      possibleValues: [
        "Bar Hopping",
        "Playing Sports",
        "Foodie",
        "Arts and Crafts",
        "Binge Watching",
        "Gaming",
        "Music",
        "Nature",
        "Traveling",
        "Reading",
        "Cooking",
        "Shopping",
        "Volunteering",
        "Fitness",
        "Meditation",
      ],
      type: "checkbox"
    ),
  ];

  List<Input> lifeGoalNeeds = [
    Input(
      title: "Prompts",
      possibleValues: [
        "Travel Frequently and Extensively",
        "Own a Nice Home, Car, and Toys",
        "Maximize Freedom and Flexibility",
        "Maximize Financial Security",
        "Build a Business, An Empire",
        "Pursue Our Craziest Dreams"
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

  List<InputPhoto> photoInputs = [];

}