import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:neighborly/functions/post_notifier.dart';

final commentsProvider = StateNotifierProvider.family<
  CommentsNotifier,
  AsyncValue<List<Map<String, dynamic>>>,
  String
>((ref, postID) => CommentsNotifier(ref, postID));

class CommentsNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final ref;
  final String postID;

  CommentsNotifier(this.ref, this.postID) : super(AsyncLoading()) {
    loadComments();
  }

  void setComments(List<Map<String, dynamic>> newComments) {
    state = AsyncData(newComments);
  }

  Future<void> loadComments() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(postID)
              .collection('comments')
              .get();
      final comments =
          querySnapshot.docs.map((doc) => {...doc.data()}).toList();
      state = AsyncData(comments);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<bool> backUpStoreComment(Map<String, dynamic> commentData) async {
    try {
      final String postID = commentData['postID'];
      final String commentID = commentData['commentID'];

      if (postID.isEmpty ||
          commentData['authorID'] == null ||
          commentData['content'] == null ||
          commentID.isEmpty) {
        print('Invalid data: $commentData');
        return false;
      }

      final data = {
        ...commentData,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(postID)
          .collection('comments')
          .doc(commentID)
          .set(data);

      await FirebaseFirestore.instance.collection('posts').doc(postID).update({
        'totalComments': FieldValue.increment(1),
      });

      ref.read(postsProvider.notifier).updateCommentCount(postID);
      print('Comment stored and incremented on post successfully: $data');
      return true;
    } catch (e) {
      print('Error storing comment: $e');
      return false;
    }
  }

  Future<bool> storeComments(Map<String, dynamic> commentData) async {
    final baseUrl = dotenv.env['BASE_URL'];
    final url = Uri.parse('${baseUrl}/api/forum/store/comments');
    print(commentData);
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(commentData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'];
      } else {
        await backUpStoreComment(commentData);
        return false;
      }
    } catch (e) {
      await backUpStoreComment(commentData);
      return false;
    }
  }

  void addComment(Map<String, dynamic> comment, {String? replyTo}) {
    state = state.when(
      data: (comments) {
        // Prepend top-level comments, append replies
        final updatedComments =
            replyTo == null ? [comment, ...comments] : [...comments, comment];
        return AsyncData(updatedComments);
      },
      loading: () => state,
      error: (_, __) => state,
    );
  }
}
