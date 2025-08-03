import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/components/post_card.dart';
import 'package:neighborly/functions/fetchData.dart';

class ForumPage extends ConsumerStatefulWidget {
  const ForumPage({super.key, required this.title});
  final String title;

  @override
  _ForumPageState createState() => _ForumPageState();
}

class _ForumPageState extends ConsumerState<ForumPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncPosts = ref.watch(fetchData('posts'));

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2E7),
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_headerSlideAnimation.value, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.groups,
                      color: Color(0xFFFAF4E8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFFFAF4E8),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: const Color(0xFFFAF4E8),
      ),
      body: asyncPosts.when(
        data:
            (posts) =>
                posts.isNotEmpty
                    ? ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (_, i) => PostCard(post: posts[i]),
                    )
                    : const Center(child: Text("No posts found")),
        error: (e, _) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.post_add_outlined),
        onPressed: () {
          context.push('/addpost');
        },
      ),
    );
  }
}
