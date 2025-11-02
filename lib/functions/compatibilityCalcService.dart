import 'compatibilityConfigService.dart';
import 'compatibilityArchetypes.dart';

class MatchCalculationService {
  // Singleton pattern
  static final MatchCalculationService _instance = MatchCalculationService._internal();
  factory MatchCalculationService() => _instance;
  MatchCalculationService._internal();
  
  // Calculate match between two users with optional archetype analysis
  MatchResult calculateMatch({
    required Map<String, dynamic> currentUser,
    required Map<String, dynamic> potentialMatch,
    bool includeArchetypes = true,
  }) {
    Map<String, CategoryScore> categoryScores = {};
    
    // 1. Calculate Chemistry/Relationship Score
    categoryScores['relationship'] = _calculateRelationshipScore(
      currentUser['relationship'] ?? [],
      potentialMatch['relationship'] ?? [],
    );
    
    // 2. Calculate Personality Score
    categoryScores['personality'] = _calculatePersonalityScore(
      currentUser['personality'] ?? [],
      potentialMatch['personality'] ?? [],
    );
    
    // 3. Calculate Interests Score
    categoryScores['interests'] = _calculateInterestsScore(
      currentUser['interests'] ?? [],
      potentialMatch['interests'] ?? [],
    );
    
    // 4. Calculate Goals Score
    categoryScores['goals'] = _calculateGoalsScore(
      currentUser['LifeGoalNeed'] ?? [],
      potentialMatch['LifeGoalNeed'] ?? [],
    );
    
    // 5. Calculate Overall Percentage using MatchingConfig directly
    double overallScore = 0.0;
    
    for (var entry in categoryScores.entries) {
      // Get weight directly from MatchingConfig
      final weight = MatchingConfig.categoryWeights[entry.key] ?? 0.25;
      overallScore += entry.value.score * weight;
    }
    
    double overallPercentage = (overallScore * 100).clamp(0, 100);
    
    // 6. Generate Top Reasons
    List<String> topReasons = _generateTopReasons(categoryScores);
    
    // 7. Determine Match Quality using MatchingConfig helper
    String matchQuality = MatchingConfig.getMatchQuality(overallPercentage);
    
    // 8. Add Archetype Analysis if requested
    Map<String, dynamic>? archetypeAnalysis;
    if (includeArchetypes) {
      archetypeAnalysis = _performArchetypeAnalysis(
        currentUserRelationship: currentUser['relationship'] ?? [],
        matchRelationship: potentialMatch['relationship'] ?? [],
        currentUserPersonality: currentUser['personality'] ?? [],
        matchPersonality: potentialMatch['personality'] ?? [],
        categoryScores: categoryScores,
      );
      
      // Add archetype-based reasons if they exist
      if (archetypeAnalysis['enhancedReasons'] != null) {
        topReasons = _mergeReasons(topReasons, archetypeAnalysis['enhancedReasons']);
      }
    }
    
    return MatchResult(
      userId: potentialMatch['userId'] ?? potentialMatch['uid'] ?? '',
      percentage: overallPercentage,
      matchQuality: matchQuality,
      topReasons: topReasons,
      breakdown: categoryScores,
      archetypeAnalysis: archetypeAnalysis,
    );
  }
  
  // Batch calculate for multiple users
  List<MatchResult> calculateMultipleMatches({
    required Map<String, dynamic> currentUser,
    required List<Map<String, dynamic>> potentialMatches,
    bool includeArchetypes = false, // Default to false for performance
  }) {
    List<MatchResult> results = [];
    
    // Get minimum percentage from MatchingConfig
    final minPercentage = MatchingConfig.scoringThresholds['minimum_match_percentage'] ?? 40;
    
    for (var match in potentialMatches) {
      final result = calculateMatch(
        currentUser: currentUser,
        potentialMatch: match,
        includeArchetypes: includeArchetypes,
      );
      
      // Only include if above minimum threshold
      if (result.percentage >= minPercentage) {
        results.add(result);
      }
    }
    
    // Sort by match percentage
    results.sort((a, b) => b.percentage.compareTo(a.percentage));
    
    return results;
  }
  
