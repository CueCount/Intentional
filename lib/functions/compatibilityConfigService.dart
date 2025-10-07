class MatchingConfig {  

  /* = = = = = = = = =
  Category Weights
  = = = = = = = = = */

  // Category weights (must sum to 1.0)
  static const Map<String, double> categoryWeights = {
    'chemistry': 0.30,
    'personality': 0.25,
    'interests': 0.25,
    'goals': 0.20,
  };
  
  // Scoring thresholds
  static const Map<String, double> scoringThresholds = {
    'minimum_match_percentage': 40,
    'good_match': 70,
    'great_match': 85,
    'excellent_match': 95,
  };

  /* = = = = = = = = =
  Specific Category Selection Weights
  = = = = = = = = = */
  
  // Chemistry compatibility matrix
  static const Map<String, Map<String, double>> chemistryMatrix = {
    'Best Friends': {
      'Best Friends': 0.8,
      'Power Couple': 0.5,
      'The Provider and Provided For': 0.3,
      'Romantic Lovers': 0.9,
      'Feisty Sex Freaks': 0.6,
      'Wanderlust Explorers': 0.95,
    },
    'Power Couple': {
      'Best Friends': 0.5,
      'Power Couple': 0.85,
      'The Provider and Provided For': 0.9,
      'Romantic Lovers': 0.4,
      'Feisty Sex Freaks': 0.7,
      'Wanderlust Explorers': 0.6,
    },
    'The Provider and Provided For': {
      'Best Friends': 0.3,
      'Power Couple': 0.9,
      'The Provider and Provided For': 0.7,
      'Romantic Lovers': 0.6,
      'Feisty Sex Freaks': 0.5,
      'Wanderlust Explorers': 0.4,
    },
    'Romantic Lovers': {
      'Best Friends': 0.9,
      'Power Couple': 0.4,
      'The Provider and Provided For': 0.6,
      'Romantic Lovers': 0.95,
      'Feisty Sex Freaks': 0.8,
      'Wanderlust Explorers': 0.7,
    },
    'Feisty Sex Freaks': {
      'Best Friends': 0.6,
      'Power Couple': 0.7,
      'The Provider and Provided For': 0.5,
      'Romantic Lovers': 0.8,
      'Feisty Sex Freaks': 0.9,
      'Wanderlust Explorers': 0.75,
    },
    'Wanderlust Explorers': {
      'Best Friends': 0.95,
      'Power Couple': 0.6,
      'The Provider and Provided For': 0.4,
      'Romantic Lovers': 0.7,
      'Feisty Sex Freaks': 0.75,
      'Wanderlust Explorers': 0.9,
    },
  };
  
  // Personality compatibility matrix
  static const Map<String, Map<String, double>> personalityMatrix = {
    'High Empathy and Sensitivity': {
      'High Empathy and Sensitivity': 0.7,
      'Exceptionally Proactive, Takes Action': 0.85,
      'Introspective and Self Aware': 0.9,
      'Socially Commanding and Experienced': 0.6,
      'Sweet, Romantic, and Affectionate': 0.95,
      'Book Smart and Highly Intelligent': 0.75,
    },
    'Exceptionally Proactive, Takes Action': {
      'High Empathy and Sensitivity': 0.85,
      'Exceptionally Proactive, Takes Action': 0.6,
      'Introspective and Self Aware': 0.7,
      'Socially Commanding and Experienced': 0.8,
      'Sweet, Romantic, and Affectionate': 0.7,
      'Book Smart and Highly Intelligent': 0.75,
    },
    'Introspective and Self Aware': {
      'High Empathy and Sensitivity': 0.9,
      'Exceptionally Proactive, Takes Action': 0.7,
      'Introspective and Self Aware': 0.75,
      'Socially Commanding and Experienced': 0.5,
      'Sweet, Romantic, and Affectionate': 0.8,
      'Book Smart and Highly Intelligent': 0.9,
    },
    'Socially Commanding and Experienced': {
      'High Empathy and Sensitivity': 0.6,
      'Exceptionally Proactive, Takes Action': 0.8,
      'Introspective and Self Aware': 0.5,
      'Socially Commanding and Experienced': 0.7,
      'Sweet, Romantic, and Affectionate': 0.65,
      'Book Smart and Highly Intelligent': 0.7,
    },
    'Sweet, Romantic, and Affectionate': {
      'High Empathy and Sensitivity': 0.95,
      'Exceptionally Proactive, Takes Action': 0.7,
      'Introspective and Self Aware': 0.8,
      'Socially Commanding and Experienced': 0.65,
      'Sweet, Romantic, and Affectionate': 0.85,
      'Book Smart and Highly Intelligent': 0.75,
    },
    'Book Smart and Highly Intelligent': {
      'High Empathy and Sensitivity': 0.75,
      'Exceptionally Proactive, Takes Action': 0.75,
      'Introspective and Self Aware': 0.9,
      'Socially Commanding and Experienced': 0.7,
      'Sweet, Romantic, and Affectionate': 0.75,
      'Book Smart and Highly Intelligent': 0.8,
    },
  };
  
  // Interest scoring tiers
  static const Map<String, double> interestScoringTiers = {
    '0_matches': 0.0,
    '1_match': 0.3,
    '2_matches': 0.5,
    '3_matches': 0.7,
    '4_matches': 0.85,
    '5_plus_matches': 1.0,
  };
  
  // Goals scoring tiers
  static const Map<String, double> goalsScoringTiers = {
    '0_matches': 0.0,
    '1_match': 0.4,
    '2_matches': 0.7,
    '3_plus_matches': 1.0,
  };
  
  // Goals compatibility groups
  static const double goalsGroupBonus = 0.15;
  
  static const List<String> financialFocusedGoals = [
    'Own a Nice Home, Car, and Toys',
    'Maximize Financial Security',
    'Build a Business, An Empire',
  ];
  
  static const List<String> freedomFocusedGoals = [
    'Travel Frequently and Extensively',
    'Maximize Freedom and Flexibility',
    'Pursue Our Craziest Dreams',
  ];
  
  /* = = = = = = = = =
  Helpers
  = = = = = = = = = */

  // Helper function to get chemistry score
  static double getChemistryScore(String trait1, String trait2) {
    return chemistryMatrix[trait1]?[trait2] ?? 
           chemistryMatrix[trait2]?[trait1] ?? 
           0.0;
  }
  
  // Helper function to get personality score
  static double getPersonalityScore(String trait1, String trait2) {
    return personalityMatrix[trait1]?[trait2] ?? 
           personalityMatrix[trait2]?[trait1] ?? 
           0.0;
  }
  
  // Helper function to get interest score based on match count
  static double getInterestScore(int matchCount) {
    if (matchCount == 0) return interestScoringTiers['0_matches']!;
    if (matchCount == 1) return interestScoringTiers['1_match']!;
    if (matchCount == 2) return interestScoringTiers['2_matches']!;
    if (matchCount == 3) return interestScoringTiers['3_matches']!;
    if (matchCount == 4) return interestScoringTiers['4_matches']!;
    return interestScoringTiers['5_plus_matches']!;
  }
  
  // Helper function to get goals score based on match count
  static double getGoalsBaseScore(int matchCount) {
    if (matchCount == 0) return goalsScoringTiers['0_matches']!;
    if (matchCount == 1) return goalsScoringTiers['1_match']!;
    if (matchCount == 2) return goalsScoringTiers['2_matches']!;
    return goalsScoringTiers['3_plus_matches']!;
  }
  
  // Helper function to check if goals are in same group
  static bool areGoalsInSameGroup(List<String> userGoals, List<String> matchGoals) {
    bool userFinancial = userGoals.any((g) => financialFocusedGoals.contains(g));
    bool matchFinancial = matchGoals.any((g) => financialFocusedGoals.contains(g));
    
    bool userFreedom = userGoals.any((g) => freedomFocusedGoals.contains(g));
    bool matchFreedom = matchGoals.any((g) => freedomFocusedGoals.contains(g));
    
    return (userFinancial && matchFinancial) || (userFreedom && matchFreedom);
  }
  
  /* = = = = = = = = =
  Overall Match Quality
  = = = = = = = = = */

  // Get match quality label
  static String getMatchQuality(double percentage) {
    if (percentage >= scoringThresholds['excellent_match']!) {
      return 'Excellent Match';
    } else if (percentage >= scoringThresholds['great_match']!) {
      return 'Great Match';
    } else if (percentage >= scoringThresholds['good_match']!) {
      return 'Good Match';
    } else if (percentage >= scoringThresholds['minimum_match_percentage']!) {
      return 'Match';
    }
    return 'Low Match';
  }

}