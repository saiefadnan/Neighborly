import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/components/snackbar.dart';

class EventPlan extends ConsumerStatefulWidget {
  final String title;
  const EventPlan({super.key, required this.title});
  @override
  ConsumerState<EventPlan> createState() => _EventPlanState();
}

class _EventPlanState extends ConsumerState<EventPlan>
    with SingleTickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late Animation<double> _headerSlideAnimation;
  final Set<int> _selectedIndexes = {};
  final Set<int> _joinedIndexes = {};
  final List<Map<String, String>> events = [
    {
      "title": "Tree Plantation",
      "desc": "Join us this Sunday to plant trees in the local park.",
      "img":
          "https://res.cloudinary.com/dpmgqsubd/image/upload/v1754651502/vitor-monthay-EkEdHarUPTs-unsplash_qsvwhr.jpg",
    },
    {
      "title": "Invitation Party",
      "desc": "Celebrate the new season with your neighbors.",
      "img":
          "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80",
    },
    {
      "title": "Health Camp",
      "desc": "Free health check-up and consultation.",
      "img":
          "https://res.cloudinary.com/dpmgqsubd/image/upload/v1754651567/tegan-mierle-fDostElVhN8-unsplash_kackpp.jpg",
    },
    {
      "title": "Community Clean-up",
      "desc": "Let’s clean our streets together!",
      "img":
          "https://res.cloudinary.com/dpmgqsubd/image/upload/v1754651680/zhang-kaiyv-QHFlhvQQFbQ-unsplash_dnlzqz.jpg",
    },
    {
      "title": "Book Swap",
      "desc": "Bring a book, take a book. Simple!",
      "img":
          "https://images.unsplash.com/photo-1519681393784-d120267933ba?auto=format&fit=crop&w=800&q=80",
    },
    {
      "title": "Potluck Dinner",
      "desc": "Share your favorite dish with the community.",
      "img":
          "https://images.unsplash.com/photo-1498654896293-37aacf113fd9?auto=format&fit=crop&w=800&q=80",
    },
  ];

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
                      Icons.event,
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
      body: MasonryGridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        padding: const EdgeInsets.all(12),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final isSelected = _selectedIndexes.contains(index);
          final joined = _joinedIndexes.contains(index);
          return GestureDetector(
            onTap:
                () => setState(() {
                  isSelected
                      ? _selectedIndexes.remove(index)
                      : _selectedIndexes.add(index);
                }),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              color: Colors.white,
              elevation: isSelected ? 8 : 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Image
                  Image.network(
                    event['img']!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                  // Event Text
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event['title']!,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          event['desc']!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),

                  isSelected
                      ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  if (joined) {
                                    _joinedIndexes.remove(index);
                                    showSnackBarError(
                                      context,
                                      'You canceled the event!',
                                    );
                                  } else {
                                    _joinedIndexes.add(index);
                                    showSnackBarSuccess(
                                      context,
                                      'You joined the event!',
                                    );
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    !joined
                                        ? Colors.green
                                        : Colors.red, // button color
                                foregroundColor: Colors.white, // text color
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child:
                                  !joined
                                      ? Text(
                                        "Join",
                                        style: TextStyle(color: Colors.white),
                                      )
                                      : Text(
                                        "Cancel",
                                        style: TextStyle(color: Colors.white),
                                      ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                // showSnackBarError(
                                //   context,
                                //   'You joined the event!',
                                // );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.deepOrange, // button color
                                foregroundColor: Colors.white, // text color
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                "Details",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                      : SizedBox.shrink(),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.event_note_sharp),
        onPressed: () {
          context.push('/addEvent');
        },
      ),
    );
  }
}
