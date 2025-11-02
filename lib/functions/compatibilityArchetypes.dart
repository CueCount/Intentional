class RelationshipArchetypeAnalyzer {
  
  // Analyze combined personality traits to identify couple archetypes
  static Map<String, dynamic> analyzePersonalityArchetypes({
    required List<dynamic> user1Traits,
    required List<dynamic> user2Traits,
  }) {
    Set<String> user1Set = user1Traits.map((e) => e.toString()).toSet();
    Set<String> user2Set = user2Traits.map((e) => e.toString()).toSet();
    Set<String> combinedTraits = user1Set.union(user2Set);
    Set<String> sharedTraits = user1Set.intersection(user2Set);
    
    List<Map<String, dynamic>> identifiedArchetypes = [];
    
    // Check each archetype
    for (var archetype in _personalityArchetypes) {
      double matchScore = _calculateArchetypeMatch(
        combinedTraits,
        sharedTraits,
        user1Set,
        user2Set,
        archetype,
      );
      
      if (matchScore >= archetype['threshold']) {
        identifiedArchetypes.add({
          'name': archetype['name'],
          'description': archetype['description'],
          'matchScore': matchScore,
          'strengths': archetype['strengths'],
          'watchOuts': archetype['watchOuts'],
        });
      }
    }
    
    // Sort by match score
    identifiedArchetypes.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
    
    // Get primary archetype
    Map<String, dynamic>? primaryArchetype = identifiedArchetypes.isNotEmpty 
        ? identifiedArchetypes.first 
        : null;
    
    return {
      'primaryArchetype': primaryArchetype,
      'allArchetypes': identifiedArchetypes,
      'traitAnalysis': _analyzeTraitDistribution(user1Set, user2Set),
    };
  }
  
  // Analyze relationship dynamics to identify couple styles
  static Map<String, dynamic> analyzeRelationshipArchetypes({
    required List<dynamic> user1Dynamics,
    required List<dynamic> user2Dynamics,
  }) {
    Set<String> user1Set = user1Dynamics.map((e) => e.toString()).toSet();
    Set<String> user2Set = user2Dynamics.map((e) => e.toString()).toSet();
    Set<String> combinedDynamics = user1Set.union(user2Set);
    Set<String> sharedDynamics = user1Set.intersection(user2Set);
    
    List<Map<String, dynamic>> identifiedStyles = [];
    
    // Check each relationship style
    for (var style in _relationshipStyles) {
      double matchScore = _calculateStyleMatch(
        combinedDynamics,
        sharedDynamics,
        style,
      );
      
      if (matchScore >= style['threshold']) {
        identifiedStyles.add({
          'name': style['name'],
          'description': style['description'],
          'matchScore': matchScore,
          'characteristics': style['characteristics'],
          'idealDate': style['idealDate'],
          'longTermOutlook': style['longTermOutlook'],
        });
      }
    }
    
    // Sort by match score
    identifiedStyles.sort((a, b) => b['matchScore'].compareTo(a['matchScore']));
    
    // Get primary style
    Map<String, dynamic>? primaryStyle = identifiedStyles.isNotEmpty 
        ? identifiedStyles.first 
        : null;
    
    return {
      'primaryStyle': primaryStyle,
      'allStyles': identifiedStyles,
      'dynamicsAnalysis': _analyzeDynamicsPattern(combinedDynamics, sharedDynamics),
    };
  }
  
  // Calculate archetype match score
  static double _calculateArchetypeMatch(
    Set<String> combinedTraits,
    Set<String> sharedTraits,
    Set<String> user1Traits,
    Set<String> user2Traits,
    Map<String, dynamic> archetype,
  ) {
    double score = 0.0;
    int requiredCount = 0;
    int optionalCount = 0;
    
    // Check required traits
    List<String> required = List<String>.from(archetype['requiredTraits'] ?? []);
    for (String trait in required) {
      if (combinedTraits.contains(trait)) {
        score += 0.3;
        requiredCount++;
      }
    }
    
    // Check optional traits
    List<String> optional = List<String>.from(archetype['optionalTraits'] ?? []);
    for (String trait in optional) {
      if (combinedTraits.contains(trait)) {
        score += 0.1;
        optionalCount++;
      }
    }
    
    // Bonus for shared traits
    List<String> bonusIfShared = List<String>.from(archetype['bonusIfShared'] ?? []);
    for (String trait in bonusIfShared) {
      if (sharedTraits.contains(trait)) {
        score += 0.15;
      }
    }
    
    // Check for complementary traits
    Map<String, String> complementary = Map<String, String>.from(archetype['complementaryPairs'] ?? {});
    complementary.forEach((trait1, trait2) {
      if ((user1Traits.contains(trait1) && user2Traits.contains(trait2)) ||
          (user1Traits.contains(trait2) && user2Traits.contains(trait1))) {
        score += 0.2;
      }
    });
    
    // Normalize score
    return score.clamp(0.0, 1.0);
  }
  
  // Calculate relationship style match score
  static double _calculateStyleMatch(
    Set<String> combinedDynamics,
    Set<String> sharedDynamics,
    Map<String, dynamic> style,
  ) {
    double score = 0.0;
    
    // Check primary dynamics
    List<String> primary = List<String>.from(style['primaryDynamics'] ?? []);
    for (String dynamic in primary) {
      if (combinedDynamics.contains(dynamic)) {
        score += 0.35;
      }
    }
    
    // Check secondary dynamics
    List<String> secondary = List<String>.from(style['secondaryDynamics'] ?? []);
    for (String dynamic in secondary) {
      if (combinedDynamics.contains(dynamic)) {
        score += 0.15;
      }
    }
    
    // Bonus for shared primary dynamics
    for (String dynamic in primary) {
      if (sharedDynamics.contains(dynamic)) {
        score += 0.2;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }
  
  // Analyze trait distribution
  static Map<String, String> _analyzeTraitDistribution(
    Set<String> user1Traits,
    Set<String> user2Traits,
  ) {
    Set<String> shared = user1Traits.intersection(user2Traits);
    Set<String> unique1 = user1Traits.difference(user2Traits);
    Set<String> unique2 = user2Traits.difference(user1Traits);
    
    String distribution;
    if (shared.length > unique1.length && shared.length > unique2.length) {
      distribution = 'Highly Aligned - You share most personality traits';
    } else if (unique1.length > shared.length || unique2.length > shared.length) {
      distribution = 'Complementary - You bring different strengths';
    } else {
      distribution = 'Balanced - Mix of shared and unique traits';
    }
    
    return {
      'distribution': distribution,
      'sharedCount': shared.length.toString(),
      'uniqueCount': (unique1.length + unique2.length).toString(),
    };
  }
  
  // Analyze dynamics pattern
  static Map<String, String> _analyzeDynamicsPattern(
    Set<String> combinedDynamics,
    Set<String> sharedDynamics,
  ) {
    String pattern;
    
    if (sharedDynamics.length >= 3) {
      pattern = 'Strongly Aligned Vision';
    } else if (sharedDynamics.length >= 1) {
      pattern = 'Partially Aligned Vision';
    } else {
      pattern = 'Diverse Perspectives';
    }
    
    // Check for specific patterns
    bool hasCareer = combinedDynamics.any((d) => 
      d.contains('Business') || d.contains('Career'));
    bool hasFamily = combinedDynamics.any((d) => 
      d.contains('Parenting') || d.contains('Homebodies'));
    bool hasAdventure = combinedDynamics.any((d) => 
      d.contains('Explore') || d.contains('Fitness'));
    
    String focus;
    if (hasCareer && hasFamily) {
      focus = 'Work-Life Balance';
    } else if (hasCareer) {
      focus = 'Career-Oriented';
    } else if (hasFamily) {
      focus = 'Family-Oriented';
    } else if (hasAdventure) {
      focus = 'Adventure-Oriented';
    } else {
      focus = 'Relationship-Focused';
    }
    
    return {
      'pattern': pattern,
      'focus': focus,
    };
  }
  
  // Personality Archetype Definitions
  static final List<Map<String, dynamic>> _personalityArchetypes = [
    {
      'name': 'Power Couple',
      'description': 'Two driven individuals building an empire together',
      'requiredTraits': ['Ambitious', 'Confident'],
      'optionalTraits': ['Intelligent', 'Proactive'],
      'bonusIfShared': ['Ambitious', 'Confident'],
      'complementaryPairs': {},
      'threshold': 0.6,
      'strengths': [
        'Mutual drive for success',
        'Support each other\'s ambitions',
        'High achievement potential',
      ],
      'watchOuts': [
        'Remember to make time for romance',
        'Avoid competing with each other',
        'Balance work and personal life',
      ],
    },
    {
      'name': 'The Intellectuals',
      'description': 'Deep thinkers who connect through ideas and knowledge',
      'requiredTraits': ['Intelligent', 'Curious'],
      'optionalTraits': ['Introspective', 'Patient'],
      'bonusIfShared': ['Intelligent', 'Curious'],
      'complementaryPairs': {},
      'threshold': 0.6,
      'strengths': [
        'Stimulating conversations',
        'Shared love of learning',
        'Mental compatibility',
      ],
      'watchOuts': [
        'Don\'t forget emotional connection',
        'Make room for spontaneity',
        'Balance analysis with action',
      ],
    },
    {
      'name': 'The Romantics',
      'description': 'Love-focused couple who prioritize emotional connection',
      'requiredTraits': ['Romantic', 'Empathetic'],
      'optionalTraits': ['Loyal', 'Patient', 'Generous'],
      'bonusIfShared': ['Romantic'],
      'complementaryPairs': {},
      'threshold': 0.6,
      'strengths': [
        'Deep emotional bond',
        'Thoughtful gestures',
        'Strong intimacy',
      ],
      'watchOuts': [
        'Maintain individual identities',
        'Address practical matters too',
        'Communicate directly when needed',
      ],
    },
    {
      'name': 'Adventure Partners',
      'description': 'Fun-loving duo always seeking the next experience',
      'requiredTraits': ['Playful', 'Curious'],
      'optionalTraits': ['Outgoing', 'Confident', 'Proactive'],
      'bonusIfShared': ['Playful', 'Curious'],
      'complementaryPairs': {},
      'threshold': 0.6,
      'strengths': [
        'Never a dull moment',
        'Shared excitement for life',
        'Spontaneous and fun',
      ],
      'watchOuts': [
        'Build stability together',
        'Have serious conversations',
        'Plan for the future',
      ],
    },
    {
      'name': 'The Balanced Duo',
      'description': 'Complementary partners who balance each other perfectly',
      'requiredTraits': [],
      'optionalTraits': ['Patient', 'Honest', 'Loyal'],
      'bonusIfShared': [],
      'complementaryPairs': {
        'Proactive': 'Patient',
        'Outgoing': 'Introspective',
        'Ambitious': 'Empathetic',
        'Playful': 'Honest',
      },
      'threshold': 0.5,
      'strengths': [
        'Balance each other\'s extremes',
        'Learn from differences',
        'Complete partnership',
      ],
      'watchOuts': [
        'Appreciate your differences',
        'Find common ground',
        'Communicate different needs',
      ],
    },
    {
      'name': 'The Loyalists',
      'description': 'Devoted partners who prioritize trust and commitment',
      'requiredTraits': ['Loyal', 'Honest'],
      'optionalTraits': ['Patient', 'Empathetic', 'Generous'],
      'bonusIfShared': ['Loyal', 'Honest'],
      'complementaryPairs': {},
      'threshold': 0.6,
      'strengths': [
        'Unshakeable trust',
        'Long-term stability',
        'Dependable partnership',
      ],
      'watchOuts': [
        'Keep the spark alive',
        'Embrace new experiences',
        'Avoid becoming too routine',
      ],
    },
    {
      'name': 'Social Butterflies',
      'description': 'Outgoing couple who thrive in social settings',
      'requiredTraits': ['Outgoing', 'Confident'],
      'optionalTraits': ['Playful', 'Generous', 'Empathetic'],
      'bonusIfShared': ['Outgoing'],
      'complementaryPairs': {},
      'threshold': 0.6,
      'strengths': [
        'Great social life',
        'Networking power',
        'Fun and engaging',
      ],
      'watchOuts': [
        'Make time for intimacy',
        'Develop deeper connections',
        'Balance social and private time',
      ],
    },
    {
      'name': 'The Givers',
      'description': 'Generous souls who find joy in caring for each other',
      'requiredTraits': ['Generous', 'Empathetic'],
      'optionalTraits': ['Patient', 'Romantic', 'Loyal'],
      'bonusIfShared': ['Generous', 'Empathetic'],
      'complementaryPairs': {},
      'threshold': 0.6,
      'strengths': [
        'Mutual support',
        'Emotional abundance',
        'Nurturing relationship',
      ],
      'watchOuts': [
        'Set healthy boundaries',
        'Practice self-care',
        'Receive as well as give',
      ],
    },
  ];
  
  // Relationship Style Definitions
  static final List<Map<String, dynamic>> _relationshipStyles = [
    {
      'name': 'Adventure Seekers',
      'description': 'Your relationship thrives on exploration and new experiences',
      'primaryDynamics': ["We Explore the World", "We're a Fitness Couple"],
      'secondaryDynamics': ["We're Fiesty Freaks", "We're Best Friends"],
      'threshold': 0.5,
      'characteristics': [
        'Always planning the next adventure',
        'Bond through physical activities',
        'Embrace spontaneity',
      ],
      'idealDate': 'Hiking to a hidden waterfall or trying a new extreme sport',
      'longTermOutlook': 'A lifetime of adventures and stories to tell',
    },
    {
      'name': 'Empire Builders',
      'description': 'Partners in business and life, building success together',
      'primaryDynamics': ["We Run a Business Together", "We're a Career Couple"],
      'secondaryDynamics': ["I Financially Provide for Them", "They Financially Provide for Me"],
      'threshold': 0.5,
      'characteristics': [
        'Aligned professional goals',
        'Support each other\'s ambitions',
        'View relationship as partnership',
      ],
      'idealDate': 'Networking event followed by strategy session over wine',
      'longTermOutlook': 'Building wealth and success as a team',
    },
    {
      'name': 'Cozy Nesters',
      'description': 'Home is where the heart is for this comfort-loving couple',
      'primaryDynamics': ["Let's Be Homebodies", "We're a Parenting Team"],
      'secondaryDynamics': ["We Share Religious Faith", "We're Romantic Lovers"],
      'threshold': 0.5,
      'characteristics': [
        'Love quiet nights at home',
        'Focus on family and stability',
        'Create a warm, welcoming space',
      ],
      'idealDate': 'Cooking dinner together and watching movies on the couch',
      'longTermOutlook': 'A stable, nurturing family life',
    },
    {
      'name': 'Passionate Lovers',
      'description': 'Romance and chemistry are at the core of your connection',
      'primaryDynamics': ["We're Romantic Lovers", "We're Fiesty Freaks"],
      'secondaryDynamics': ["We're Best Friends"],
      'threshold': 0.5,
      'characteristics': [
        'Intense emotional connection',
        'Prioritize romance and intimacy',
        'Keep the spark alive',
      ],
      'idealDate': 'Candlelit dinner followed by dancing until dawn',
      'longTermOutlook': 'A passionate love story that never gets old',
    },
    {
      'name': 'Best Friend Lovers',
      'description': 'Friendship is the foundation of your romantic relationship',
      'primaryDynamics': ["We're Best Friends", "We're Romantic Lovers"],
      'secondaryDynamics': ["We Explore the World", "Let's Be Homebodies"],
      'threshold': 0.5,
      'characteristics': [
        'Easy companionship',
        'Share everything with each other',
        'Laugh together constantly',
      ],
      'idealDate': 'Anything that involves lots of talking and laughing',
      'longTermOutlook': 'Growing old together as best friends',
    },
    {
      'name': 'Traditional Partners',
      'description': 'Clear roles and traditional values guide your relationship',
      'primaryDynamics': ["I Financially Provide for Them", "They Financially Provide for Me"],
      'secondaryDynamics': ["We Share Religious Faith", "We're a Parenting Team"],
      'threshold': 0.5,
      'characteristics': [
        'Defined relationship roles',
        'Traditional values',
        'Focus on stability',
      ],
      'idealDate': 'Classic dinner and a movie',
      'longTermOutlook': 'A traditional family structure',
    },
    {
      'name': 'Faith-Centered Couple',
      'description': 'Spiritual connection forms the core of your relationship',
      'primaryDynamics': ["We Share Religious Faith"],
      'secondaryDynamics': ["We're a Parenting Team", "Let's Be Homebodies"],
      'threshold': 0.4,
      'characteristics': [
        'Shared spiritual practices',
        'Values-driven decisions',
        'Faith guides relationship',
      ],
      'idealDate': 'Attending service together followed by family gathering',
      'longTermOutlook': 'A relationship blessed by shared faith',
    },
    {
      'name': 'Dynamic Duo',
      'description': 'A versatile couple that adapts to any situation',
      'primaryDynamics': [],
      'secondaryDynamics': ["We're Best Friends", "We Explore the World", "We're Romantic Lovers"],
      'threshold': 0.3,
      'characteristics': [
        'Flexible and adaptable',
        'Multi-faceted relationship',
        'Balance various interests',
      ],
      'idealDate': 'Surprise each other with something new',
      'longTermOutlook': 'An evolving relationship that grows with you',
    },
  ];
  
  // Generate narrative explanation
  static String generateArchetypeNarrative({
    Map<String, dynamic>? personalityArchetype,
    Map<String, dynamic>? relationshipStyle,
  }) {
    StringBuffer narrative = StringBuffer();
    
    if (personalityArchetype != null) {
      narrative.writeln('💑 Personality Match: ${personalityArchetype['name']}');
      narrative.writeln(personalityArchetype['description']);
      narrative.writeln();
    }
    
    if (relationshipStyle != null) {
      narrative.writeln('❤️ Relationship Style: ${relationshipStyle['name']}');
      narrative.writeln(relationshipStyle['description']);
      narrative.writeln();
    }
    
    if (personalityArchetype == null && relationshipStyle == null) {
      narrative.writeln('Your unique combination doesn\'t fit a specific archetype, ');
      narrative.writeln('which means you\'re writing your own relationship story!');
    }
    
    return narrative.toString();
  }
}

// Extension to integrate with main compatibility calculator
extension ArchetypeIntegration on Map<String, dynamic> {
  Map<String, dynamic> withArchetypeAnalysis({
    required List<dynamic> user1Chemistry,
    required List<dynamic> user2Chemistry,
    required List<dynamic> user1Personality,
    required List<dynamic> user2Personality,
  }) {
    // Analyze personality archetypes
    Map<String, dynamic> personalityAnalysis = 
        RelationshipArchetypeAnalyzer.analyzePersonalityArchetypes(
      user1Traits: user1Personality,
      user2Traits: user2Personality,
    );
    
    // Analyze relationship styles
    Map<String, dynamic> relationshipAnalysis = 
        RelationshipArchetypeAnalyzer.analyzeRelationshipArchetypes(
      user1Dynamics: user1Chemistry,
      user2Dynamics: user2Chemistry,
    );
    
    // Generate narrative
    String narrative = RelationshipArchetypeAnalyzer.generateArchetypeNarrative(
      personalityArchetype: personalityAnalysis['primaryArchetype'],
      relationshipStyle: relationshipAnalysis['primaryStyle'],
    );
    
    // Add to existing results
    this['archetypeAnalysis'] = {
      'personalityArchetype': personalityAnalysis['primaryArchetype'],
      'relationshipStyle': relationshipAnalysis['primaryStyle'],
      'narrative': narrative,
      'allPersonalityArchetypes': personalityAnalysis['allArchetypes'],
      'allRelationshipStyles': relationshipAnalysis['allStyles'],
      'traitDistribution': personalityAnalysis['traitAnalysis'],
      'dynamicsPattern': relationshipAnalysis['dynamicsAnalysis'],
    };
    
    return this;
  }
}