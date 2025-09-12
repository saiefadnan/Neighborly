import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/models/event.dart';
import 'package:neighborly/notifiers/event_notifier.dart';
import 'package:neighborly/pages/addEvent.dart';

class EventPlan extends ConsumerStatefulWidget {
  final String title;
  const EventPlan({super.key, required this.title});

  @override
  ConsumerState<EventPlan> createState() => _EventPlanState();
}

class _EventPlanState extends ConsumerState<EventPlan>
    with TickerProviderStateMixin {
  final Set<int> _selectedIndexes = <int>{};
  late AnimationController _animationController;
  late Animation<double> _headerSlideAnimation;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();

    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    try {
      await ref.read(eventProvider.notifier).handleRefresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Events refreshed successfully!',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF71BB7B),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Text(
                  'Failed to refresh events',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  List<EventModel> _getUpcomingEvents(List<EventModel> events) {
    final now = DateTime.now();
    return events.where((event) {
      final eventDate = event.date;
      return eventDate.isAfter(now) || eventDate.isAtSameMomentAs(now);
    }).toList();
  }

  List<EventModel> _getMyEvents(List<EventModel> events) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return events.where((event) => event.creatorId == currentUserId).toList();
  }

  List<EventModel> _getJoinedEvents(List<EventModel> events) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return events.where((event) => event.joined).toList();
  }

  List<EventModel> _getPastEvents(List<EventModel> events) {
    final now = DateTime.now();
    return events.where((event) {
      final eventDate = event.date;
      return eventDate.isBefore(now);
    }).toList();
  }

  Widget _buildEventGrid(List<EventModel> events, String emptyMessage) {
    print('hello');
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: const Color(0xFF71BB7B),
      backgroundColor: Colors.white,
      strokeWidth: 3,
      displacement: 40,
      child:
          events.isEmpty
              ? ListView(
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                cacheExtent: 200,
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
                            color: const Color(0xFF71BB7B).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.event_busy_rounded,
                            size: 48,
                            color: Color(0xFF71BB7B),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          emptyMessage,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Check back later or create a new event!",
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
                  return _buildEventCard(event, isSelected, index);
                },
              ),
    );
  }

  Widget _buildEventCard(EventModel event, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        EventModel newEvent = EventModel(
          id: event.id,
          creatorId: event.creatorId,
          title: event.title,
          imageUrl: event.imageUrl,
          description: event.description,
          createdAt: event.createdAt,
          approved: event.approved,
          location: event.location,
          lat: (event.lat as num).toDouble(),
          lng: (event.lng as num).toDouble(),
          radius: (event.radius as num).toDouble(),
          tags: event.tags,
          date: event.date,
        );
        context.push('/eventDetails', extra: newEvent);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF71BB7B).withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.06),
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
                        const Color(0xFF71BB7B).withOpacity(0.1),
                        const Color(0xFF71BB7B).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Image.network(
                    event.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFFAF8F5),
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_rounded,
                            size: 32,
                            color: Color(0xFF71BB7B),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }
                      return Container(
                        height: 140,
                        width: double.infinity,
                        color: const Color(0xFFFAF8F5),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF71BB7B),
                            ),
                            strokeWidth: 2,
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            // Event Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Event Description
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFF5F6368).withOpacity(0.9),
                      height: 1.3,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Location and Date Row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: const Color(0xFF71BB7B).withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF5F6368).withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: const Color(0xFF71BB7B).withOpacity(0.8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.date.day}/${event.date.month}/${event.date.year} at ${event.date.hour.toString().padLeft(2, '0')}:${event.date.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF5F6368).withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),

                  // Tags Row
                  if (event.tags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children:
                          event.tags.take(3).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF71BB7B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF71BB7B),
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvent = ref.watch(eventProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        title: AnimatedBuilder(
          animation: _headerSlideAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_headerSlideAnimation.value, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF71BB7B), Color(0xFF5BA55F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF71BB7B).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.event_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Color(0xFF2C3E50),
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF71BB7B), Color(0xFF5BA55F)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerHeight: 0,
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFF5F6368),
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past Events'),
                    Tab(text: 'My Events'),
                    Tab(text: 'Joined Events'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: asyncEvent.when(
        data: (events) {
          final upcomingEvents = _getUpcomingEvents(events);
          final pastEvents = _getPastEvents(events);
          final myEvents = _getMyEvents(events);
          final joinedEvents = _getJoinedEvents(events);

          return TabBarView(
            controller: _tabController,
            children: [
              _buildEventGrid(upcomingEvents, "No Upcoming Events"),
              _buildEventGrid(pastEvents, "No Past Events"),
              _buildEventGrid(myEvents, "No My Events"),
              _buildEventGrid(joinedEvents, "No Joined Events"),
            ],
          );
        },
        loading:
            () => const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF71BB7B)),
              ),
            ),
        error:
            (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Color(0xFF71BB7B),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "create_event_fab",
        backgroundColor: const Color(0xFF71BB7B),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
}
