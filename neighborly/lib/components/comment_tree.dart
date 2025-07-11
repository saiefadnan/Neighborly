import 'package:flutter/material.dart';
import 'package:neighborly/components/comment_card.dart';

Widget buildCommentTree(dynamic comments, int parentID, int depth) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var comment in comments.where((c) => c['parentID'] == parentID)) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 0),
              child: Row(
                children: List.generate(depth, (index) {
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      width: 2,
                      height: 120,
                      color: Colors.grey[350],
                    ),
                  );
                }),
              ),
            ),

            Expanded(child: CommentCard(comment: comment, depth: depth)),
          ],
        ),
        buildCommentTree(comments, comment['commentID'], depth + 1),
      ],
    ],
  );
}
