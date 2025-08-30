import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/notifiers/event_notifier.dart';
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
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        elevation: 0,
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
                      color: const Color(0xFF71BB7B).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Color(0xFF2C3E50),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        surfaceTintColor: Colors.transparent,
      ),
      body: asyncEvent.when(
        data:
            (events) => RefreshIndicator(
              onRefresh: ref.read(eventProvider.notifier).handleRefresh,
              color: const Color(0xFF71BB7B),
              child:
                  events.isEmpty
                      ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 100),
                          Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF71BB7B,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.event_busy_rounded,
                                    size: 48,
                                    color: Color(0xFF71BB7B),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "No Events Available",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "No events in your area right now.\nCheck back later or create a new event!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF5F6368),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                      : MasonryGridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        padding: const EdgeInsets.all(20),
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          final isSelected = _selectedIndexes.contains(index);

                          return GestureDetector(
                            onTap: () {
                              EventModel newEvent = EventModel(
                                id: event.id,
                                title: event.title,
                                imageUrl: event.imageUrl,
                                description: event.description,
                                createdAt: event.createdAt,
                                approved: event.approved,
                                location: event.location,
                                lat: (event.lat as num).toDouble(),
                                lng: (event.lng as num).toDouble(),
                                raduis: (event.raduis as num).toDouble(),
                                tags: event.tags,
                              );
                              context.push('/eventDetails', extra: newEvent);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.1),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isSelected ? 0.12 : 0.06,
                                    ),
                                    blurRadius: isSelected ? 16 : 8,
                                    offset: Offset(0, isSelected ? 6 : 3),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Event Image
                                  Stack(
                                    children: [
                                      Container(
                                        height: 140,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              const Color(
                                                0xFF71BB7B,
                                              ).withOpacity(0.1),
                                              const Color(
                                                0xFF71BB7B,
                                              ).withOpacity(0.05),
                                            ],
                                          ),
                                        ),
                                        child: Image.network(
                                          event.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return Container(
                                              color: const Color(0xFFFAF8F5),
                                              child: const Center(
                                                child: Icon(
                                                  Icons
                                                      .image_not_supported_rounded,
                                                  size: 32,
                                                  color: Color(0xFF71BB7B),
                                                ),
                                              ),
                                            );
                                          },
                                          loadingBuilder: (
                                            context,
                                            child,
                                            loadingProgress,
                                          ) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Container(
                                              color: const Color(0xFFFAF8F5),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Color(0xFF71BB7B)),
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      // Tags overlay
                                      if (event.tags.isNotEmpty)
                                        Positioned(
                                          top: 8,
                                          left: 8,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF71BB7B),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Text(
                                              event.tags.first.replaceAll(
                                                '#',
                                                '',
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  // Event Content
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C3E50),
                                            height: 1.2,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          event.description,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF5F6368),
                                            height: 1.3,
                                          ),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFF71BB7B,
                                                ).withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.location_on_rounded,
                                                size: 12,
                                                color: Color(0xFF71BB7B),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                event.location,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Color(0xFF5F6368),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
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
        loading:
            () => Container(
              color: const Color(0xFFFAF8F5),
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
                      "Loading events...",
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
        error:
            (e, st) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(eventProvider),
              color: const Color(0xFF71BB7B),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline_rounded,
                            size: 48,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Oops! Something went wrong",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "We couldn't load the events right now.\nPull down to refresh and try again.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F6368),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$e',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
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
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF71BB7B).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          heroTag: "create_event_fab",
          backgroundColor: const Color(0xFF71BB7B),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CreateEventPage(title: 'Add Event'),
              ),
            );
          },
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text(
            'Create Event',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
