import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/comment_card.dart';
import 'package:neighborly/components/comment_tree.dart';
import 'package:neighborly/functions/fetchData.dart';

class BottomCommentSheet extends ConsumerStatefulWidget {
  final int postID;
  final ScrollController? scrollController;
  const BottomCommentSheet({
    super.key,
    required this.postID,
    required this.scrollController,
  });

  @override
  ConsumerState<BottomCommentSheet> createState() => _BottomCommentSheetState();
}

class _BottomCommentSheetState extends ConsumerState<BottomCommentSheet> {
  @override
  Widget build(BuildContext context) {
    final asyncComments = ref.watch(fetchData('comments'));
    return asyncComments.when(
      data: (allComments) {
        final comments =
            allComments
                .where((comment) => comment['postID'] == widget.postID)
                .toList();
        final topLevelComments =
            comments.where((comment) => comment['parentID'] == null).toList();
        return topLevelComments.isEmpty
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "No comments yet",
                    style: TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text("Start the conversation"),
                ],
              ),
            )
            : ListView.builder(
              controller: widget.scrollController,
              itemCount: topLevelComments.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    CommentCard(comment: topLevelComments[index], depth: 0),
                    buildCommentTree(
                      comments,
                      topLevelComments[index]['commentID'],
                      1,
                    ),
                  ],
                );
              },
            );
      },
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: () => Center(child: CircularProgressIndicator()),
    );
  }
}

void showCommentBox(BuildContext context, WidgetRef ref, int postId) {
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
    ),
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: .6,
        minChildSize: .59,
        maxChildSize: .9,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(width: 3, color: Colors.grey.shade300),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: BottomCommentSheet(
                postID: postId,
                scrollController: scrollController,
              ),
            ),
          );
        },
      );
    },
  );
}
