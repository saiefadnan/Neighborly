import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String selectedScope = 'community'; // 'community' or 'explore'

  void _refreshPosts() {
    final postNotifier = ref.read(postsProvider.notifier);
    if (selectedScope == 'community') {
      postNotifier.loadNearByPosts();
    } else {
      postNotifier.loadExplorePosts();
    }
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              color: Color(0xFFFAF8F5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5F6368).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Filter by Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.5,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = selectedCategory == cat;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedCategory = cat;
                          });
                          Navigator.pop(context);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? const LinearGradient(
                                      colors: [
                                        Color(0xFF71BB7B),
                                        Color(0xFF5BA55F),
                                      ],
                                    )
                                    : null,
                            color: isSelected ? null : const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(16),
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
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _getCategoryIcon(cat),
                              const SizedBox(height: 4),
                              Text(
                                cat.toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                  color:
                                      isSelected
                                          ? const Color(0xFFFAF8F5)
                                          : const Color(0xFF5F6368),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

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
    print('ForumPage initialized');
    // Load community posts by default after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshPosts();
    });
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
        return Icon(Icons.public_rounded, size: 16, color: iconColor);
      case 'my posts':
        return Icon(Icons.person_outline_rounded, size: 16, color: iconColor);
      case 'general':
        return Icon(
          Icons.chat_bubble_outline_rounded,
          size: 16,
          color: iconColor,
        );
      case 'urgent':
        return Icon(Icons.priority_high_rounded, size: 16, color: iconColor);
      case 'emergency':
        return Icon(Icons.warning_rounded, size: 16, color: iconColor);
      case 'ask':
        return Icon(Icons.help_outline_rounded, size: 16, color: iconColor);
      case 'news':
        return Icon(Icons.newspaper_rounded, size: 16, color: iconColor);
      default:
        return Icon(Icons.public_rounded, size: 16, color: iconColor);
    }
  }

  final List<String> categories = [
    'all',
    'my posts',
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
          backgroundColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16, top: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF8C42), Color(0xFFFF6B1A)],
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
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Events',
                          style: TextStyle(
                            color: Color(0xFFFAF8F5),
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
            preferredSize: const Size.fromHeight(48.0), // Compact single row
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    // Community/Explore Toggle
                    Expanded(
                      child: Container(
                        height: 42, // Increased from 32 to 42
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F3F4),
                          borderRadius: BorderRadius.circular(
                            22,
                          ), // Adjusted to match height
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedScope = 'community';
                                  });
                                  _refreshPosts();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    gradient:
                                        selectedScope == 'community'
                                            ? const LinearGradient(
                                              colors: [
                                                Color(0xFF71BB7B),
                                                Color(0xFF5BA55F),
                                              ],
                                            )
                                            : null,
                                    borderRadius: BorderRadius.circular(
                                      20,
                                    ), // Increased to match container height
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.home_outlined,
                                          size: 16, // Increased from 14 to 16
                                          color:
                                              selectedScope == 'community'
                                                  ? const Color(0xFFFAF8F5)
                                                  : const Color(0xFF5F6368),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ), // Increased from 4 to 6
                                        Text(
                                          'Community',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize:
                                                12, // Increased from 10 to 12
                                            color:
                                                selectedScope == 'community'
                                                    ? const Color(0xFFFAF8F5)
                                                    : const Color(0xFF5F6368),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedScope = 'explore';
                                  });
                                  _refreshPosts();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    gradient:
                                        selectedScope == 'explore'
                                            ? const LinearGradient(
                                              colors: [
                                                Color(0xFF71BB7B),
                                                Color(0xFF5BA55F),
                                              ],
                                            )
                                            : null,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.explore_outlined,
                                          size: 16, // Increased from 14 to 16
                                          color:
                                              selectedScope == 'explore'
                                                  ? const Color(0xFFFAF8F5)
                                                  : const Color(0xFF5F6368),
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ), // Increased from 4 to 6
                                        Text(
                                          'Explore',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize:
                                                12, // Increased from 10 to 12
                                            color:
                                                selectedScope == 'explore'
                                                    ? const Color(0xFFFAF8F5)
                                                    : const Color(0xFF5F6368),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Category Filter Button
                    GestureDetector(
                      onTap: _showCategoryFilter,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 42, // Match the Community/Explore toggle height
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16, // Increased from 12
                          vertical: 8, // Increased from 6
                        ),
                        decoration: BoxDecoration(
                          gradient:
                              selectedCategory != 'all'
                                  ? const LinearGradient(
                                    colors: [
                                      Color(0xFF71BB7B),
                                      Color(0xFF5BA55F),
                                    ],
                                  )
                                  : null,
                          color:
                              selectedCategory == 'all'
                                  ? const Color(0xFFF1F3F4)
                                  : null,
                          borderRadius: BorderRadius.circular(
                            22,
                          ), // Increased to match
                          border:
                              selectedCategory != 'all'
                                  ? null
                                  : Border.all(
                                    color: const Color(
                                      0xFF5F6368,
                                    ).withOpacity(0.3),
                                  ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.filter_list_rounded,
                              size: 16, // Increased from 14 to 16
                              color:
                                  selectedCategory != 'all'
                                      ? const Color(0xFFFAF8F5)
                                      : const Color(0xFF5F6368),
                            ),
                            const SizedBox(width: 6), // Increased from 4 to 6
                            Text(
                              selectedCategory == 'all'
                                  ? 'Filter'
                                  : selectedCategory.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12, // Increased from 10 to 12
                                color:
                                    selectedCategory != 'all'
                                        ? const Color(0xFFFAF8F5)
                                        : const Color(0xFF5F6368),
                              ),
                            ),
                            if (selectedCategory != 'all') ...[
                              const SizedBox(width: 6), // Increased from 4 to 6
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedCategory = 'all';
                                  });
                                },
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 12,
                                  color: Color(0xFFFAF8F5),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
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
                        color: const Color(0xFFFAF8F5).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFFAF8F5).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Color(0xFFFAF8F5),
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
                            color: Color(0xFFFAF8F5),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          selectedScope == 'community'
                              ? 'Your community'
                              : 'Explore neighborhoods',
                          style: const TextStyle(
                            color: Color(0xFFE8E6E3),
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
                        : selectedCategory == 'my posts'
                        ? posts.where((post) {
                          // Get current user ID from FirebaseAuth
                          final currentUserId =
                              FirebaseAuth.instance.currentUser?.uid;
                          return post['authorID'] == currentUserId;
                        }).toList()
                        : posts
                            .where(
                              (post) =>
                                  post['category'].toString().toLowerCase() ==
                                  selectedCategory,
                            )
                            .toList();
                return RefreshIndicator(
                  color: const Color(0xFF71BB7B),
                  backgroundColor: const Color(0xFFFAF8F5),
                  strokeWidth: 2.5,
                  onRefresh: () async {
                    _refreshPosts();
                  },
                  child:
                      filtered.isNotEmpty
                          ? ListView.builder(
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: false,
                            cacheExtent: 200,
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
                                        color: const Color(
                                          0xFF71BB7B,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: const Icon(
                                        Icons.forum_rounded,
                                        size: 64,
                                        color: Color(0xFF71BB7B),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      selectedScope == 'community'
                                          ? (selectedCategory == 'my posts'
                                              ? 'You haven\'t posted anything yet'
                                              : 'No posts in your community yet')
                                          : (selectedCategory == 'my posts'
                                              ? 'You haven\'t posted anything yet'
                                              : 'No posts to explore yet'),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5F6368),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      selectedScope == 'community'
                                          ? (selectedCategory == 'my posts'
                                              ? 'Start sharing with your community!\nCreate your first post below.'
                                              : 'Be the first to start a conversation\nin your neighborhood!')
                                          : (selectedCategory == 'my posts'
                                              ? 'Start sharing with your community!\nCreate your first post below.'
                                              : 'Check back later for posts from\nother communities!'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: const Color(
                                          0xFF5F6368,
                                        ).withOpacity(0.7),
                                        height: 1.4,
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
                  (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF5F6368).withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshPosts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
              loading:
                  () => const Center(
                    child: CircularProgressIndicator(color: Color(0xFF71BB7B)),
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
