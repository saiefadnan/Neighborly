import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:like_button/like_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/comment_sheet.dart';

final boxHeightProvider = StateProvider<Map<String, double>>((ref) => {});
final replyTargetProvider = StateProvider<String?>((ref) => null);
final kvc = KeyboardVisibilityController();

class CommentCard extends ConsumerStatefulWidget {
  final dynamic comment;
  final int depth;
  final GlobalKey ckey;
  const CommentCard({
    required this.ckey,
    required this.comment,
    required this.depth,
  }) : super(key: ckey);

  @override
  ConsumerState<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<CommentCard> {
  bool liked = false;
  Future<void> likedByme() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.comment['postID'])
          .collection('comments')
          .doc(widget.comment['commentID'])
          .collection('likes')
          .doc(uid)
          .get()
          .timeout(Duration(seconds: 10)); // Add timeout

      if (!mounted) return; // Check mounted after async operation
      setState(() {
        liked = likeDoc.exists;
      });
    } catch (e) {
      print('Error checking like status: $e');
      // Don't update state if there's an error
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return; // Check mounted first

      try {
        final context = widget.ckey.currentContext;
        if (context != null && mounted) {
          final box = context.findRenderObject() as RenderBox?;
          final height = box?.size.height ?? 0;
          ref.read(boxHeightProvider.notifier).update((state) {
            return {...state, widget.comment['commentID']: height};
          });
        }

        if (!mounted) return; // Check again before async operation
        await likedByme();
      } catch (e) {
        print('Error in initState callback: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8F5), // Light cream background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF71BB7B).withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author Info Row
            Row(
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
                    child: Image.network(
                      userUrlCache[widget.comment['authorID']] ??
                          'assets/images/anonymous.jpg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value:
                                loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/anonymous.jpg',
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        widget.comment['author'] ?? 'Anonymous',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.0,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF71BB7B),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '2h',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Comment Content
            Padding(
              padding: const EdgeInsets.only(
                left: 44,
              ), // Align with profile picture
              child: Text(
                widget.comment['content'],
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF4A5568),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Actions Row
            Padding(
              padding: const EdgeInsets.only(left: 44), // Align with content
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: LikeButton(
                      isLiked: liked,
                      likeCount: widget.comment['reacts'] ?? 0,
                      countPostion: CountPostion.right,
                      size: 18,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      countBuilder: (count, isLiked, text) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            text,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isLiked
                                      ? Colors.red
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
                          size: 18,
                          color: isLiked ? Colors.red : const Color(0xFF5F6368),
                        );
                      },
                      onTap: (isLiked) async {
                        if (!mounted) return isLiked; // Check mounted first

                        try {
                          final commentRef = FirebaseFirestore.instance
                              .collection('posts')
                              .doc(widget.comment['postID'])
                              .collection('comments')
                              .doc(widget.comment['commentID']);
                          final likesRef = commentRef.collection('likes');
                          final uid = FirebaseAuth.instance.currentUser!.uid;

                          if (isLiked) {
                            // Unlike the comment
                            await Future.wait([
                              likesRef.doc(uid).delete(),
                              commentRef.update({
                                'reacts': FieldValue.increment(-1),
                              }),
                            ]).timeout(Duration(seconds: 10)); // Add timeout

                            if (!mounted)
                              return isLiked; // Check mounted after async operation
                            widget.comment['reacts'] = max(
                              widget.comment['reacts'] - 1,
                              0,
                            );
                          } else {
                            // Like the comment
                            await Future.wait([
                              likesRef.doc(uid).set({
                                'likedAt': FieldValue.serverTimestamp(),
                              }),
                              commentRef.update({
                                'reacts': FieldValue.increment(1),
                              }),
                            ]).timeout(Duration(seconds: 10)); // Add timeout

                            if (!mounted)
                              return isLiked; // Check mounted after async operation
                            widget.comment['reacts'] =
                                widget.comment['reacts'] + 1;
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
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      ref.read(replyTargetProvider.notifier).state =
                          widget.comment['commentID'];
                      ref.read(hintTextProvider.notifier).state =
                          'Replying to @${widget.comment['author']}';
                      final focusNode = ref.read(commentFocusNodeProvider);
                      if (focusNode.hasFocus && !kvc.isVisible) {
                        focusNode.unfocus();
                      }
                      Future.delayed(Duration(milliseconds: 50), () {
                        focusNode.requestFocus();
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF71BB7B).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.reply_rounded,
                            size: 16,
                            color: Color(0xFF71BB7B),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF71BB7B),
                            ),
                          ),
                        ],
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
