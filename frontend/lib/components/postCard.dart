import 'package:flutter/material.dart';
import 'package:like_button/like_button.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends StatefulWidget {
  final dynamic post;
  const PostCard({super.key, required this.post});
  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  Future<bool> OnTap(bool isLiked) async {
    return !isLiked;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/dummy.png',
                    width: 35,
                    height: 35,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['author'],
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '🕒 ${timeago.format(DateTime.parse(widget.post['timestamp']))}',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('${widget.post['title']}', style: TextStyle(fontSize: 18)),
            Text(
              widget.post['content'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    LikeButton(
                      isLiked: true,
                      likeCount: 20,
                      countPostion: CountPostion.right,
                      size: 25,
                      onTap: OnTap,
                    ),
                    SizedBox(width: 10),
                    IconButton(
                      icon: Icon(Icons.comment),
                      iconSize: 22,
                      onPressed: () {
                        // Navigate to comments page or show comments dialog
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(onPressed: () {}, icon: Icon(Icons.report)),
                    IconButton(
                      icon: Icon(Icons.share),
                      iconSize: 22,
                      onPressed:
                          () => Share.share(
                            "Check this out: ${widget.post['title']}\n\n${widget.post['link']}",
                          ),
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