  // Perform archetype analysis
  Map<String, dynamic> _performArchetypeAnalysis({
    required List<dynamic> currentUserRelationship,
    required List<dynamic> matchRelationship,
    required List<dynamic> currentUserPersonality,
    required List<dynamic> matchPersonality,
    required Map<String, CategoryScore> categoryScores,
  }) {
    // Analyze personality archetypes
    Map<String, dynamic> personalityAnalysis = 
        RelationshipArchetypeAnalyzer.analyzePersonalityArchetypes(
      user1Traits: currentUserPersonality,
      user2Traits: matchPersonality,
    );
    
    // Analyze relationship styles
    Map<String, dynamic> relationshipAnalysis = 
        RelationshipArchetypeAnalyzer.analyzeRelationshipArchetypes(
      user1Dynamics: currentUserRelationship,
      user2Dynamics: matchRelationship,
    );
    
    // Generate narrative
    String narrative = _generateArchetypeNarrative(
      personalityArchetype: personalityAnalysis['primaryArchetype'],
      relationshipStyle: relationshipAnalysis['primaryStyle'],
      categoryScores: categoryScores,
    );
    
    // Generate enhanced reasons based on archetypes
    List<String> enhancedReasons = _generateArchetypeReasons(
      personalityArchetype: personalityAnalysis['primaryArchetype'],
      relationshipStyle: relationshipAnalysis['primaryStyle'],
    );
    
    // Create summary
    Map<String, String> summary = _createArchetypeSummary(
      personalityArchetype: personalityAnalysis['primaryArchetype'],
      relationshipStyle: relationshipAnalysis['primaryStyle'],
    );
    
    return {
      'personalityArchetype': personalityAnalysis['primaryArchetype'],
      'relationshipStyle': relationshipAnalysis['primaryStyle'],
      'allPersonalityArchetypes': personalityAnalysis['allArchetypes'],
      'allRelationshipStyles': relationshipAnalysis['allStyles'],
      'narrative': narrative,
      'summary': summary,
      'enhancedReasons': enhancedReasons,
      'traitDistribution': personalityAnalysis['traitAnalysis'],
      'dynamicsPattern': relationshipAnalysis['dynamicsAnalysis'],
    };
  }
  
  // Generate archetype narrative
  String _generateArchetypeNarrative({
    Map<String, dynamic>? personalityArchetype,
    Map<String, dynamic>? relationshipStyle,
    required Map<String, CategoryScore> categoryScores,
  }) {
    StringBuffer narrative = StringBuffer();
    
    if (personalityArchetype != null && relationshipStyle != null) {
      // Special combinations
      if (personalityArchetype['name'] == 'Power Couple' && 
          relationshipStyle['name'] == 'Empire Builders') {
        narrative.write('Power couple building an empire together - '
            'an unstoppable force in both love and business.');
      } else if (personalityArchetype['name'] == 'The Romantics' && 
                 relationshipStyle['name'] == 'Passionate Lovers') {
        narrative.write('Deeply romantic souls with passionate chemistry - '
            'a love story for the ages.');
      } else if (personalityArchetype['name'] == 'The Intellectuals' && 
                 relationshipStyle['name'] == 'Best Friend Lovers') {
        narrative.write('Intellectual best friends in love - '
            'stimulating minds and hearts in perfect harmony.');
      } else if (personalityArchetype['name'] == 'Adventure Partners' && 
                 relationshipStyle['name'] == 'Adventure Seekers') {
        narrative.write('Born adventurers on a lifelong journey together - '
            'every day is a new exciting chapter.');
      } else {
        narrative.write('${personalityArchetype['name']} with '
            '${relationshipStyle['name']} style - ${personalityArchetype['description']}');
      }
    } else if (personalityArchetype != null) {
      narrative.write('${personalityArchetype['name']}: ${personalityArchetype['description']}');
    } else if (relationshipStyle != null) {
      narrative.write('${relationshipStyle['name']}: ${relationshipStyle['description']}');
    } else {
      // No clear archetype - create custom message based on scores
      double relationshipScore = categoryScores['relationship']?.score ?? 0;
      double personalityScore = categoryScores['personality']?.score ?? 0;
      
      if (relationshipScore > 0.7 && personalityScore > 0.7) {
        narrative.write('A unique and strong connection that defies conventional categories.');
      } else {
        narrative.write('Your distinctive combination creates its own special dynamic.');
      }
    }
    
    return narrative.toString();
  }
  
