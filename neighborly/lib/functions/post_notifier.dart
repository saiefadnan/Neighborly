import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final postsProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<List<Map<String, dynamic>>>>(
      (ref) => PostNotifier(ref),
    );

class PostNotifier
    extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final Ref ref;

  PostNotifier(this.ref) : super(AsyncLoading()) {
    loadPosts();
  }

  Future<void> loadPosts() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('posts').get();
      final posts = querySnapshot.docs.map((doc) => {...doc.data()}).toList();
      state = AsyncData(posts);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void addPosts(Map<String, dynamic> post) {
    state = state.when(
      data: (posts) => AsyncData([post, ...posts]),
      error: (e, st) => state,
      loading: () => state,
    );
  }

  void updateCommentCount(String id) {
    state = state.when(
      data: (posts) {
        final updated =
            posts.map((post) {
              if (post['postID'] == id) {
                return {...post, 'totalComments': post['totalComments'] + 1};
              }
              return post;
            }).toList();
        return AsyncData(updated);
      },
      error: (e, st) => state,
      loading: () => state,
    );
  }

  void updateReactCount(String id) {
    state = state.when(
      data: (posts) {
        final updated =
            posts.map((post) {
              if (post['postID'] == id) {
                return {...post, 'totalComments': post['reacts'] + 1};
              }
              return post;
            }).toList();
        return AsyncData(updated);
      },
      error: (e, st) => state,
      loading: () => state,
    );
  }

  List<Map<String, dynamic>> getPosts() {
    return state.maybeWhen(data: (posts) => posts, orElse: () => []);
  }

  void clearPosts() {
    state = const AsyncData([]);
  }
}
