import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/comment_card.dart';
import 'package:neighborly/components/comment_sheet.dart';

Widget buildCommentTree(dynamic comments, String parentID, int depth) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (var comment in comments.where((c) => c['parentID'] == parentID)) ...[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(depth, (index) {
                return Consumer(
                  builder: (context, ref, _) {
                    final height = ref.watch(
                      boxHeightProvider.select(
                        (mp) => mp[comment['commentID']],
                      ),
                    );
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: 2,
                        height: height ?? 60,
                        color: Colors.grey[350],
                      ),
                    );
                  },
                );
              }),
            ),
            Expanded(
              child: CommentCard(
                ckey: commentKeys[comment['commentID']] ??= GlobalKey(),
                comment: comment,
                depth: depth,
              ),
            ),
          ],
        ),
        buildCommentTree(comments, comment['commentID'], depth + 1),
      ],
    ],
  );
}

// Widget buildCommentTree(dynamic comments, int parentID, int depth) {
//   return Consumer(
//     builder: (context, ref, _) {
//       final boxHeights = ref.watch(boxHeightProvider);
//       Widget buildTree(int parentID, int depth) {
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             for (var comment in comments.where(
//               (c) => c['parentID'] == parentID,
//             )) ...[
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.only(left: 0),
//                     child: Row(
//                       children: List.generate(depth, (index) {
//                         return Padding(
//                           padding: EdgeInsets.symmetric(horizontal: 8.0),
//                           child: Container(
//                             width: 2,
//                             height: boxHeights[comment['commentID']] ?? 60,
//                             color: Colors.grey[350],
//                           ),
//                         );
//                       }),
//                     ),
//                   ),

//                   Expanded(
//                     child: CommentCard(
//                       ckey: ckeys[comment['commentID']] ??= GlobalKey(),
//                       comment: comment,
//                       depth: depth,
//                     ),
//                   ),
//                 ],
//               ),
//               buildTree(comment['commentID'], depth + 1),
//             ],
//           ],
//         );
//       }

//       return buildTree(parentID, depth);
//     },
//   );
// }