  // Generate archetype-based reasons
  List<String> _generateArchetypeReasons({
    Map<String, dynamic>? personalityArchetype,
    Map<String, dynamic>? relationshipStyle,
  }) {
    List<String> reasons = [];
    
    if (personalityArchetype != null && personalityArchetype['strengths'] != null) {
      List<dynamic> strengths = personalityArchetype['strengths'];
      if (strengths.isNotEmpty) {
        reasons.add(strengths.first.toString());
      }
    }
    
    if (relationshipStyle != null && relationshipStyle['characteristics'] != null) {
      List<dynamic> characteristics = relationshipStyle['characteristics'];
      if (characteristics.isNotEmpty) {
        reasons.add(characteristics.first.toString());
      }
    }
    
    return reasons;
  }
  
  // Create archetype summary
  Map<String, String> _createArchetypeSummary({
    Map<String, dynamic>? personalityArchetype,
    Map<String, dynamic>? relationshipStyle,
  }) {
    String title = 'Unique Match';
    String subtitle = '';
    
    if (personalityArchetype != null && relationshipStyle != null) {
      title = '${personalityArchetype['name']} + ${relationshipStyle['name']}';
      subtitle = 'A ${personalityArchetype['name'].toString().toLowerCase()} couple with ${relationshipStyle['name'].toString().toLowerCase()} dynamics';
    } else if (personalityArchetype != null) {
      title = personalityArchetype['name'];
      subtitle = personalityArchetype['description'];
    } else if (relationshipStyle != null) {
      title = relationshipStyle['name'];
      subtitle = relationshipStyle['description'];
    }
    
    return {
      'title': title,
      'subtitle': subtitle,
      'idealDate': relationshipStyle?['idealDate'] ?? 'Discover what works for you',
      'longTermOutlook': relationshipStyle?['longTermOutlook'] ?? 'Writing your own story',
    };
  }
  
  // Merge standard reasons with archetype reasons
  List<String> _mergeReasons(List<String> standardReasons, List<String> archetypeReasons) {
    List<String> merged = [...standardReasons];
    
    for (String archetypeReason in archetypeReasons) {
      if (!merged.contains(archetypeReason) && merged.length < 5) {
        merged.add(archetypeReason);
      }
    }
    
    return merged.take(3).toList(); // Keep top 3
  }
  
  // Relationship CALCULATION - Now uses MatchingConfig helper
  CategoryScore _calculateRelationshipScore(
    List<dynamic> userRelationship,
    List<dynamic> matchRelationship,
  ) {
    if (userRelationship.isEmpty || matchRelationship.isEmpty) {
      return CategoryScore(
        category: 'relationship',
        score: 0.0,
        percentage: 0.0,
        matches: [],
        reason: 'No relationship preferences set',
      );
    }
    
    double bestScore = 0.0;
    String bestUserTrait = '';
    String bestMatchTrait = '';
    
    // Find best compatibility score using MatchingConfig helper
    for (String userTrait in userRelationship) {
      for (String matchTrait in matchRelationship) {
        // Use the helper function from MatchingConfig
        double score = MatchingConfig.getRelationshipScore(userTrait, matchTrait);
        
        if (score > bestScore) {
          bestScore = score;
          bestUserTrait = userTrait;
          bestMatchTrait = matchTrait;
        }
      }
    }
    
    // Generate reason
    String reason = '';
    if (bestScore >= 0.9) {
      reason = 'Perfect relationship match';
    } else if (bestScore >= 0.7) {
      reason = 'Strong relationship compatibility';
    } else if (bestScore >= 0.5) {
      reason = 'Moderate relationship match';
    } else {
      reason = 'Different relationship styles';
    }
    
    return CategoryScore(
      category: 'relationship',
      score: bestScore,
      percentage: bestScore * 100,
      matches: bestScore > 0 ? [bestUserTrait, bestMatchTrait] : [],
      reason: reason,
    );
  }
  
