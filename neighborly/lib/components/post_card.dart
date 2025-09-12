import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/comment_card.dart';
import 'package:neighborly/components/comment_sheet.dart';
import 'package:like_button/like_button.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class PostCard extends ConsumerStatefulWidget {
  final dynamic post;
  const PostCard({super.key, required this.post});
  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool liked = false;
  String userPicUrl = '';
  bool _disposed = false;

  // Keep the widget alive during scrolling
  Future<void> likedByme() async {
    if (_disposed) return; // Early exit if disposed
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post['postID'])
          .collection('likes')
          .doc(uid)
          .get()
          .timeout(Duration(seconds: 10)); // Add timeout

      if (_disposed || !mounted) return; // Check both disposed and mounted
      setState(() {
        liked = likeDoc.exists;
      });
    } catch (e) {
      print("Error checking like status: $e");
      // Don't update state if there's an error
    }
  }

  Future<void> fetchUserInfo() async {
    if (_disposed) return; // Early exit if disposed
    try {
      final uid = widget.post['authorID'];
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get()
          .timeout(Duration(seconds: 10)); // Add timeout

      if (_disposed || !mounted) return; // Check both disposed and mounted
      setState(() {
        userPicUrl = userDoc['profilepicurl'] ?? '';
      });
    } catch (e) {
      print("Error fetching user info: $e");
      if (_disposed || !mounted) return; // Check both disposed and mounted
      // Set fallback value instead of leaving empty
      setState(() {
        userPicUrl = '';
      });
    }
  }

  String _getFormattedTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      // Show like "Jul 25"
      return '${_getMonthAbbreviation(date.month)} ${date.day}, ${date.year}';
    } else {
      return timeago.format(date);
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'urgent':
        return const Icon(
          Icons.access_time_filled,
          size: 14,
          color: Colors.white,
        );
      case 'emergency':
        return const Icon(Icons.warning_rounded, size: 14, color: Colors.white);
      case 'ask':
        return const Icon(Icons.help_rounded, size: 14, color: Colors.white);
      case 'news':
        return const Icon(
          Icons.newspaper_rounded,
          size: 14,
          color: Colors.white,
        );
      case 'general':
      default:
        return const Icon(Icons.chat_rounded, size: 14, color: Colors.white);
    }
  }

  List<Color> _getCategoryGradientColor(String category) {
    switch (category.toLowerCase()) {
      case 'urgent':
        return [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)];
      case 'emergency':
        return [const Color(0xFFFF4757), const Color(0xFFFF6B7A)];
      case 'ask':
        return [const Color(0xFF4834D4), const Color(0xFF686DE0)];
      case 'news':
        return [const Color(0xFF00D2D3), const Color(0xFF54A0FF)];
      case 'general':
      default:
        return [const Color(0xFF71BB7B), const Color(0xFF5BA55F)];
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePostData();
    });
    print(widget.post);
    if (widget.post['type'] == 'video' && widget.post['mediaUrl'] != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post['mediaUrl']),
      );
      _initializeVideoPlayerFuture = _videoController!
          .initialize()
          .timeout(Duration(seconds: 15))
          .then((_) {
            if (!_disposed && mounted) {
              _videoController!.setLooping(true);
            }
          })
          .catchError((error) {
            print('Video initialization failed: $error');
            return null;
          });
    }
  }

  Future<void> _initializePostData() async {
    if (_disposed || !mounted) return;

    try {
      await Future.wait([
        fetchUserInfo(),
        likedByme(),
      ]).timeout(Duration(seconds: 10));
    } catch (e) {
      print("Error initializing post data: $e");
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic> votedByMap = {};
    bool hasVoted = false;
    String? userVotedOptionId;
    if (widget.post['type'] == 'poll') {
      votedByMap = Map<String, dynamic>.from(
        widget.post['poll']['votedBy'] ?? {},
      );
      hasVoted = votedByMap.containsKey(uid);
      userVotedOptionId = hasVoted ? votedByMap[uid].toString() : null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5), // Light cream background
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info Row
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF71BB7B).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF71BB7B).withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child:
                          userPicUrl.isEmpty
                              ? Image.asset(
                                'assets/images/anonymous.jpg',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              )
                              : Image.network(
                                userPicUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                loadingBuilder: (
                                  context,
                                  child,
                                  loadingProgress,
                                ) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        color: const Color(0xFF71BB7B),
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.error,
                                        color: Colors.red,
                                      ),
                                    ),
                                  );
                                },
                              ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post['author'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C3E50),
                            fontSize: 16,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_rounded,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.post['timestamp'] is Timestamp
                                  ? _getFormattedTime(
                                    (widget.post['timestamp'] as Timestamp)
                                        .toDate()
                                        .toIso8601String(),
                                  )
                                  : widget.post['timestamp'] is Map
                                  ? _getFormattedTime(
                                    DateTime.fromMillisecondsSinceEpoch(
                                      (widget.post['timestamp']['_seconds']
                                                  as int) *
                                              1000 +
                                          ((widget.post['timestamp']['_nanoseconds']
                                                  as int) ~/
                                              1000000),
                                    ).toIso8601String(),
                                  )
                                  : 'Just now',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),

                        // Location Display (if location is shared)
                        if (widget.post['location'] != null &&
                            widget.post['location'] is Map &&
                            widget.post['location']['shared'] == true &&
                            widget.post['location']['name'] != null &&
                            widget.post['location']['name']
                                .toString()
                                .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.post['location']['name'],
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getCategoryGradientColor(widget.post['category'])[0],
                          _getCategoryGradientColor(widget.post['category'])[1],
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _getCategoryGradientColor(
                            widget.post['category'],
                          )[0].withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _getCategoryIcon(widget.post['category']),
                        const SizedBox(width: 6),
                        Text(
                          widget.post['category'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Title
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.post['title'],
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C3E50),
                  fontSize: 24,
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Content with ReadMore
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ReadMoreText(
                widget.post['content'],
                trimLines: 3,
                trimCollapsedText: ' Read more',
                trimExpandedText: ' Show less',
                style: const TextStyle(
                  height: 1.5,
                  color: Color(0xFF4A5568),
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                moreStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF71BB7B),
                  decoration: TextDecoration.underline,
                ),
                lessStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF71BB7B),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            // Image if exists
            if (widget.post['type'] == 'image') ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder:
                          (context) => _FullScreenImageViewer(
                            imageUrl: widget.post['mediaUrl'],
                            heroTag: 'image_${widget.post['postID']}',
                          ),
                    ),
                  );
                },
                child: Hero(
                  tag: 'image_${widget.post['postID']}',
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.network(
                            widget.post['mediaUrl'],
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(
                                        color: const Color(0xFF71BB7B),
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Loading image...',
                                        style: TextStyle(
                                          color: Color(0xFF5F6368),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: double.infinity,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.broken_image_rounded,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Failed to load image',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                          // Full-screen indicator
                          // Positioned(
                          //   top: 8,
                          //   right: 8,
                          //   child: Container(
                          //     padding: const EdgeInsets.all(6),
                          //     decoration: BoxDecoration(
                          //       color: Colors.black.withOpacity(0.6),
                          //       borderRadius: BorderRadius.circular(8),
                          //     ),
                          //     child: const Icon(
                          //       Icons.fullscreen,
                          //       color: Colors.white,
                          //       size: 20,
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (widget.post['type'] == 'poll' &&
                (widget.post['poll']['options'] as List).isNotEmpty) ...[
              const SizedBox(height: 20),
              FlutterPolls(
                pollId: widget.post['postID'].toString(),
                onVoted: (PollOption option, int selectedIndex) async {
                  if (!hasVoted) {
                    try {
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      final postRef = FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.post['postID']);
                      votedByMap[uid] = option.id; // track who voted what

                      final options = List<Map<String, dynamic>>.from(
                        widget.post['poll']['options'],
                      );
                      options[selectedIndex]['votes'] =
                          ((options[selectedIndex]['votes'] as int?) ?? 0) + 1;

                      await postRef.update({
                        'poll.options': options,
                        'poll.votedBy': votedByMap,
                      });
                      setState(() {
                        hasVoted = true;
                        userVotedOptionId = option.id;
                        widget.post['poll']['options'][selectedIndex]['votes'] =
                            options[selectedIndex]['votes'];
                      });

                      return true;
                    } catch (e) {
                      print("Vote error: $e");
                      return false;
                    }
                  } else {
                    return false;
                  }
                },
                pollTitle: Text(widget.post['poll']['question']),
                pollOptions:
                    (widget.post['poll']['options'] as List)
                        .map((e) => Map<String, dynamic>.from(e))
                        .map<PollOption>(
                          (option) => PollOption(
                            id: option['id'].toString().trim(),
                            title: Text(option['title'] ?? 'No title'),
                            votes: option['votes'] as int? ?? 0,
                          ),
                        )
                        .toList(),
                hasVoted: hasVoted,
                userVotedOptionId: userVotedOptionId,
              ),
            ],
            if (widget.post['type'] == 'link') ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      try {
                        String urlString = widget.post['url'] ?? '';
                        print(
                          'Attempting to open URL: $urlString',
                        ); // Debug log

                        // Ensure URL has proper protocol
                        if (!urlString.startsWith('http://') &&
                            !urlString.startsWith('https://')) {
                          urlString = 'https://$urlString';
                        }

                        final url = Uri.parse(urlString);
                        print('Parsed URL: $url'); // Debug log

                        // Show loading indicator
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Opening link...'),
                                ],
                              ),
                              backgroundColor: Color(0xFF71BB7B),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }

                        if (await canLaunchUrl(url)) {
                          // Try external application first
                          bool launched = await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                          print(
                            'External app launch result: $launched',
                          ); // Debug log

                          // If external app failed, try in-app browser
                          if (!launched) {
                            print('External app failed, trying in-app browser');
                            launched = await launchUrl(
                              url,
                              mode: LaunchMode.inAppBrowserView,
                            );
                            print(
                              'In-app browser launch result: $launched',
                            ); // Debug log
                          }

                          // If both failed, try platform default
                          if (!launched) {
                            print(
                              'In-app browser failed, trying platform default',
                            );
                            launched = await launchUrl(url);
                            print(
                              'Platform default launch result: $launched',
                            ); // Debug log
                          }

                          if (!launched) {
                            throw Exception('All launch methods failed');
                          }
                        } else {
                          print('Cannot launch URL: $url');
                          // Show user-friendly error
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No app available to open this link',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Error launching URL: $e');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Unable to open link'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'URL: ${widget.post['url']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.red,
                              action: SnackBarAction(
                                label: 'Copy URL',
                                textColor: Colors.white,
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: widget.post['url']),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('URL copied to clipboard'),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: LinkPreview(
                        onLinkPreviewDataFetched: (data) {
                          print(
                            'Link preview data fetched: ${data.title}',
                          ); // Debug log
                        },
                        text: widget.post['url'] ?? '',
                        borderRadius: 16,
                        backgroundColor: Colors.white,
                        titleTextStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                          fontSize: 16,
                        ),
                        insidePadding: const EdgeInsets.all(16),
                        outsidePadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (widget.post['type'] == 'video') ...[
              const SizedBox(height: 18),
              _videoController != null
                  ? FutureBuilder(
                    future: _initializeVideoPlayerFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => _FullScreenVideoViewer(
                                      videoUrl: widget.post['mediaUrl'],
                                      heroTag: 'video_${widget.post['postID']}',
                                    ),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'video_${widget.post['postID']}',
                            child: AspectRatio(
                              aspectRatio: _videoController!.value.aspectRatio,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(_videoController!),

                                  // Play/Pause overlay
                                  GestureDetector(
                                    onTap: () {
                                      if (_disposed || !mounted) return;
                                      setState(() {
                                        _videoController!.value.isPlaying
                                            ? _videoController!.pause()
                                            : _videoController!.play();
                                      });
                                    },
                                    child: Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      color: Colors.transparent,
                                      child: Center(
                                        child:
                                            !_videoController!.value.isPlaying
                                                ? Container(
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: const Icon(
                                                    Icons.play_arrow,
                                                    size: 48,
                                                    color: Colors.white,
                                                  ),
                                                )
                                                : null,
                                      ),
                                    ),
                                  ),

                                  // Full-screen indicator
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.fullscreen,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),

                                  // Progress indicator at bottom
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: VideoProgressIndicator(
                                      _videoController!,
                                      allowScrubbing: true,
                                      colors: const VideoProgressColors(
                                        playedColor: Color(0xFF71BB7B),
                                        bufferedColor: Colors.grey,
                                        backgroundColor: Colors.white30,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  )
                  : const Text('No video url'),
            ],
            const SizedBox(height: 16),
            // Actions row
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF71BB7B).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: LikeButton(
                          isLiked: liked,
                          likeCount: widget.post['reacts'],
                          countPostion: CountPostion.right,
                          size: 24,
                          padding: const EdgeInsets.all(8),
                          countBuilder: (count, isLiked, text) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isLiked
                                          ? Colors.redAccent
                                          : const Color(0xFF5F6368),
                                ),
                              ),
                            );
                          },
                          likeBuilder: (isLiked) {
                            return Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color:
                                  isLiked
                                      ? Colors.redAccent
                                      : const Color(0xFF5F6368),
                              size: 24,
                            );
                          },
                          onTap: (isLiked) async {
                            if (!mounted) return isLiked; // Check mounted first

                            try {
                              final postRef = FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.post['postID']);
                              final likesRef = postRef.collection('likes');
                              final uid =
                                  FirebaseAuth.instance.currentUser!.uid;

                              if (isLiked) {
                                // Unlike the post
                                await Future.wait(
                                  [
                                    likesRef.doc(uid).delete(),
                                    postRef.update({
                                      'reacts': FieldValue.increment(-1),
                                    }),
                                  ],
                                ).timeout(Duration(seconds: 10)); // Add timeout

                                if (!mounted) {
                                  return isLiked; // Check mounted after async operation
                                }
                                widget.post['reacts'] = max(
                                  widget.post['reacts'] - 1,
                                  0,
                                );
                              } else {
                                // Like the post
                                await Future.wait(
                                  [
                                    likesRef.doc(uid).set({
                                      'likedAt': FieldValue.serverTimestamp(),
                                    }),
                                    postRef.update({
                                      'reacts': FieldValue.increment(1),
                                    }),
                                  ],
                                ).timeout(Duration(seconds: 10)); // Add timeout

                                if (!mounted) {
                                  return isLiked; // Check mounted after async operation
                                }
                                widget.post['reacts'] =
                                    widget.post['reacts'] + 1;
                              }

                              return !isLiked;
                            } catch (e) {
                              print('Error toggling like: $e');
                              if (!mounted) return isLiked;

                              // Show user-friendly error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to update like. Please try again.',
                                  ),
                                  backgroundColor: Colors.red[400],
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              return isLiked;
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              openedPost = widget.post;
                              showCommentBox(
                                context,
                                ref,
                                widget.post['postID'],
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    size: 24,
                                    color: Color(0xFF5F6368),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${widget.post['totalComments']}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5F6368),
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
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.flag_outlined,
                            color: Color(0xFF5F6368),
                          ),
                          iconSize: 22,
                          tooltip: "Report",
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.share_outlined,
                            color: Color(0xFF5F6368),
                          ),
                          iconSize: 22,
                          tooltip: "Share",
                          onPressed: () => Share.share(widget.post['link']),
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
  }
}

