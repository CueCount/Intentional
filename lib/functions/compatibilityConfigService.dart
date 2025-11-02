class MatchingConfig {  

  /* = = = = = = = = =
  Category Weights
  = = = = = = = = = */

  // Category weights (must sum to 1.0)
  static const Map<String, double> categoryWeights = {
    'relationship': 0.30,
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
  static const Map<String, Map<String, double>> relationshipMatrix = {
    "We're Best Friends": {
      "We're Best Friends": 0.95,
      "We Explore the World": 0.90,
      "We Run a Business Together": 0.70,
      "Let's Be Homebodies": 0.85,
      "We're a Career Couple": 0.60,
      "I Financially Provide for Them": 0.50,
      "They Financially Provide for Me": 0.50,
      "We're Romantic Lovers": 0.90,
      "We're Feisty Freaks": 0.75,
      "We Share Religious Faith": 0.70,
      "We're a Parenting Team": 0.80,
      "We're a Fitness Couple": 0.75,
    },
    "We Explore the World": {
      "We're Best Friends": 0.90,
      "We Explore the World": 0.95,
      "We Run a Business Together": 0.65,
      "Let's Be Homebodies": 0.30,
      "We're a Career Couple": 0.60,
      "I Financially Provide for Them": 0.45,
      "They Financially Provide for Me": 0.45,
      "We're Romantic Lovers": 0.80,
      "We're Feisty Freaks": 0.85,
      "We Share Religious Faith": 0.60,
      "We're a Parenting Team": 0.50,
      "We're a Fitness Couple": 0.90,
    },
    "We Run a Business Together": {
      "We're Best Friends": 0.70,
      "We Explore the World": 0.65,
      "We Run a Business Together": 0.90,
      "Let's Be Homebodies": 0.55,
      "We're a Career Couple": 0.95,
      "I Financially Provide for Them": 0.80,
      "They Financially Provide for Me": 0.80,
      "We're Romantic Lovers": 0.60,
      "We're Feisty Freaks": 0.65,
      "We Share Religious Faith": 0.65,
      "We're a Parenting Team": 0.70,
      "We're a Fitness Couple": 0.60,
    },
    "Let's Be Homebodies": {
      "We're Best Friends": 0.85,
      "We Explore the World": 0.30,
      "We Run a Business Together": 0.55,
      "Let's Be Homebodies": 0.95,
      "We're a Career Couple": 0.50,
      "I Financially Provide for Them": 0.70,
      "They Financially Provide for Me": 0.70,
      "We're Romantic Lovers": 0.85,
      "We're Fiesty Freaks": 0.70,
      "We Share Religious Faith": 0.80,
      "We're a Parenting Team": 0.90,
      "We're a Fitness Couple": 0.40,
    },
    "We're a Career Couple": {
      "We're Best Friends": 0.60,
      "We Explore the World": 0.60,
      "We Run a Business Together": 0.95,
      "Let's Be Homebodies": 0.50,
      "We're a Career Couple": 0.90,
      "I Financially Provide for Them": 0.75,
      "They Financially Provide for Me": 0.75,
      "We're Romantic Lovers": 0.55,
      "We're Feisty Freaks": 0.65,
      "We Share Religious Faith": 0.60,
      "We're a Parenting Team": 0.65,
      "We're a Fitness Couple": 0.70,
    },
    "I Financially Provide for Them": {
      "We're Best Friends": 0.50,
      "We Explore the World": 0.45,
      "We Run a Business Together": 0.80,
      "Let's Be Homebodies": 0.70,
      "We're a Career Couple": 0.75,
      "I Financially Provide for Them": 0.85,
      "They Financially Provide for Me": 0.20, // Asymmetric relationship
      "We're Romantic Lovers": 0.65,
      "We're Feisty Freaks": 0.60,
      "We Share Religious Faith": 0.70,
      "We're a Parenting Team": 0.75,
      "We're a Fitness Couple": 0.50,
    },
    "They Financially Provide for Me": {
      "We're Best Friends": 0.50,
      "We Explore the World": 0.45,
      "We Run a Business Together": 0.80,
      "Let's Be Homebodies": 0.70,
      "We're a Career Couple": 0.75,
      "I Financially Provide for Them": 0.20, // Asymmetric relationship
      "They Financially Provide for Me": 0.85,
      "We're Romantic Lovers": 0.65,
      "We're Feisty Freaks": 0.60,
      "We Share Religious Faith": 0.70,
      "We're a Parenting Team": 0.75,
      "We're a Fitness Couple": 0.50,
    },
    "We're Romantic Lovers": {
      "We're Best Friends": 0.90,
      "We Explore the World": 0.80,
      "We Run a Business Together": 0.60,
      "Let's Be Homebodies": 0.85,
      "We're a Career Couple": 0.55,
      "I Financially Provide for Them": 0.65,
      "They Financially Provide for Me": 0.65,
      "We're Romantic Lovers": 0.95,
      "We're Feisty Freaks": 0.85,
      "We Share Religious Faith": 0.75,
      "We're a Parenting Team": 0.80,
      "We're a Fitness Couple": 0.70,
    },
    "We're Feisty Freaks": {
      "We're Best Friends": 0.75,
      "We Explore the World": 0.85,
      "We Run a Business Together": 0.65,
      "Let's Be Homebodies": 0.70,
      "We're a Career Couple": 0.65,
      "I Financially Provide for Them": 0.60,
      "They Financially Provide for Me": 0.60,
      "We're Romantic Lovers": 0.85,
      "We're Feisty Freaks": 0.95,
      "We Share Religious Faith": 0.50,
      "We're a Parenting Team": 0.60,
      "We're a Fitness Couple": 0.85,
    },
    "We Share Religious Faith": {
      "We're Best Friends": 0.70,
      "We Explore the World": 0.60,
      "We Run a Business Together": 0.65,
      "Let's Be Homebodies": 0.80,
      "We're a Career Couple": 0.60,
      "I Financially Provide for Them": 0.70,
      "They Financially Provide for Me": 0.70,
      "We're Romantic Lovers": 0.75,
      "We're Feisty Freaks": 0.50,
      "We Share Religious Faith": 0.95,
      "We're a Parenting Team": 0.85,
      "We're a Fitness Couple": 0.65,
    },
    "We're a Parenting Team": {
      "We're Best Friends": 0.80,
      "We Explore the World": 0.50,
      "We Run a Business Together": 0.70,
      "Let's Be Homebodies": 0.90,
      "We're a Career Couple": 0.65,
      "I Financially Provide for Them": 0.75,
      "They Financially Provide for Me": 0.75,
      "We're Romantic Lovers": 0.80,
      "We're Feisty Freaks": 0.60,
      "We Share Religious Faith": 0.85,
      "We're a Parenting Team": 0.95,
      "We're a Fitness Couple": 0.60,
    },
    "We're a Fitness Couple": {
      "We're Best Friends": 0.75,
      "We Explore the World": 0.90,
      "We Run a Business Together": 0.60,
      "Let's Be Homebodies": 0.40,
      "We're a Career Couple": 0.70,
      "I Financially Provide for Them": 0.50,
      "They Financially Provide for Me": 0.50,
      "We're Romantic Lovers": 0.70,
      "We're Feisty Freaks": 0.85,
      "We Share Religious Faith": 0.65,
      "We're a Parenting Team": 0.60,
      "We're a Fitness Couple": 0.95,
    },
  };
  
  // Personality compatibility matrix
  static const Map<String, Map<String, double>> personalityMatrix = {
    "Empathetic": {
      "Empathetic": 0.75,      // Good but can be overwhelming if both too sensitive
      "Proactive": 0.85,        // Great balance - empathy + action
      "Introspective": 0.90,    // Deep understanding
      "Outgoing": 0.70,         // Can work well - draws empath out
      "Romantic": 0.95,         // Perfect match
      "Honest": 0.85,           // Trust and understanding
      "Intelligent": 0.75,      // Good combination
      "Curious": 0.70,          // Decent match
      "Loyal": 0.90,            // Strong foundation
      "Confident": 0.65,        // Can work if confident person is gentle
      "Patient": 0.95,          // Excellent match
      "Playful": 0.75,          // Lightens the mood
      "Ambitious": 0.60,        // May clash if ambition lacks empathy
      "Generous": 0.95,         // Beautiful combination
    },
    "Proactive": {
      "Empathetic": 0.85,
      "Proactive": 0.65,        // Can clash if both always taking charge
      "Introspective": 0.70,    // Balance of action and thought
      "Outgoing": 0.80,         // Good energy match
      "Romantic": 0.70,         // Can work well
      "Honest": 0.80,           // Direct and action-oriented
      "Intelligent": 0.85,      // Strategic action
      "Curious": 0.85,          // Adventure and exploration
      "Loyal": 0.75,            // Dependable combination
      "Confident": 0.85,        // Power couple potential
      "Patient": 0.70,          // Good balance
      "Playful": 0.80,          // Fun and active
      "Ambitious": 0.90,        // Excellent match for goals
      "Generous": 0.75,         // Action with heart
    },
    "Introspective": {
      "Empathetic": 0.90,
      "Proactive": 0.70,
      "Introspective": 0.70,    // Can be too internal if both
      "Outgoing": 0.65,         // Needs balance
      "Romantic": 0.85,         // Deep romantic connection
      "Honest": 0.90,           // Truth and self-awareness
      "Intelligent": 0.95,      // Deep conversations
      "Curious": 0.90,          // Exploring ideas together
      "Loyal": 0.80,            // Thoughtful commitment
      "Confident": 0.60,        // May clash with styles
      "Patient": 0.85,          // Good understanding
      "Playful": 0.65,          // Different energies
      "Ambitious": 0.70,        // Can work with understanding
      "Generous": 0.80,         // Thoughtful giving
    },
    "Outgoing": {
      "Empathetic": 0.70,
      "Proactive": 0.80,
      "Introspective": 0.65,
      "Outgoing": 0.75,         // Fun but may lack depth
      "Romantic": 0.70,         // Can be exciting
      "Honest": 0.75,           // Open communication
      "Intelligent": 0.70,      // Social intelligence
      "Curious": 0.85,          // Exploring together
      "Loyal": 0.70,            // Social but committed
      "Confident": 0.90,        // Great social match
      "Patient": 0.60,          // Different paces
      "Playful": 0.95,          // Perfect fun match
      "Ambitious": 0.80,        // Networking power
      "Generous": 0.85,         // Social generosity
    },
    "Romantic": {
      "Empathetic": 0.95,
      "Proactive": 0.70,
      "Introspective": 0.85,
      "Outgoing": 0.70,
      "Romantic": 0.90,         // Beautiful but needs some contrast
      "Honest": 0.80,           // True romance
      "Intelligent": 0.75,      // Smart romance
      "Curious": 0.75,          // Exploring love
      "Loyal": 0.95,            // Devoted love
      "Confident": 0.75,        // Confident romance
      "Patient": 0.90,          // Gentle love
      "Playful": 0.85,          // Fun and romantic
      "Ambitious": 0.65,        // May have different priorities
      "Generous": 0.95,         // Giving in love
    },
    "Honest": {
      "Empathetic": 0.85,
      "Proactive": 0.80,
      "Introspective": 0.90,
      "Outgoing": 0.75,
      "Romantic": 0.80,
      "Honest": 0.85,           // Truth-based relationship
      "Intelligent": 0.85,      // Truthful discourse
      "Curious": 0.80,          // Open exploration
      "Loyal": 0.95,            // Trust foundation
      "Confident": 0.80,        // Confident honesty
      "Patient": 0.85,          // Understanding truth
      "Playful": 0.70,          // Light but honest
      "Ambitious": 0.75,        // Transparent goals
      "Generous": 0.85,         // Open-hearted
    },
    "Intelligent": {
      "Empathetic": 0.75,
      "Proactive": 0.85,
      "Introspective": 0.95,
      "Outgoing": 0.70,
      "Romantic": 0.75,
      "Honest": 0.85,
      "Intelligent": 0.85,      // Intellectual match
      "Curious": 0.95,          // Learning together
      "Loyal": 0.75,            // Smart commitment
      "Confident": 0.80,        // Intellectual confidence
      "Patient": 0.80,          // Thoughtful patience
      "Playful": 0.70,          // Different approaches
      "Ambitious": 0.90,        // Strategic ambition
      "Generous": 0.75,         // Thoughtful giving
    },
    "Curious": {
      "Empathetic": 0.70,
      "Proactive": 0.85,
      "Introspective": 0.90,
      "Outgoing": 0.85,
      "Romantic": 0.75,
      "Honest": 0.80,
      "Intelligent": 0.95,
      "Curious": 0.90,          // Exploration partners
      "Loyal": 0.70,            // Adventure vs stability
      "Confident": 0.80,        // Confident exploration
      "Patient": 0.65,          // Different paces
      "Playful": 0.90,          // Fun discoveries
      "Ambitious": 0.85,        // Growth-oriented
      "Generous": 0.75,         // Sharing discoveries
    },
    "Loyal": {
      "Empathetic": 0.90,
      "Proactive": 0.75,
      "Introspective": 0.80,
      "Outgoing": 0.70,
      "Romantic": 0.95,
      "Honest": 0.95,
      "Intelligent": 0.75,
      "Curious": 0.70,
      "Loyal": 0.95,            // Deep commitment
      "Confident": 0.75,        // Secure loyalty
      "Patient": 0.90,          // Steadfast patience
      "Playful": 0.75,          // Fun but committed
      "Ambitious": 0.70,        // Different focuses
      "Generous": 0.90,         // Giving loyalty
    },
    "Confident": {
      "Empathetic": 0.65,
      "Proactive": 0.85,
      "Introspective": 0.60,
      "Outgoing": 0.90,
      "Romantic": 0.75,
      "Honest": 0.80,
      "Intelligent": 0.80,
      "Curious": 0.80,
      "Loyal": 0.75,
      "Confident": 0.70,        // May compete
      "Patient": 0.65,          // Different approaches
      "Playful": 0.85,          // Confident fun
      "Ambitious": 0.95,        // Power combination
      "Generous": 0.75,         // Confident giving
    },
    "Patient": {
      "Empathetic": 0.95,
      "Proactive": 0.70,
      "Introspective": 0.85,
      "Outgoing": 0.60,
      "Romantic": 0.90,
      "Honest": 0.85,
      "Intelligent": 0.80,
      "Curious": 0.65,
      "Loyal": 0.90,
      "Confident": 0.65,
      "Patient": 0.85,          // Peaceful but may lack spark
      "Playful": 0.70,          // Different energies
      "Ambitious": 0.60,        // Different paces
      "Generous": 0.90,         // Patient giving
    },
    "Playful": {
      "Empathetic": 0.75,
      "Proactive": 0.80,
      "Introspective": 0.65,
      "Outgoing": 0.95,
      "Romantic": 0.85,
      "Honest": 0.70,
      "Intelligent": 0.70,
      "Curious": 0.90,
      "Loyal": 0.75,
      "Confident": 0.85,
      "Patient": 0.70,
      "Playful": 0.90,          // Fun together
      "Ambitious": 0.70,        // Work-play balance
      "Generous": 0.85,         // Joyful giving
    },
    "Ambitious": {
      "Empathetic": 0.60,
      "Proactive": 0.90,
      "Introspective": 0.70,
      "Outgoing": 0.80,
      "Romantic": 0.65,
      "Honest": 0.75,
      "Intelligent": 0.90,
      "Curious": 0.85,
      "Loyal": 0.70,
      "Confident": 0.95,
      "Patient": 0.60,
      "Playful": 0.70,
      "Ambitious": 0.85,        // Shared drive but may compete
      "Generous": 0.70,         // Success with heart
    },
    "Generous": {
      "Empathetic": 0.95,
      "Proactive": 0.75,
      "Introspective": 0.80,
      "Outgoing": 0.85,
      "Romantic": 0.95,
      "Honest": 0.85,
      "Intelligent": 0.75,
      "Curious": 0.75,
      "Loyal": 0.90,
      "Confident": 0.75,
      "Patient": 0.90,
      "Playful": 0.85,
      "Ambitious": 0.70,
      "Generous": 0.90,         // Beautiful giving relationship
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
  static double getRelationshipScore(String trait1, String trait2) {
    return relationshipMatrix[trait1]?[trait2] ?? 
           relationshipMatrix[trait2]?[trait1] ?? 
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