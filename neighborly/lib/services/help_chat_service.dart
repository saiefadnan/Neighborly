import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neighborly/models/help_chat_models.dart';
import 'package:neighborly/services/notification_service.dart';

class HelpChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  // Send a chat message
  Future<Map<String, dynamic>> sendMessage({
    required String helpRequestId,
    required String senderId,
    required String senderName,
    required String message,
    required HelpChatMessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final chatMessage = HelpChatMessage(
        id: '', // Will be set by Firestore
        helpRequestId: helpRequestId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        metadata: metadata,
      );

      final docRef = await _firestore
          .collection('helpChats')
          .doc(helpRequestId)
          .collection('messages')
          .add(chatMessage.toJson());

      // Update chat session's last message
      await _updateChatSession(helpRequestId, message, DateTime.now());

      // Send notification to other party
      await _sendChatNotification(helpRequestId, senderId, senderName, message);

      return {'success': true, 'messageId': docRef.id};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Get chat messages stream
  Stream<QuerySnapshot> getChatMessages(String helpRequestId) {
    return _firestore
        .collection('helpChats')
        .doc(helpRequestId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Send progress update
  Future<void> sendProgressUpdate({
    required String helpRequestId,
    required String updaterId,
    required String updaterName,
    required HelpProgressStatus status,
    required String message,
  }) async {
    try {
      final progressUpdate = HelpProgressUpdate(
        id: '', // Will be set by Firestore
        helpRequestId: helpRequestId,
        updaterId: updaterId,
        updaterName: updaterName,
        status: status,
        message: message,
        timestamp: DateTime.now(),
      );

      // Save progress update
      await _firestore
          .collection('helpProgress')
          .doc(helpRequestId)
          .collection('updates')
          .add(progressUpdate.toJson());

      // Update the help request's current status
      await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .update({
        'currentProgressStatus': status.toString().split('.').last,
        'lastProgressUpdate': progressUpdate.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification about progress update
      await _sendProgressNotification(helpRequestId, updaterName, message);
    } catch (e) {
      throw Exception('Failed to send progress update: $e');
    }
  }

  // Request completion
  Future<void> requestCompletion({
    required String helpRequestId,
    required String initiatorId,
    required String initiatorName,
    required HelpCompletionInitiator initiatorType,
    required String message,
  }) async {
    try {
      final completionRequest = HelpCompletionRequest(
        id: '', // Will be set by Firestore
        helpRequestId: helpRequestId,
        initiatorId: initiatorId,
        initiatorName: initiatorName,
        initiatorType: initiatorType,
        status: HelpCompletionStatus.pending,
        message: message,
        requestedAt: DateTime.now(),
      );

      // Save completion request
      await _firestore
          .collection('helpCompletions')
          .doc(helpRequestId)
          .set(completionRequest.toJson());

      // Update help request status to pending completion
      await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .update({
        'status': 'pending_completion',
        'completionRequest': completionRequest.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Send notification to other party for confirmation
      await _sendCompletionRequestNotification(
        helpRequestId, 
        initiatorName, 
        message,
        initiatorType,
      );
    } catch (e) {
      throw Exception('Failed to request completion: $e');
    }
  }

  // Confirm completion
  Future<void> confirmCompletion({
    required String helpRequestId,
    required String confirmerId,
    required String confirmerName,
    required bool approved,
    String? feedback,
  }) async {
    try {
      // Update completion request
      await _firestore
          .collection('helpCompletions')
          .doc(helpRequestId)
          .update({
        'status': approved 
            ? HelpCompletionStatus.confirmed.toString().split('.').last
            : HelpCompletionStatus.rejected.toString().split('.').last,
        'confirmerId': confirmerId,
        'confirmerName': confirmerName,
        'confirmedAt': FieldValue.serverTimestamp(),
        'feedback': feedback,
      });

      if (approved) {
        // Mark help request as completed
        await _firestore
            .collection('helpedRequests')
            .doc(helpRequestId)
            .update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Also update the original help request
        await _updateOriginalHelpRequestStatus(helpRequestId, 'completed');

        // Award XP to both parties
        await _awardCompletionXP(helpRequestId);

        // Send completion confirmation notification
        await _sendCompletionConfirmedNotification(helpRequestId, confirmerName);
      } else {
        // Revert to in_progress status
        await _firestore
            .collection('helpedRequests')
            .doc(helpRequestId)
            .update({
          'status': 'in_progress',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send rejection notification
        await _sendCompletionRejectedNotification(helpRequestId, confirmerName, feedback);
      }
    } catch (e) {
      throw Exception('Failed to confirm completion: $e');
    }
  }

  // Mark messages as read
  Future<void> markMessagesAsRead(String helpRequestId, String userId) async {
    try {
      final batch = _firestore.batch();
      
      final unreadMessages = await _firestore
          .collection('helpChats')
          .doc(helpRequestId)
          .collection('messages')
          .where('senderId', isNotEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadMessages.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      // Silently fail - not critical
      print('Failed to mark messages as read: $e');
    }
  }

  // Get chat session
  Future<HelpChatSession?> getChatSession(String helpRequestId) async {
    try {
      final doc = await _firestore
          .collection('helpChats')
          .doc(helpRequestId)
          .get();

      if (doc.exists) {
        return HelpChatSession.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get chat session: $e');
    }
  }

  // Get progress updates stream
  Stream<QuerySnapshot> getProgressUpdates(String helpRequestId) {
    return _firestore
        .collection('helpProgress')
        .doc(helpRequestId)
        .collection('updates')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // Get completion request
  Future<HelpCompletionRequest?> getCompletionRequest(String helpRequestId) async {
    try {
      final doc = await _firestore
          .collection('helpCompletions')
          .doc(helpRequestId)
          .get();

      if (doc.exists) {
        return HelpCompletionRequest.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get completion request: $e');
    }
  }

  // Private helper methods
  Future<void> _updateChatSession(String helpRequestId, String lastMessage, DateTime timestamp) async {
    try {
      // Get help request details to create proper chat session
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) return;

      final data = helpedRequest.data() as Map<String, dynamic>;
      
      final chatSession = HelpChatSession(
        id: helpRequestId,
        helpRequestId: helpRequestId,
        requesterId: data['requesterId'] as String,
        requesterName: data['requesterName'] as String,
        responderId: data['responderId'] as String,
        responderName: data['responderName'] as String,
        createdAt: timestamp,
        unreadCounts: {
          data['requesterId'] as String: 0,
          data['responderId'] as String: 0,
        },
      );

      await _firestore
          .collection('helpChats')
          .doc(helpRequestId)
          .set(chatSession.toJson(), SetOptions(merge: true));
    } catch (e) {
      // Non-critical, continue
      print('Failed to update chat session: $e');
    }
  }

  Future<void> _sendChatNotification(String helpRequestId, String senderId, String senderName, String message) async {
    try {
      // Get the help request to find the other party
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) return;

      final data = helpedRequest.data() as Map<String, dynamic>;
      final requesterId = data['requesterId'] as String;
      final responderId = data['responderId'] as String;
      
      // Determine recipient (the other party)
      final recipientId = senderId == requesterId ? responderId : requesterId;

      await _notificationService.sendNotification(
        userId: recipientId,
        title: 'New message from $senderName',
        body: message.length > 50 ? '${message.substring(0, 50)}...' : message,
        type: 'help_chat',
        data: {
          'helpRequestId': helpRequestId,
          'senderId': senderId,
          'senderName': senderName,
        },
      );
    } catch (e) {
      print('Failed to send chat notification: $e');
    }
  }

  Future<void> _sendProgressNotification(String helpRequestId, String updaterName, String message) async {
    try {
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) return;

      final data = helpedRequest.data() as Map<String, dynamic>;
      final requesterId = data['requesterId'] as String;

      await _notificationService.sendNotification(
        userId: requesterId,
        title: 'Progress Update',
        body: '$updaterName: $message',
        type: 'help_progress',
        data: {
          'helpRequestId': helpRequestId,
          'updaterName': updaterName,
          'message': message,
        },
      );
    } catch (e) {
      print('Failed to send progress notification: $e');
    }
  }

  Future<void> _sendCompletionRequestNotification(
    String helpRequestId, 
    String initiatorName, 
    String message,
    HelpCompletionInitiator initiatorType,
  ) async {
    try {
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) return;

      final data = helpedRequest.data() as Map<String, dynamic>;
      final requesterId = data['requesterId'] as String;
      final responderId = data['responderId'] as String;
      
      // Send to the other party
      final recipientId = initiatorType == HelpCompletionInitiator.requester 
          ? responderId 
          : requesterId;

      await _notificationService.sendNotification(
        userId: recipientId,
        title: 'Completion Request',
        body: '$initiatorName wants to mark the help as complete: $message',
        type: 'completion_request',
        data: {
          'helpRequestId': helpRequestId,
          'initiatorName': initiatorName,
          'message': message,
          'action': 'confirm_completion',
        },
      );
    } catch (e) {
      print('Failed to send completion request notification: $e');
    }
  }

  Future<void> _sendCompletionConfirmedNotification(String helpRequestId, String confirmerName) async {
    try {
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) return;

      final data = helpedRequest.data() as Map<String, dynamic>;
      final requesterId = data['requesterId'] as String;
      final responderId = data['responderId'] as String;

      // Send to both parties
      for (final userId in [requesterId, responderId]) {
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Help Completed! 🎉',
          body: '$confirmerName confirmed the help is complete. Great job!',
          type: 'help_completed',
          data: {
            'helpRequestId': helpRequestId,
            'confirmerName': confirmerName,
          },
        );
      }
    } catch (e) {
      print('Failed to send completion confirmed notification: $e');
    }
  }

  Future<void> _sendCompletionRejectedNotification(String helpRequestId, String confirmerName, String? feedback) async {
    try {
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) return;

      final data = helpedRequest.data() as Map<String, dynamic>;
      final requesterId = data['requesterId'] as String;
      final responderId = data['responderId'] as String;

      // Send to both parties
      for (final userId in [requesterId, responderId]) {
        await _notificationService.sendNotification(
          userId: userId,
          title: 'Completion Request Declined',
          body: feedback != null 
              ? '$confirmerName declined: $feedback'
              : '$confirmerName thinks more work is needed',
          type: 'completion_rejected',
          data: {
            'helpRequestId': helpRequestId,
            'confirmerName': confirmerName,
            'feedback': feedback,
          },
        );
      }
    } catch (e) {
      print('Failed to send completion rejected notification: $e');
    }
  }

  Future<void> _updateOriginalHelpRequestStatus(String helpRequestId, String status) async {
    try {
      print('DEBUG: Attempting to update original help request status for $helpRequestId to $status');
      
      // Find the original help request
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) {
        print('DEBUG: helpedRequest not found for $helpRequestId');
        return;
      }

      final data = helpedRequest.data() as Map<String, dynamic>;
      
      // Fix: Use 'requestId' which is the actual field name in the document
      final originalRequestId = data['requestId'] as String?;
      
      print('DEBUG: originalRequestId found: $originalRequestId');

      if (originalRequestId != null && originalRequestId.isNotEmpty) {
        await _firestore
            .collection('helpRequests')
            .doc(originalRequestId)
            .update({
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('DEBUG: Successfully updated helpRequests/$originalRequestId status to $status');
      } else {
        print('DEBUG: No requestId found in helpedRequest data');
        print('DEBUG: Available fields: ${data.keys.toList()}');
      }
    } catch (e) {
      print('DEBUG: Error updating original help request status: $e');
    }
  }

  Future<void> _awardCompletionXP(String helpRequestId) async {
    try {
      final helpedRequest = await _firestore
          .collection('helpedRequests')
          .doc(helpRequestId)
          .get();

      if (!helpedRequest.exists) return;

      final data = helpedRequest.data() as Map<String, dynamic>;
      final requesterId = data['requesterId'] as String;
      final responderId = data['responderId'] as String;

      // Award XP to both parties
      const int xpReward = 10; // Completion bonus

      final batch = _firestore.batch();

      // Requester gets XP for completing the request
      final requesterRef = _firestore.collection('users').doc(requesterId);
      batch.update(requesterRef, {
        'xp': FieldValue.increment(xpReward),
        'completedRequests': FieldValue.increment(1),
      });

      // Responder gets XP for helping
      final responderRef = _firestore.collection('users').doc(responderId);
      batch.update(responderRef, {
        'xp': FieldValue.increment(xpReward * 2), // Double XP for helping
        'completedHelps': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      print('Failed to award completion XP: $e');
    }
  }

  // Delete entire chat session and all messages permanently
  Future<void> deleteChat(String helpRequestId) async {
    try {
      final batch = _firestore.batch();

      // Get all messages in the chat
      final messagesSnapshot = await _firestore
          .collection('helpChats')
          .doc(helpRequestId)
          .collection('messages')
          .get();

      // Delete all messages
      for (final messageDoc in messagesSnapshot.docs) {
        batch.delete(messageDoc.reference);
      }

      // Delete the chat session document
      final chatRef = _firestore.collection('helpChats').doc(helpRequestId);
      batch.delete(chatRef);

      await batch.commit();
      print('Chat $helpRequestId permanently deleted');
    } catch (e) {
      print('Error deleting chat: $e');
      rethrow;
    }
  }
}
