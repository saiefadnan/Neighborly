import 'package:cloud_firestore/cloud_firestore.dart';

// Enhanced Help Chat Message Model
class HelpChatMessage {
  final String id;
  final String helpRequestId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final HelpChatMessageType type;
  final Map<String, dynamic>? metadata;
  bool isRead;

  HelpChatMessage({
    required this.id,
    required this.helpRequestId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.type,
    this.metadata,
    this.isRead = false,
  });

  factory HelpChatMessage.fromJson(Map<String, dynamic> json) {
    return HelpChatMessage(
      id: json['id'] ?? '',
      helpRequestId: json['helpRequestId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: HelpChatMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => HelpChatMessageType.text,
      ),
      metadata: json['metadata'],
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'helpRequestId': helpRequestId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString().split('.').last,
      'metadata': metadata,
      'isRead': isRead,
    };
  }
}

enum HelpChatMessageType {
  text,
  statusUpdate,
  locationShare,
  progressUpdate,
  completionRequest,
  image,
  system,
}

// Enhanced Help Progress Update Model
class HelpProgressUpdate {
  final String id;
  final String helpRequestId;
  final String updaterId;
  final String updaterName;
  final HelpProgressStatus status;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  HelpProgressUpdate({
    required this.id,
    required this.helpRequestId,
    required this.updaterId,
    required this.updaterName,
    required this.status,
    required this.message,
    required this.timestamp,
    this.metadata,
  });

