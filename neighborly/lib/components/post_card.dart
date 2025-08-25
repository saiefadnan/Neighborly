import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
          Icons.schedule_outlined,
          size: 16,
          color: Colors.redAccent,
        );
      case 'emergency':
        return const Icon(
          Icons.warning_amber_outlined,
          size: 16,
          color: Colors.deepOrange,
        );
      case 'ask':
        return const Icon(Icons.help_outline, size: 16, color: Colors.blue);
      case 'news':
        return const Icon(
          Icons.newspaper_outlined,
          size: 16,
          color: Colors.green,
        );
      case 'general':
      default:
        return const Icon(
          Icons.chat_bubble_outline,
          size: 16,
          color: Colors.indigo,
        );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'urgent':
        return Color(0xFFF5F1E8);
      case 'emergency':
        return Color(0xFFF5F1E8);
      case 'ask':
        return Color(0xFFF5F1E8);
      case 'news':
        return Color(0xFFF5F1E8);
      case 'general':
      default:
        return Color(0xFFF5F1E8);
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/dummy.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['author'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.post['timestamp'] is Timestamp
                          ? _getFormattedTime(
                            (widget.post['timestamp'] as Timestamp)
                                .toDate()
                                .toIso8601String(),
                          )
                          : 'Just now', // fallback if null or still FieldValue
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Spacer(),

                Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getCategoryIcon(widget.post['category']),
                      // const SizedBox(width: 6),
                      // Text(
                      //   widget.post['category'].toString().toUpperCase(),
                      //   style: const TextStyle(
                      //     color: Colors.white,
                      //     fontWeight: FontWeight.bold,
                      //     fontSize: 12,
                      //   ),
                      // ),
                    ],
                  ),
                  backgroundColor: _getCategoryColor(widget.post['category']),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Text(
                widget.post['title'],
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo[800],
                  fontSize: 22,
                ),
              ),
            ),
            // Title
            const SizedBox(height: 12),

            // Content with ReadMore
            ReadMoreText(
              widget.post['content'],
              trimLines: 2,
              trimCollapsedText: 'Show more',
              trimExpandedText: '',
              style: TextStyle(
                height: 1.4,
                color: Colors.grey[800],
                fontSize: 18,
              ),
              moreStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            // Image if exists
            if (widget.post['type'] == 'image') ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.post['mediaUrl'],
                  // width: 300,
                  // height: 300,
                  // fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 300,
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey[400],
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
              // ElevatedButton(
              //   onPressed: () async {
              //     final url = Uri.parse("https://www.google.com");
              //     if (await canLaunchUrl(url)) {
              //       await launchUrl(url, mode: LaunchMode.externalApplication);
              //     } else {
              //       print("Can't launch URL");
              //     }
              //   },
              //   child: Text("Open Google"),
              // ),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse(widget.post['url']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    print('not possible!');
                  }
                },
                child: LinkPreview(
                  onLinkPreviewDataFetched: (data) {},
                  text: widget.post['url'] ?? '',
                  borderRadius: 4,
                  sideBorderColor: Colors.white,
                  sideBorderWidth: 4,
                  insidePadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                  outsidePadding: const EdgeInsets.symmetric(vertical: 4),
                  titleTextStyle: const TextStyle(fontWeight: FontWeight.bold),
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
            const SizedBox(height: 20),
            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    LikeButton(
                      isLiked: liked,
                      likeCount: widget.post['reacts'],
                      countPostion: CountPostion.right,
                      size: 26,
                      likeBuilder: (isLiked) {
                        return Icon(
                          Icons.favorite,
                          color: isLiked ? Colors.redAccent : Colors.grey,
                        );
                      },
                      onTap: (isLiked) async {
                        try {
                          final postRef = FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.post['postID']);
                          final likesRef = postRef.collection('likes');
                          final uid = FirebaseAuth.instance.currentUser!.uid;
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
                            widget.post['reacts'] = widget.post['reacts'] + 1;
                            likesRef.doc(uid).set({
                              'likedAt': FieldValue.serverTimestamp(),
                            });
                            postRef.update({'reacts': FieldValue.increment(1)});
                          }
                          return !isLiked;
                        } catch (e) {
                          return isLiked;
                        }
                      },
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      iconSize: 26,
                      tooltip: "Comments",
                      onPressed: () {
                        showCommentBox(context, ref, widget.post['postID']);
                      },
                    ),
                    Text(
                      '${widget.post['totalComments']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flag_outlined),
                      tooltip: "Report",
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: "Share",
                      onPressed: () => Share.share(widget.post['link']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
