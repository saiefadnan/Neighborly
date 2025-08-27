import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/functions/event_notifier.dart';
import 'package:neighborly/models/event.dart';
import 'package:neighborly/pages/addEvent.dart';

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

  Future<void> _handleRefresh() async {
    // Fetch new events or update state
    await Future.delayed(Duration(seconds: 2));
  }

  // Future<void> fetchEvents() async {
  //   try {
  //     await FirebaseFirestore.instance.collection('events').get().then((
  //       QuerySnapshot querySnapshot,
  //     ) {
  //       setState(() {
  //         events =
  //             querySnapshot.docs
  //                 .map((doc) => doc.data() as Map<String, dynamic>)
  //                 .toList();
  //       });
  //     });
  //   } catch (e) {
  //     print('Error fetching events: $e');
  //   }
  // }

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //await fetchEvents();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvent = ref.watch(eventProvider);
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
      body: asyncEvent.when(
        data:
            (events) => RefreshIndicator(
              onRefresh: _handleRefresh,
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final isSelected = _selectedIndexes.contains(index);
                  // final joined = _joinedIndexes.contains(index);
                  return GestureDetector(
                    onTap: () {
                      EventModel newEvent = EventModel(
                        title: event.title,
                        imageUrl: event.imageUrl,
                        description: event.description,
                        date: event.date,
                        joined: event.joined,
                        location: event.location,
                        lat: (event.lat as num).toDouble(),
                        lng: (event.lng as num).toDouble(),
                        tags: event.tags,
                      );
                      context.push('/eventDetails', extra: newEvent);
                    },
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
                            event.imageUrl!,
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
                                  event.title!,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  event.description!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        loading: () => Center(child: CircularProgressIndicator()),
        error:
            (e, st) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(eventProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  const Center(child: Text('Oops! Something went wrong.')),
                  Center(
                    child: Text(
                      '$e',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: Colors.white,
        child: const Icon(Icons.event_note_sharp),
        onPressed: () async {
          final updatedEvents = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateEventPage(title: 'Add Event'),
            ),
          );

          if (updatedEvents != null) {
            setState(() {
              events = updatedEvents;
            });
          }

          //context.push('/addEvent');
        },
      ),
    );
  }
}
