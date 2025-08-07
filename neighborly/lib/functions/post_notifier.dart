import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/functions/fetchData.dart';

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
      final response = await ref.read(fetchData('posts').future);
      state = AsyncData(response);
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

  void clearPosts() {
    state = const AsyncData([]);
  }
}