  // PERSONALITY CALCULATION - Now uses MatchingConfig helper
  CategoryScore _calculatePersonalityScore(
    List<dynamic> userPersonality,
    List<dynamic> matchPersonality,
  ) {
    if (userPersonality.isEmpty || matchPersonality.isEmpty) {
      return CategoryScore(
        category: 'personality',
        score: 0.0,
        percentage: 0.0,
        matches: [],
        reason: 'No personality preferences set',
      );
    }
    
    double totalScore = 0.0;
    int combinations = 0;
    List<String> goodMatches = [];
    
    // Average compatibility across all combinations using MatchingConfig helper
    for (String userTrait in userPersonality) {
      for (String matchTrait in matchPersonality) {
        // Use the helper function from MatchingConfig
        double score = MatchingConfig.getPersonalityScore(userTrait, matchTrait);
        totalScore += score;
        combinations++;
        
        if (score >= 0.7) {
          goodMatches.add('$userTrait + $matchTrait');
        }
      }
    }
    
    double averageScore = combinations > 0 ? totalScore / combinations : 0.0;
    
    // Generate reason
    String reason = '';
    if (averageScore >= 0.8) {
      reason = 'Highly compatible personalities';
    } else if (averageScore >= 0.6) {
      reason = 'Good personality balance';
    } else if (averageScore >= 0.4) {
      reason = 'Some personality differences';
    } else {
      reason = 'Different personality types';
    }
    
    return CategoryScore(
      category: 'personality',
      score: averageScore,
      percentage: averageScore * 100,
      matches: goodMatches.take(2).toList(),
      reason: reason,
    );
  }
  
  // INTERESTS CALCULATION - Now uses MatchingConfig helper
  CategoryScore _calculateInterestsScore(
    List<dynamic> userInterests,
    List<dynamic> matchInterests,
  ) {
    if (userInterests.isEmpty || matchInterests.isEmpty) {
      return CategoryScore(
        category: 'interests',
        score: 0.0,
        percentage: 0.0,
        matches: [],
        reason: 'No interests set',
      );
    }
    
    // Find overlapping interests
    Set<String> userSet = Set<String>.from(userInterests.map((e) => e.toString()));
    Set<String> matchSet = Set<String>.from(matchInterests.map((e) => e.toString()));
    Set<String> overlap = userSet.intersection(matchSet);
    
    int matchCount = overlap.length;
    
    // Get score using MatchingConfig helper
    double score = MatchingConfig.getInterestScore(matchCount);
    
    // Generate reason
    String reason = '';
    if (matchCount == 0) {
      reason = 'Different interests';
    } else if (matchCount == 1) {
      reason = 'Both enjoy ${overlap.first}';
    } else if (matchCount == 2) {
      reason = 'Share ${overlap.join(' and ')}';
    } else {
      reason = 'Share $matchCount common interests';
    }
    
    return CategoryScore(
      category: 'interests',
      score: score,
      percentage: score * 100,
      matches: overlap.toList(),
      reason: reason,
    );
  }
  
  // GOALS CALCULATION - Now uses MatchingConfig helpers
  CategoryScore _calculateGoalsScore(
    List<dynamic> userGoals,
    List<dynamic> matchGoals,
  ) {
    if (userGoals.isEmpty || matchGoals.isEmpty) {
      return CategoryScore(
        category: 'goals',
        score: 0.0,
        percentage: 0.0,
        matches: [],
        reason: 'No goals set',
      );
    }
    
    // Convert to string lists
    List<String> userGoalsList = userGoals.map((e) => e.toString()).toList();
    List<String> matchGoalsList = matchGoals.map((e) => e.toString()).toList();
    
    // Find overlapping goals
    Set<String> userSet = Set<String>.from(userGoalsList);
    Set<String> matchSet = Set<String>.from(matchGoalsList);
    Set<String> overlap = userSet.intersection(matchSet);
    
    int matchCount = overlap.length;
    
    // Get base score using MatchingConfig helper
    double baseScore = MatchingConfig.getGoalsBaseScore(matchCount);
    
    // Check for group bonus using MatchingConfig helper
    String groupType = '';
    if (MatchingConfig.areGoalsInSameGroup(userGoalsList, matchGoalsList)) {
      baseScore += MatchingConfig.goalsGroupBonus;
      
      // Determine which group they're in
      bool userFinancial = userGoalsList.any((g) => 
        MatchingConfig.financialFocusedGoals.contains(g));
      bool matchFinancial = matchGoalsList.any((g) => 
        MatchingConfig.financialFocusedGoals.contains(g));
      
      if (userFinancial && matchFinancial) {
        groupType = ' (both success-driven)';
      } else {
        groupType = ' (both freedom-seekers)';
      }
    }
    
    double finalScore = baseScore.clamp(0.0, 1.0);
    
    // Generate reason
    String reason = '';
    if (matchCount > 0 || groupType.isNotEmpty) {
      if (matchCount > 0) {
        reason = 'Aligned life goals$groupType';
      } else {
        reason = 'Similar ambitions$groupType';
      }
    } else {
      reason = 'Different life goals';
    }
    
    return CategoryScore(
      category: 'goals',
      score: finalScore,
      percentage: finalScore * 100,
      matches: overlap.toList(),
      reason: reason,
    );
  }
  