  factory HelpProgressUpdate.fromJson(Map<String, dynamic> json) {
    return HelpProgressUpdate(
      id: json['id'] ?? '',
      helpRequestId: json['helpRequestId'] ?? '',
      updaterId: json['updaterId'] ?? '',
      updaterName: json['updaterName'] ?? '',
      status: HelpProgressStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => HelpProgressStatus.started,
      ),
      message: json['message'] ?? '',
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'helpRequestId': helpRequestId,
      'updaterId': updaterId,
      'updaterName': updaterName,
      'status': status.toString().split('.').last,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

enum HelpProgressStatus {
  started,
  onTheWay,
  arrived,
  helping,
  nearCompletion,
}

// Enhanced Help Completion Model
class HelpCompletionRequest {
  final String id;
  final String helpRequestId;
  final String initiatorId;
  final String initiatorName;
  final HelpCompletionInitiator initiatorType;
  final String message;
  final DateTime requestedAt;
  final HelpCompletionStatus status;
  final DateTime? confirmedAt;
  final String? confirmerId;
  final String? confirmerName;
  final String? confirmerMessage;

  HelpCompletionRequest({
    required this.id,
    required this.helpRequestId,
    required this.initiatorId,
    required this.initiatorName,
    required this.initiatorType,
    required this.message,
    required this.requestedAt,
    required this.status,
    this.confirmedAt,
    this.confirmerId,
    this.confirmerName,
    this.confirmerMessage,
  });

  factory HelpCompletionRequest.fromJson(Map<String, dynamic> json) {
    return HelpCompletionRequest(
      id: json['id'] ?? '',
      helpRequestId: json['helpRequestId'] ?? '',
      initiatorId: json['initiatorId'] ?? '',
      initiatorName: json['initiatorName'] ?? '',
      initiatorType: HelpCompletionInitiator.values.firstWhere(
        (e) => e.toString().split('.').last == json['initiatorType'],
        orElse: () => HelpCompletionInitiator.responder,
      ),
      message: json['message'] ?? '',
      requestedAt: json['requestedAt'] is Timestamp
          ? (json['requestedAt'] as Timestamp).toDate()
          : DateTime.parse(json['requestedAt'] ?? DateTime.now().toIso8601String()),
      status: HelpCompletionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => HelpCompletionStatus.pending,
      ),
      confirmedAt: json['confirmedAt'] != null
          ? (json['confirmedAt'] is Timestamp
              ? (json['confirmedAt'] as Timestamp).toDate()
              : DateTime.parse(json['confirmedAt']))
          : null,
      confirmerId: json['confirmerId'],
      confirmerName: json['confirmerName'],
      confirmerMessage: json['confirmerMessage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'helpRequestId': helpRequestId,
      'initiatorId': initiatorId,
      'initiatorName': initiatorName,
      'initiatorType': initiatorType.toString().split('.').last,
      'message': message,
      'requestedAt': requestedAt.toIso8601String(),
      'status': status.toString().split('.').last,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'confirmerId': confirmerId,
      'confirmerName': confirmerName,
      'confirmerMessage': confirmerMessage,
    };
  }

  bool get isPending => status == HelpCompletionStatus.pending;
  bool get isConfirmed => status == HelpCompletionStatus.confirmed;
  bool get isRejected => status == HelpCompletionStatus.rejected;
}

enum HelpCompletionInitiator {
  requester,
  responder,
}

enum HelpCompletionStatus {
  pending,
  confirmed,
  rejected,
  expired,
}

// Enhanced Help Request Model (extends existing one)
class EnhancedHelpRequest {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String status; // open, in_progress, pending_completion, completed, cancelled
  final String? acceptedResponderUserId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // New fields for in-progress management
  final bool hasChatEnabled;
  final int unreadMessageCount;
  final DateTime? lastMessageAt;
  final String? currentProgressStatus;
  final DateTime? progressUpdatedAt;
  final String? completionRequestId; // ID of pending completion request
  
  // Original help request data
  final Map<String, dynamic> originalData;

  EnhancedHelpRequest({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.status,
    this.acceptedResponderUserId,
    required this.createdAt,
    required this.updatedAt,
    this.hasChatEnabled = false,
    this.unreadMessageCount = 0,
    this.lastMessageAt,
    this.currentProgressStatus,
    this.progressUpdatedAt,
    this.completionRequestId,
    required this.originalData,
  });

  factory EnhancedHelpRequest.fromJson(Map<String, dynamic> json) {
    return EnhancedHelpRequest(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'open',
      acceptedResponderUserId: json['acceptedResponderUserId'],
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] is Timestamp
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      hasChatEnabled: json['hasChatEnabled'] ?? false,
      unreadMessageCount: json['unreadMessageCount'] ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? (json['lastMessageAt'] is Timestamp
              ? (json['lastMessageAt'] as Timestamp).toDate()
              : DateTime.parse(json['lastMessageAt']))
          : null,
      currentProgressStatus: json['currentProgressStatus'],
      progressUpdatedAt: json['progressUpdatedAt'] != null
          ? (json['progressUpdatedAt'] is Timestamp
              ? (json['progressUpdatedAt'] as Timestamp).toDate()
              : DateTime.parse(json['progressUpdatedAt']))
          : null,
      completionRequestId: json['completionRequestId'],
      originalData: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = Map<String, dynamic>.from(originalData);
    result.addAll({
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'status': status,
      'acceptedResponderUserId': acceptedResponderUserId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'hasChatEnabled': hasChatEnabled,
      'unreadMessageCount': unreadMessageCount,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'currentProgressStatus': currentProgressStatus,
      'progressUpdatedAt': progressUpdatedAt?.toIso8601String(),
      'completionRequestId': completionRequestId,
    });
    return result;
  }

  bool get isInProgress => status == 'in_progress';
  bool get isPendingCompletion => status == 'pending_completion';
  bool get isCompleted => status == 'completed';
  bool get hasUnreadMessages => unreadMessageCount > 0;
  bool get hasActiveChatSession => hasChatEnabled && isInProgress;
}

// Chat Session Model
class HelpChatSession {
  final String id;
  final String helpRequestId;
  final String requesterId;
  final String requesterName;
  final String responderId;
  final String responderName;
  final DateTime createdAt;
  final DateTime? lastActivity;
  final bool isActive;
  final int totalMessages;
  final Map<String, int> unreadCounts; // userId -> unread count

  HelpChatSession({
    required this.id,
    required this.helpRequestId,
    required this.requesterId,
    required this.requesterName,
    required this.responderId,
    required this.responderName,
    required this.createdAt,
    this.lastActivity,
    this.isActive = true,
    this.totalMessages = 0,
    required this.unreadCounts,
  });

  factory HelpChatSession.fromJson(Map<String, dynamic> json) {
    return HelpChatSession(
      id: json['id'] ?? '',
      helpRequestId: json['helpRequestId'] ?? '',
      requesterId: json['requesterId'] ?? '',
      requesterName: json['requesterName'] ?? '',
      responderId: json['responderId'] ?? '',
      responderName: json['responderName'] ?? '',
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActivity: json['lastActivity'] != null
          ? (json['lastActivity'] is Timestamp
              ? (json['lastActivity'] as Timestamp).toDate()
              : DateTime.parse(json['lastActivity']))
          : null,
      isActive: json['isActive'] ?? true,
      totalMessages: json['totalMessages'] ?? 0,
      unreadCounts: Map<String, int>.from(json['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'helpRequestId': helpRequestId,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'responderId': responderId,
      'responderName': responderName,
      'createdAt': createdAt.toIso8601String(),
      'lastActivity': lastActivity?.toIso8601String(),
      'isActive': isActive,
      'totalMessages': totalMessages,
      'unreadCounts': unreadCounts,
    };
  }

  int getUnreadCount(String userId) {
    return unreadCounts[userId] ?? 0;
  }
}
