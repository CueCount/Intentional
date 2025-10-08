import 'compatibilityConfigService.dart'; 

class MatchCalculationService {
  // Singleton pattern
  static final MatchCalculationService _instance = MatchCalculationService._internal();
  factory MatchCalculationService() => _instance;
  MatchCalculationService._internal();
  
  // Calculate match between two users (NO CONFIG PARAMETER NEEDED!)
  MatchResult calculateMatch({
    required Map<String, dynamic> currentUser,
    required Map<String, dynamic> potentialMatch,
  }) {
    Map<String, CategoryScore> categoryScores = {};
    
    // 1. Calculate Chemistry Score
    categoryScores['chemistry'] = _calculateChemistryScore(
      currentUser['chemistry'] ?? [],
      potentialMatch['chemistry'] ?? [],
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
      currentUser['goals'] ?? [],
      potentialMatch['goals'] ?? [],
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
    
    return MatchResult(
      userId: potentialMatch['userId'] ?? potentialMatch['uid'] ?? '',
      percentage: overallPercentage,
      matchQuality: matchQuality,
      topReasons: topReasons,
      breakdown: categoryScores,
    );
  }
  
  // Batch calculate for multiple users
  List<MatchResult> calculateMultipleMatches({
    required Map<String, dynamic> currentUser,
    required List<Map<String, dynamic>> potentialMatches,
  }) {
    List<MatchResult> results = [];
    
    // Get minimum percentage from MatchingConfig
    final minPercentage = MatchingConfig.scoringThresholds['minimum_match_percentage'] ?? 40;
    
    for (var match in potentialMatches) {
      final result = calculateMatch(
        currentUser: currentUser,
        potentialMatch: match,
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
  
  // CHEMISTRY CALCULATION - Now uses MatchingConfig helper
  CategoryScore _calculateChemistryScore(
    List<dynamic> userChemistry,
    List<dynamic> matchChemistry,
  ) {
    if (userChemistry.isEmpty || matchChemistry.isEmpty) {
      return CategoryScore(
        category: 'chemistry',
        score: 0.0,
        percentage: 0.0,
        matches: [],
        reason: 'No chemistry preferences set',
      );
    }
    
    double bestScore = 0.0;
    String bestUserTrait = '';
    String bestMatchTrait = '';
    
    // Find best compatibility score using MatchingConfig helper
    for (String userTrait in userChemistry) {
      for (String matchTrait in matchChemistry) {
        // Use the helper function from MatchingConfig
        double score = MatchingConfig.getChemistryScore(userTrait, matchTrait);
        
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
      reason = 'Perfect chemistry match';
    } else if (bestScore >= 0.7) {
      reason = 'Strong chemistry compatibility';
    } else if (bestScore >= 0.5) {
      reason = 'Moderate chemistry match';
    } else {
      reason = 'Different chemistry styles';
    }
    
    return CategoryScore(
      category: 'chemistry',
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

}

// Data classes
class MatchResult {
  final String userId;
  final double percentage;
  final String matchQuality;
  final List<String> topReasons;
  final Map<String, CategoryScore> breakdown;
  
  MatchResult({
    required this.userId,
    required this.percentage,
    required this.matchQuality,
    required this.topReasons,
    required this.breakdown,
  });
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