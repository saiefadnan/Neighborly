import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/post_card.dart';
import 'package:neighborly/functions/fetchData.dart';

class ForumPage extends ConsumerWidget {
  const ForumPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(fetchData('posts'));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: asyncPosts.when(
        data: (posts) => posts.isNotEmpty
            ? ListView.builder(
                itemCount: posts.length,
                itemBuilder: (_, i) => PostCard(post: posts[i]),
              )
            : const Center(child: Text("No posts found")),
        error: (e, _) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
