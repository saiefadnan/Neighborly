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

  List<Map<String, dynamic>> getPosts() {
    return state.maybeWhen(data: (posts) => posts, orElse: () => []);
  }

  void clearPosts() {
    state = const AsyncData([]);
  }
}
