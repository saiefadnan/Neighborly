import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> likedByme() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final likeDoc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.post['postID'])
              .collection('likes')
              .doc(uid)
              .get();
      if (!mounted) return;
      setState(() {
        liked = likeDoc.exists;
      });
    } catch (e) {}
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await likedByme();
    });
    if (widget.post['type'] == 'video' && widget.post['mediaUrl'] != null) {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.post['mediaUrl']),
      );
      _initializeVideoPlayerFuture = _videoController!.initialize();
      _videoController!.setLooping(true);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _videoController?.dispose();
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info Row
            Container(
              padding: const EdgeInsets.all(16),
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
                      child: Image.asset(
                        'assets/images/dummy.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                                  : 'Just now',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
              padding: const EdgeInsets.symmetric(horizontal: 4),
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
              Container(
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
                  child: Image.network(
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
                                    loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
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
                        return AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _videoController!.value.isPlaying
                                        ? _videoController!.pause()
                                        : null;
                                  });
                                },
                                child: VideoPlayer(_videoController!),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _videoController!.value.isPlaying
                                        ? _videoController!.pause()
                                        : _videoController!.play();
                                  });
                                },
                                child:
                                    !_videoController!.value.isPlaying
                                        ? Icon(
                                          Icons.play_circle,
                                          size: 64,
                                          color: Colors.white,
                                        )
                                        : null,
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: VideoProgressIndicator(
                                  _videoController!,
                                  allowScrubbing: true,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const Center(child: CircularProgressIndicator());
                      }
                    },
                  )
                  : const Text('No video url'),
            ],
            const SizedBox(height: 24),
            // Actions row
            Container(
              padding: const EdgeInsets.all(16),
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
                            try {
                              final postRef = FirebaseFirestore.instance
                                  .collection('posts')
                                  .doc(widget.post['postID']);
                              final likesRef = postRef.collection('likes');
                              final uid =
                                  FirebaseAuth.instance.currentUser!.uid;
                              if (isLiked) {
                                widget.post['reacts'] = max(
                                  widget.post['reacts'] - 1,
                                  0,
                                );
                                likesRef.doc(uid).delete();
                                postRef.update({
                                  'reacts': FieldValue.increment(-1),
                                });
                              } else {
                                widget.post['reacts'] =
                                    widget.post['reacts'] + 1;
                                likesRef.doc(uid).set({
                                  'likedAt': FieldValue.serverTimestamp(),
                                });
                                postRef.update({
                                  'reacts': FieldValue.increment(1),
                                });
                              }
                              return !isLiked;
                            } catch (e) {
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
