class FeedbackData {
  final String id;
  final String userId;
  final String targetUserId;
  final String? helpRequestId;
  final String feedbackType;
  final double rating;
  final String description;
  final String? improvementSuggestion;
  final bool wouldRecommend;
  final DateTime createdAt;
  final bool isVerified;

  FeedbackData({
    required this.id,
    required this.userId,
    required this.targetUserId,
    this.helpRequestId,
    required this.feedbackType,
    required this.rating,
    required this.description,
    this.improvementSuggestion,
    required this.wouldRecommend,
    required this.createdAt,
    this.isVerified = false,
  });

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetUserId': targetUserId,
      'helpRequestId': helpRequestId,
      'feedbackType': feedbackType,
      'rating': rating,
      'description': description,
      'improvementSuggestion': improvementSuggestion,
      'wouldRecommend': wouldRecommend,
      'createdAt': createdAt.toIso8601String(),
      'isVerified': isVerified,
    };
  }

  factory FeedbackData.fromJson(Map<String, dynamic> json) {
    return FeedbackData(
      id: json['id'],
      userId: json['userId'],
      targetUserId: json['targetUserId'],
      helpRequestId: json['helpRequestId'],
      feedbackType: json['feedbackType'],
      rating: json['rating'].toDouble(),
      description: json['description'],
      improvementSuggestion: json['improvementSuggestion'],
      wouldRecommend: json['wouldRecommend'],
      createdAt: DateTime.parse(json['createdAt']),
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class ReportData {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final String? reportedContentId;
  final String reportType;
  final String severity;
  final String description;
  final String? evidence;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved', 'dismissed'
  final bool isAnonymous;

  ReportData({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    this.reportedContentId,
    required this.reportType,
    required this.severity,
    required this.description,
    this.evidence,
    required this.createdAt,
    this.status = 'pending',
    required this.isAnonymous,
  });

  // Convert to/from JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reportedContentId': reportedContentId,
      'reportType': reportType,
      'severity': severity,
      'description': description,
      'evidence': evidence,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'isAnonymous': isAnonymous,
    };
  }

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      id: json['id'],
      reporterId: json['reporterId'],
      reportedUserId: json['reportedUserId'],
      reportedContentId: json['reportedContentId'],
      reportType: json['reportType'],
      severity: json['severity'],
      description: json['description'],
      evidence: json['evidence'],
      createdAt: DateTime.parse(json['createdAt']),
      status: json['status'] ?? 'pending',
      isAnonymous: json['isAnonymous'],
    );
  }
}

// Service class to manage feedback and reports
class FeedbackService {
  static final List<FeedbackData> _feedbacks = [];
  static final List<ReportData> _reports = [];

  // Add new feedback
  static void addFeedback(FeedbackData feedback) {
    _feedbacks.add(feedback);
    // In a real app, this would be saved to a database
  }

  // Add new report
  static void addReport(ReportData report) {
    _reports.add(report);
    // In a real app, this would be saved to a database
  }

  // Get feedback for a specific user
  static List<FeedbackData> getFeedbackForUser(String userId) {
    return _feedbacks
        .where((feedback) => feedback.targetUserId == userId)
        .toList();
  }

  // Get average rating for a user
  static double getAverageRating(String userId) {
    final userFeedbacks = getFeedbackForUser(userId);
    if (userFeedbacks.isEmpty) return 0.0;

    final totalRating = userFeedbacks.fold(
      0.0,
      (sum, feedback) => sum + feedback.rating,
    );
    return totalRating / userFeedbacks.length;
  }

  // Get feedback count for a user
  static int getFeedbackCount(String userId) {
    return getFeedbackForUser(userId).length;
  }

  // Get recent feedback for a user (for help history)
  static List<FeedbackData> getRecentFeedback(String userId, {int limit = 5}) {
    final userFeedbacks = getFeedbackForUser(userId);
    userFeedbacks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return userFeedbacks.take(limit).toList();
  }

  // Check if user has any pending reports
  static bool hasPendingReports(String userId) {
    return _reports.any(
      (report) => report.reportedUserId == userId && report.status == 'pending',
    );
  }

  // Get trust score based on feedback and reports
  static double getTrustScore(String userId) {
    final avgRating = getAverageRating(userId);
    final feedbackCount = getFeedbackCount(userId);
    final hasPending = hasPendingReports(userId);

    // Base score from rating
    double score = avgRating * 20; // Convert 5-star to 100-point scale

    // Boost for having more feedback (social proof)
    if (feedbackCount >= 10)
      score += 5;
    else if (feedbackCount >= 5)
      score += 3;
    else if (feedbackCount >= 1)
      score += 1;

    // Penalty for pending reports
    if (hasPending) score -= 15;

    // Ensure score is between 0-100
    return score.clamp(0.0, 100.0);
  }
}
