import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/components/post_card.dart';
import 'package:neighborly/functions/post_notifier.dart';

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
  String selectedCategory = 'all';
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

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'general':
        return const Icon(
          Icons.chat_bubble_outline,
          size: 25,
          color: Colors.yellow,
        );
      case 'urgent':
        return const Icon(
          Icons.schedule_outlined,
          size: 25,
          color: Colors.deepOrange,
        );
      case 'emergency':
        return const Icon(
          Icons.warning_amber_outlined,
          size: 25,
          color: Colors.redAccent,
        );
      case 'ask':
        return const Icon(
          Icons.help_outline,
          size: 25,
          color: Colors.blueAccent,
        );
      case 'news':
        return const Icon(
          Icons.newspaper_outlined,
          size: 25,
          color: Colors.green,
        );
      default:
        return const Icon(Icons.public, size: 25, color: Colors.indigo);
    }
  }

  final List<String> categories = [
    'all',
    'general',
    'urgent',
    'emergency',
    'ask',
    'news',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: categories.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F2E7),
        appBar: AppBar(
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 10),
              child: ElevatedButton(
                onPressed: () => context.push('/eventPlan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.deepOrange, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                ),
                child: Icon(Icons.event, size: 30, color: Colors.deepOrange),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              color: Colors.white, // background color
              height: 48,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      categories.map((cat) {
                        bool isSelected = selectedCategory == cat;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = cat;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected ? Colors.teal : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                _getCategoryIcon(cat),
                                const SizedBox(width: 6),
                                Text(
                                  cat.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),

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
        body: Consumer(
          builder: (context, ref, _) {
            final asyncPosts = ref.watch(postsProvider);
            return asyncPosts.when(
              data: (posts) {
                final filtered =
                    selectedCategory == 'all'
                        ? posts
                        : posts
                            .where(
                              (post) =>
                                  post['category'].toString().toLowerCase() ==
                                  selectedCategory,
                            )
                            .toList();
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(postsProvider);
                  },
                  child:
                      filtered.isNotEmpty
                          ? ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) => PostCard(post: filtered[i]),
                          )
                          : ListView(
                            // wrapped in a ListView so RefreshIndicator still works
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              Center(
                                child: Padding(
                                  padding: EdgeInsets.only(top: 300),
                                  child: Text("No posts found"),
                                ),
                              ),
                            ],
                          ),
                );
              },
              error:
                  (e, _) => RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(postsProvider);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        const Center(
                          child: Text('Oops! Something went wrong.'),
                        ),
                        Center(
                          child: Text(
                            '$e',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

              loading: () => const Center(child: CircularProgressIndicator()),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF71BB7B),
          foregroundColor: Colors.white,
          child: const Icon(Icons.post_add_rounded),
          onPressed: () async {
            context.push('/addPost');
          },
        ),
      ),
    );
  }
}
