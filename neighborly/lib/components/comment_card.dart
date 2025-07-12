import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final boxHeightProvider = StateProvider<Map<int, double>>((ref) => {});

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
  Future<bool> OnTap(bool isLiked) async {
    return !isLiked;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = widget.ckey.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        final height = box?.size.height ?? 0;
        ref.read(boxHeightProvider.notifier).update((state) {
          return {...state, widget.comment['commentID']: height};
        });
        print('Height for comment ${widget.comment['commentID']}: $height');
      }
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
                      widget.comment['author'],
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
    );
  }
}
