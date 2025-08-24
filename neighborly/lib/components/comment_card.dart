import 'dart:math';

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
      final likeDoc =
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.comment['postID'])
              .collection('comments')
              .doc(widget.comment['commentID'])
              .collection('likes')
              .doc(uid)
              .get();
      if (!mounted) return;
      setState(() {
        liked = likeDoc.exists;
      });
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = widget.ckey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        final height = box?.size.height ?? 0;
        ref.read(boxHeightProvider.notifier).update((state) {
          return {...state, widget.comment['commentID']: height};
        });
        //print('Height for comment ${widget.comment['commentID']}: $height');
      }
      await likedByme();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/dummy.png',
                    width: 25,
                    height: 25,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Row(
                  children: [
                    Text(
                      widget.comment['author'] ?? 'Anonymous',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.0,
                      ),
                    ),
                    SizedBox(width: 5),
                    Icon(
                      Icons.check_circle,
                      color: Color(0xFF71BB7B),
                      size: 12,
                    ),
                    SizedBox(width: 5),
                    Text(
                      '2h',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 35),
                Expanded(child: Text(widget.comment['content'])),
              ],
            ),
            Row(
              children: [
                SizedBox(width: 35),
                LikeButton(
                  isLiked: liked,
                  likeCount: widget.comment['reacts'] ?? 0,
                  countPostion: CountPostion.right,
                  likeBuilder: (isLiked) {
                    return Icon(
                      Icons.favorite,
                      size: 15,
                      color: isLiked ? Colors.red : Colors.grey,
                    );
                  },
                  onTap: (isLiked) async {
                    try {
                      final commentRef = FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.comment['postID'])
                          .collection('comments')
                          .doc(widget.comment['commentID']);
                      final likesRef = commentRef.collection('likes');
                      final uid = FirebaseAuth.instance.currentUser!.uid;
                      if (isLiked) {
                        widget.comment['reacts'] = max(
                          widget.comment['reacts'] - 1,
                          0,
                        );
                        likesRef.doc(uid).delete();
                        commentRef.update({'reacts': FieldValue.increment(-1)});
                      } else {
                        widget.comment['reacts'] = widget.comment['reacts'] + 1;
                        likesRef.doc(uid).set({
                          'likedAt': FieldValue.serverTimestamp(),
                        });
                        commentRef.update({'reacts': FieldValue.increment(1)});
                      }
                      return !isLiked;
                    } catch (e) {
                      return isLiked;
                    }
                  },
                ),
                SizedBox(width: 40),
                TextButton.icon(
                  onPressed: () {
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
                  icon: Icon(Icons.reply, color: Colors.blue, size: 15),
                  label: Text(
                    'reply',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
