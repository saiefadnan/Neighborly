import 'package:flutter_riverpod/flutter_riverpod.dart';

final commentsProvider =
    StateNotifierProvider<CommentsNotifier, List<Map<String, dynamic>>>((ref) {
      return CommentsNotifier();
    });

class CommentsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  CommentsNotifier() : super([]);

  void setComments(List<Map<String, dynamic>> newComments) {
    state = newComments;
  }

  void addComment(Map<String, dynamic> comment, final replyTo) {
    if (replyTo == null) {
      state = [comment, ...state];
    } // add new comment to list
    else {
      state = [...state, comment];
    }
  }
}
