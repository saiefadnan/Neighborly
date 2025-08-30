import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neighborly/models/event.dart';

class EventDetailsPage extends ConsumerStatefulWidget {
  final EventModel event;
  const EventDetailsPage({super.key, required this.event});

  @override
  ConsumerState<EventDetailsPage> createState() => _EventDetailsState();
}

class _EventDetailsState extends ConsumerState<EventDetailsPage> {
  bool hasJoined = false;
  int totalParticipants = 0;
  LatLng? userLocation;
  GoogleMapController? mapController;
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await checkJoinedStatus();
      await loadParticipantCount();
    });
    _getCurrentLocation();
  }

  Future<void> checkJoinedStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc =
          await FirebaseFirestore.instance
              .collection('events')
              .doc(widget.event.id)
              .collection('participants')
              .doc(uid)
              .get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            hasJoined = data['joined'];
          });
        }
      }
    } catch (e) {
      print('Error checking join status: $e');
    }
  }

  Future<int> getParticipantCount(String eventId) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .collection('participants')
              .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting participant count: $e');
      return 0;
    }
  }

  Future<void> loadParticipantCount() async {
    try {
      final count = await getParticipantCount(widget.event.id!);
      setState(() {
        totalParticipants = count;
      });
    } catch (e) {
      print('Error loading participant count: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          userLocation = LatLng(position.latitude, position.longitude);
        });

        // Optional: Draw a simple straight line (for demo)
        if (userLocation != null) {
          _drawSimplePath();
        }
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  void _drawSimplePath() {
    if (userLocation != null) {
      setState(() {
        polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: [userLocation!, LatLng(widget.event.lat, widget.event.lng)],
            color: Colors.blue,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        };
      });
    }
  }

  Future<void> toggleJoinStatus() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (hasJoined) {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .collection('participants')
            .doc(uid)
            .delete();
      } else {
        await FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .collection('participants')
            .doc(uid)
            .set({'joined': true}, SetOptions(merge: true));
      }
      setState(() {
        hasJoined = !hasJoined;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasJoined ? "You've joined the event!" : "You've left the event!",
          ),
        ),
      );
      await loadParticipantCount();
    } catch (e) {
      print('Error joining event: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Event Details"),
        backgroundColor: const Color(0xFF71BB7B),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Image.network(
              event.imageUrl,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    height: 220,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 60),
                    ),
                  ),
            ),

            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                event.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Date
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "${event.createdAt.toDate().day}/${event.createdAt.toDate().month}/${event.createdAt.toDate().year}  •  ${event.createdAt.toDate().hour}:${event.createdAt.toDate().minute.toString().padLeft(2, '0')}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Mock Location
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                event.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),

            const SizedBox(height: 24),

            // Mock tags
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                children:
                    event.tags.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Participants count (mocked from joined)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.people_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    hasJoined
                        ? "You're in! Total: ${totalParticipants} joined"
                        : "$totalParticipants people have joined",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Join Button
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await toggleJoinStatus();
                },
                icon: Icon(
                  hasJoined ? Icons.check_circle : Icons.check_circle_outline,
                ),
                label: Text(hasJoined ? "Already Joined" : "Join Event"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasJoined ? Colors.grey : Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            // Map View (Demo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Event Location",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 400, // fix height to avoid layout issues
                      child: GoogleMap(
                        gestureRecognizers:
                            <Factory<OneSequenceGestureRecognizer>>{
                              Factory<OneSequenceGestureRecognizer>(
                                () => EagerGestureRecognizer(),
                              ),
                            },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(widget.event.lat, widget.event.lng),
                          zoom: 12,
                        ),
                        onMapCreated:
                            (controller) => mapController = controller,
                        markers: {
                          // Event location marker
                          Marker(
                            markerId: MarkerId('event-location'),
                            position: LatLng(
                              widget.event.lat,
                              widget.event.lng,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueRed,
                            ),
                            infoWindow: InfoWindow(
                              title: 'Event Location',
                              snippet: widget.event.title,
                            ),
                          ),
                          // User location marker (if available)
                          if (userLocation != null)
                            Marker(
                              markerId: MarkerId('user-location'),
                              position: userLocation!,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                              infoWindow: InfoWindow(title: 'Your Location'),
                            ),
                        },
                        polylines: polylines,
                        mapType: MapType.normal,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        rotateGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        tiltGesturesEnabled: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