// Full-screen Image Viewer
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullScreenImageViewer({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            onPressed: () {
              // TODO: Implement download functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Download feature coming soon!'),
                  backgroundColor: Color(0xFF71BB7B),
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF71BB7B),
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                );
              },
              errorBuilder:
                  (context, error, stackTrace) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

// Full-screen Video Viewer
class _FullScreenVideoViewer extends StatefulWidget {
  final String videoUrl;
  final String heroTag;

  const _FullScreenVideoViewer({required this.videoUrl, required this.heroTag});

  @override
  State<_FullScreenVideoViewer> createState() => _FullScreenVideoViewerState();
}

class _FullScreenVideoViewerState extends State<_FullScreenVideoViewer> {
  VideoPlayerController? _videoController;
  Future<void>? _initializeVideoPlayerFuture;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );
    _initializeVideoPlayerFuture = _videoController!.initialize().then((_) {
      if (mounted) {
        _videoController!.setLooping(true);
        _videoController!.play();
        setState(() {});
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    if (_showControls) {
      _startHideControlsTimer();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child:
                  _videoController != null
                      ? FutureBuilder(
                        future: _initializeVideoPlayerFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return Hero(
                              tag: widget.heroTag,
                              child: AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: VideoPlayer(_videoController!),
                              ),
                            );
                          } else {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF71BB7B),
                              ),
                            );
                          }
                        },
                      )
                      : const Center(
                        child: Text(
                          'No video available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _videoController!.value.isPlaying
                      ? _videoController!.pause()
                      : _videoController!.play();
                });
              },
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.transparent,
                child: Center(
                  child:
                      !_videoController!.value.isPlaying
                          ? Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              size: 48,
                              color: Colors.white,
                            ),
                          )
                          : null,
                ),
              ),
            ),
            // Controls overlay
            if (_showControls)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      // Top controls
                      SafeArea(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Download feature coming soon!',
                                    ),
                                    backgroundColor: Color(0xFF71BB7B),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),

                      // Bottom controls
                      if (_videoController != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              // Play/Pause button
                              // Progress indicator
                              VideoProgressIndicator(
                                _videoController!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: Color(0xFF71BB7B),
                                  bufferedColor: Colors.grey,
                                  backgroundColor: Colors.white30,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
