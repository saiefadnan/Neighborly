import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        return comments.isEmpty
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
              itemCount: comments.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.all(3.0),
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
                          Text(
                            '${comments[index]['author']}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(width: 35),
                          Expanded(
                            child: Text('${comments[index]['content']}'),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          SizedBox(width: 35),
                          Icon(Icons.favorite, color: Colors.red, size: 15),
                          SizedBox(width: 5),
                          Text('${comments[index]['reacts']}'),
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
                    ], // Replace with actual comment widget
                  ),
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
  showBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: .6,
        minChildSize: .58,
        maxChildSize: .95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              border: Border.all(width: 3, color: Colors.grey.shade300),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
            ),
            child: Padding(
              padding: EdgeInsets.only(left: 10, top: 10),
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
