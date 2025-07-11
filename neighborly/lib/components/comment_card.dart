import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:readmore/readmore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CommentCard extends ConsumerStatefulWidget {
  final dynamic comment;
  final int depth;
  const CommentCard({super.key, required this.comment, required this.depth});

  @override
  ConsumerState<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends ConsumerState<CommentCard> {
  Future<bool> OnTap(bool isLiked) async {
    return !isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 0),
      child: Card(
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
                        widget.comment['author'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                      SizedBox(width: 5),
                      Icon(Icons.check_circle, color: Colors.blue, size: 12),
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
                  Expanded(
                    child: ReadMoreText(
                      widget.comment['content'],
                      trimLines: 2,
                      style: TextStyle(fontSize: 14.0, color: Colors.black87),
                      trimMode: TrimMode.Line,
                      trimCollapsedText: 'Read more',
                      trimExpandedText: ' Show less',
                      moreStyle: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 35),
                  SizedBox(width: 5),
                  LikeButton(
                    likeCount: widget.comment['reacts'] ?? 0,
                    countPostion: CountPostion.right,
                    likeBuilder: (isLiked) {
                      return Icon(
                        Icons.favorite,
                        size: 15,
                        color: isLiked ? Colors.red : Colors.grey,
                      );
                    },
                    onTap: OnTap,
                  ),
                  SizedBox(width: 40),
                  Icon(Icons.reply, color: Colors.blue, size: 15),
                  SizedBox(width: 5),
                  Text(
                    'reply',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
