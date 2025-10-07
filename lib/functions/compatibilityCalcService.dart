import 'dart:math' as math;

class MatchCalculationService {

  // Singleton pattern
  static final MatchCalculationService _instance = MatchCalculationService._internal();
  factory MatchCalculationService() => _instance;
  MatchCalculationService._internal();
  
  // Calculate match between two users using cached config
  MatchResult calculateMatch({
    required Map<String, dynamic> currentUser,
    required Map<String, dynamic> potentialMatch,
    required Map<String, dynamic> config,
  }) {
    
    Map<String, CategoryScore> categoryScores = {};
    
    // 1. Calculate Chemistry Score
    categoryScores['chemistry'] = _calculateChemistryScore(
      currentUser['chemistry'] ?? [],
      potentialMatch['chemistry'] ?? [],
      config,
    );
    
    // 2. Calculate Personality Score
    categoryScores['personality'] = _calculatePersonalityScore(
      currentUser['personality'] ?? [],
      potentialMatch['personality'] ?? [],
      config,
    );
    
    // 3. Calculate Interests Score
    categoryScores['interests'] = _calculateInterestsScore(
      currentUser['interests'] ?? [],
      potentialMatch['interests'] ?? [],
      config,
    );
    
    // 4. Calculate Goals Score
    categoryScores['goals'] = _calculateGoalsScore(
      currentUser['goals'] ?? [],
      potentialMatch['goals'] ?? [],
      config,
    );
    
    // 5. Calculate Overall Percentage
    double overallScore = 0.0;
    final weights = config['category_weights'] ?? {};
    
    for (var entry in categoryScores.entries) {
      final weight = (weights[entry.key] ?? 0.25).toDouble();
      overallScore += entry.value.score * weight;
    }
    
    double overallPercentage = (overallScore * 100).clamp(0, 100);
    
    // 6. Generate Top Reasons
    List<String> topReasons = _generateTopReasons(categoryScores);
    
    // 7. Determine Match Quality
    String matchQuality = _getMatchQuality(overallPercentage, config);
    
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
    required Map<String, dynamic> config,
  }) {
    List<MatchResult> results = [];
    
    final minPercentage = (config['scoring_thresholds']?['minimum_match_percentage'] ?? 40).toDouble();
    
    for (var match in potentialMatches) {
      final result = calculateMatch(
        currentUser: currentUser,
        potentialMatch: match,
        config: config,
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
  
  // CHEMISTRY CALCULATION
  CategoryScore _calculateChemistryScore(
    List<dynamic> userChemistry,
    List<dynamic> matchChemistry,
    Map<String, dynamic> config,
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
    
    final matrix = config['categories']?['chemistry']?['compatibility_matrix'] ?? {};
    double bestScore = 0.0;
    String bestUserTrait = '';
    String bestMatchTrait = '';
    
    // Find best compatibility score
    for (String userTrait in userChemistry) {
      for (String matchTrait in matchChemistry) {
        // Check both directions in matrix
        double score = (matrix[userTrait]?[matchTrait] ?? 
                       matrix[matchTrait]?[userTrait] ?? 0.0).toDouble();
        
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
  
  // PERSONALITY CALCULATION
  CategoryScore _calculatePersonalityScore(
    List<dynamic> userPersonality,
    List<dynamic> matchPersonality,
    Map<String, dynamic> config,
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
    
    final matrix = config['categories']?['personality']?['compatibility_matrix'] ?? {};
    double totalScore = 0.0;
    int combinations = 0;
    List<String> goodMatches = [];
    
    // Average compatibility across all combinations
    for (String userTrait in userPersonality) {
      for (String matchTrait in matchPersonality) {
        double score = (matrix[userTrait]?[matchTrait] ?? 
                       matrix[matchTrait]?[userTrait] ?? 0.0).toDouble();
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
  
  // INTERESTS CALCULATION (Simple Overlap)
  CategoryScore _calculateInterestsScore(
    List<dynamic> userInterests,
    List<dynamic> matchInterests,
    Map<String, dynamic> config,
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
    
    // Get score from tiers
    final tiers = config['categories']?['interests']?['scoring_tiers'] ?? {};
    double score = 0.0;
    
    if (matchCount == 0) {
      score = (tiers['0_matches'] ?? 0.0).toDouble();
    } else if (matchCount == 1) {
      score = (tiers['1_match'] ?? 0.3).toDouble();
    } else if (matchCount == 2) {
      score = (tiers['2_matches'] ?? 0.5).toDouble();
    } else if (matchCount == 3) {
      score = (tiers['3_matches'] ?? 0.7).toDouble();
    } else if (matchCount == 4) {
      score = (tiers['4_matches'] ?? 0.85).toDouble();
    } else {
      score = (tiers['5_plus_matches'] ?? 1.0).toDouble();
    }
    
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
  
  // GOALS CALCULATION with Group Bonus
  CategoryScore _calculateGoalsScore(
    List<dynamic> userGoals,
    List<dynamic> matchGoals,
    Map<String, dynamic> config,
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
    
    // Find overlapping goals
    Set<String> userSet = Set<String>.from(userGoals.map((e) => e.toString()));
    Set<String> matchSet = Set<String>.from(matchGoals.map((e) => e.toString()));
    Set<String> overlap = userSet.intersection(matchSet);
    
    int matchCount = overlap.length;
    
    // Check for group bonus
    final groups = config['categories']?['goals']?['compatibility_groups'] ?? {};
    double groupBonus = 0.0;
    String groupType = '';
    
    // Check financial group
    List<String> financialGoals = List<String>.from(groups['financial_focused'] ?? []);
    bool userFinancial = userGoals.any((g) => financialGoals.contains(g.toString()));
    bool matchFinancial = matchGoals.any((g) => financialGoals.contains(g.toString()));
    
    // Check freedom group
    List<String> freedomGoals = List<String>.from(groups['freedom_focused'] ?? []);
    bool userFreedom = userGoals.any((g) => freedomGoals.contains(g.toString()));
    bool matchFreedom = matchGoals.any((g) => freedomGoals.contains(g.toString()));
    
    if (userFinancial && matchFinancial) {
      groupBonus = (config['categories']?['goals']?['group_bonus'] ?? 0.15).toDouble();
      groupType = ' (both success-driven)';
    } else if (userFreedom && matchFreedom) {
      groupBonus = (config['categories']?['goals']?['group_bonus'] ?? 0.15).toDouble();
      groupType = ' (both freedom-seekers)';
    }
    
    // Get base score from tiers
    final tiers = config['categories']?['goals']?['scoring_tiers'] ?? {};
    double baseScore = 0.0;
    
    if (matchCount == 0) {
      baseScore = (tiers['0_matches'] ?? 0.0).toDouble();
    } else if (matchCount == 1) {
      baseScore = (tiers['1_match'] ?? 0.4).toDouble();
    } else if (matchCount == 2) {
      baseScore = (tiers['2_matches'] ?? 0.7).toDouble();
    } else {
      baseScore = (tiers['3_plus_matches'] ?? 1.0).toDouble();
    }
    
    double finalScore = (baseScore + groupBonus).clamp(0.0, 1.0);
    
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
  
  // Get match quality label
  String _getMatchQuality(double percentage, Map<String, dynamic> config) {
    final thresholds = config['scoring_thresholds'] ?? {};
    
    if (percentage >= (thresholds['excellent_match'] ?? 95)) {
      return 'Excellent Match';
    } else if (percentage >= (thresholds['great_match'] ?? 85)) {
      return 'Great Match';
    } else if (percentage >= (thresholds['good_match'] ?? 70)) {
      return 'Good Match';
    } else if (percentage >= (thresholds['minimum_match_percentage'] ?? 40)) {
      return 'Match';
    } else {
      return 'Low Match';
    }
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