  // Generate top reasons for match
  List<String> _generateTopReasons(Map<String, CategoryScore> categoryScores) {
    List<String> reasons = [];
    
    // Sort by score
    var sortedCategories = categoryScores.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    
    // Take top performing categories
    for (var category in sortedCategories) {
      if (category.score >= 0.7 && reasons.length < 3) {
        if (category.reason.isNotEmpty && !category.reason.contains('No ')) {
          reasons.add(category.reason);
        }
      }
    }
    
    // If no strong reasons, add moderate ones
    if (reasons.isEmpty) {
      for (var category in sortedCategories) {
        if (category.score >= 0.4 && reasons.length < 3) {
          if (category.reason.isNotEmpty && !category.reason.contains('No ')) {
            reasons.add(category.reason);
          }
        }
      }
    }
    
    return reasons;
  }

  // Helper method to get user's personality archetype (for profile display)
  Map<String, dynamic> getUserArchetype({
    required List<dynamic> personalityTraits,
  }) {
    var analysis = RelationshipArchetypeAnalyzer.analyzePersonalityArchetypes(
      user1Traits: personalityTraits,
      user2Traits: [], // Empty to analyze just one user
    );
    
    return {
      'archetype': analysis['primaryArchetype'],
      'allArchetypes': analysis['allArchetypes'],
    };
  }

  // Helper method to get user's relationship style (for profile display)
  Map<String, dynamic> getUserRelationshipStyle({
    required List<dynamic> relationshipDynamics,
  }) {
    var analysis = RelationshipArchetypeAnalyzer.analyzeRelationshipArchetypes(
      user1Dynamics: relationshipDynamics,
      user2Dynamics: [], // Empty to analyze just one user
    );
    
    return {
      'style': analysis['primaryStyle'],
      'allStyles': analysis['allStyles'],
    };
  }
}

// Updated MatchResult class with archetype analysis
class MatchResult {
  final String userId;
  final double percentage;
  final String matchQuality;
  
  final List<String> topReasons;
  final Map<String, CategoryScore> breakdown;
  final Map<String, dynamic>? archetypeAnalysis; // New field
  
  MatchResult({
    required this.userId,
    required this.percentage,
    required this.matchQuality,
    required this.topReasons,
    required this.breakdown,
    this.archetypeAnalysis, // Optional
  });
  
  // Convenience getters for archetype data
  String? get personalityArchetype => 
    archetypeAnalysis?['personalityArchetype']?['name'];
    
  String? get relationshipStyle => 
    archetypeAnalysis?['relationshipStyle']?['name'];
    
  String? get archetypeNarrative => 
    archetypeAnalysis?['narrative'];
    
  String? get archetypeTitle => 
    archetypeAnalysis?['summary']?['title'];
    
  String? get idealDate => 
    archetypeAnalysis?['summary']?['idealDate'];
    
  String? get longTermOutlook => 
    archetypeAnalysis?['summary']?['longTermOutlook'];
}

class CategoryScore {
  final String category;
  final double score; // 0.0 to 1.0
  final double percentage; // 0 to 100
  final List<String> matches;
  final String reason;
  
  CategoryScore({
    required this.category,
    required this.score,
    required this.percentage,
    required this.matches,
    required this.reason,
  });
}