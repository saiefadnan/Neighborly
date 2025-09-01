import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/components/post_card.dart';
import 'package:neighborly/notifiers/post_notifier.dart';

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
    Color iconColor =
        selectedCategory == category
            ? const Color(0xFFFAF8F5)
            : const Color(0xFF5F6368);

    switch (category.toLowerCase()) {
      case 'all':
        return Icon(Icons.public_rounded, size: 20, color: iconColor);
      case 'general':
        return Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: iconColor,
        );
      case 'urgent':
        return Icon(Icons.access_time_rounded, size: 20, color: iconColor);
      case 'emergency':
        return Icon(Icons.warning_amber_rounded, size: 20, color: iconColor);
      case 'ask':
        return Icon(Icons.help_outline_rounded, size: 20, color: iconColor);
      case 'news':
        return Icon(Icons.newspaper_rounded, size: 20, color: iconColor);
      default:
        return Icon(Icons.public_rounded, size: 20, color: iconColor);
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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          elevation: 0,
          shadowColor: Colors.transparent,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/eventPlan'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.event,
                          size: 20,
                          color: Color(0xFFFAF8F5),
                        ), // Light cream
                        const SizedBox(width: 8),
                        const Text(
                          'Events',
                          style: TextStyle(
                            color: Color(0xFFFAF8F5), // Light cream
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(68.0),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5), // Light cream instead of white
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              gradient:
                                  isSelected
                                      ? const LinearGradient(
                                        colors: [
                                          Color(0xFF71BB7B),
                                          Color(0xFF5BA55F),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                      : null,
                              color:
                                  isSelected ? null : const Color(0xFFF1F3F4),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF71BB7B,
                                          ).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                      : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedScale(
                                  scale: isSelected ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: _getCategoryIcon(cat),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  cat.toUpperCase(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color:
                                        isSelected
                                            ? const Color(0xFFFAF8F5)
                                            : const Color(0xFF5F6368),
                                    letterSpacing: 0.5,
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFAF8F5,
                        ).withOpacity(0.15), // Light cream
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(
                            0xFFFAF8F5,
                          ).withOpacity(0.2), // Light cream
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Color(
                          0xFFFAF8F5,
                        ), // Light cream instead of white
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: Color(
                              0xFFFAF8F5,
                            ), // Light cream instead of white
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Text(
                          'Community discussions',
                          style: TextStyle(
                            color: Color(
                              0xFFE8E6E3,
                            ), // Slightly darker cream for subtitle
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF71BB7B), Color(0xFF5BA55F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
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
                  color: const Color(0xFF71BB7B),
                  backgroundColor: const Color(
                    0xFFFAF8F5,
                  ), // Light cream instead of white
                  strokeWidth: 2.5,
                  onRefresh: () async {
                    ref.invalidate(postsProvider);
                  },
                  child:
                      filtered.isNotEmpty
                          ? ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(8),
                            itemCount: filtered.length,
                            itemBuilder:
                                (_, i) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: PostCard(post: filtered[i]),
                                  ),
                                ),
                          )
                          : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(24),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F3F4),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(
                                        Icons.forum_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'No ${selectedCategory == 'all' ? '' : selectedCategory} posts yet',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5F6368),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Be the first to start a discussion!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () => context.push('/addPost'),
                                      icon: const Icon(Icons.add, size: 20),
                                      label: const Text('Create Post'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF71BB7B,
                                        ),
                                        foregroundColor: const Color(
                                          0xFFFAF8F5,
                                        ), // Light cream instead of white
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                );
              },
              error:
                  (e, _) => RefreshIndicator(
                    color: const Color(0xFF71BB7B),
                    backgroundColor: const Color(
                      0xFFFAF8F5,
                    ), // Light cream instead of white
                    onRefresh: () async {
                      ref.invalidate(postsProvider);
                    },
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.error_outline,
                                  color: Colors.red,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Oops! Something went wrong',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF5F6368),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pull down to refresh and try again',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$e',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontFamily: 'monospace',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

              loading:
                  () => Container(
                    color: const Color(0xFFF8F9FA),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF71BB7B),
                            ),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading discussions...',
                            style: TextStyle(
                              color: Color(0xFF5F6368),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          heroTag: "forum_fab",
          backgroundColor: const Color(0xFF71BB7B),
          foregroundColor: const Color(0xFFFAF8F5),
          elevation: 4,
          onPressed: () async {
            context.push('/addPost');
          },
          child: const Icon(Icons.add_circle_outline, size: 28),
        ),
      ),
    );
  }
}
