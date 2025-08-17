import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/comment_card.dart';
import 'package:neighborly/components/comment_tree.dart';
import 'package:neighborly/functions/comment_notifier.dart';

final Map<String, GlobalKey> commentKeys = {};
final DraggableScrollableController _controller =
    DraggableScrollableController();
final TextEditingController _commentController = TextEditingController();
final commentFocusNodeProvider = Provider<FocusNode>((ref) {
  final node = FocusNode();
  ref.onDispose(() => node.dispose());
  return node;
});

final hintTextProvider = StateProvider<String>((ref) => '');

class BottomCommentSheet extends ConsumerStatefulWidget {
  final String postID;
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
    final asyncComments = ref.watch(commentsProvider(widget.postID));
    // ref.listen(fetchData('comments'), (previous, next) {
    //   next.whenData((fetchedList) {
    //     ref.read(commentsProvider.notifier).setComments(fetchedList);
    //   });
    // });
    return asyncComments.when(
      data: (comments) {
        //final comments = ref.watch(commentsProvider);
        final filteredComments =
            comments.where((c) => c['postID'] == widget.postID).toList();
        final topLevelComments =
            filteredComments.where((c) => c['parentID'] == null).toList();
        return topLevelComments.isNotEmpty
            ? ListView.builder(
              controller: widget.scrollController,
              itemCount: topLevelComments.length,
              itemBuilder: (context, index) {
                final commentId = topLevelComments[index]['commentID'];
                if (commentId == null) return SizedBox.shrink();
                commentKeys.putIfAbsent(commentId, () => GlobalKey());

                return Column(
                  children: [
                    CommentCard(
                      ckey: commentKeys[commentId]!,
                      comment: topLevelComments[index],
                      depth: 0,
                    ),
                    buildCommentTree(
                      comments,
                      topLevelComments[index]['commentID'],
                      1,
                    ),
                    SizedBox(height: 16.0),
                  ],
                );
              },
            )
            : ListView(
              controller: widget.scrollController,
              padding: EdgeInsets.all(16.0),
              shrinkWrap: true,
              children: [
                Center(
                  child: Text(
                    "No comments yet",
                    style: TextStyle(
                      fontSize: 25.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Center(child: Text("Start the conversation")),
              ],
            );
        ;
      },
      error: (e, _) {
        return ListView(
          controller: widget.scrollController,
          padding: EdgeInsets.all(16.0),
          shrinkWrap: true,
          children: [
            Center(
              child: Text(
                "Network error!",
                style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

void showCommentBox(BuildContext context, WidgetRef ref, String postId) {
  bool canSend = false;
  ref.read(hintTextProvider.notifier).state = ""; // Reset reply target
  showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
    ),
    isScrollControlled: true,
    builder: (context) {
      final commentFocusNode = ref.watch(commentFocusNodeProvider);
      return StatefulBuilder(
        builder: (context, setState) {
          return KeyboardVisibilityBuilder(
            builder: (context, isKeyboardVisible) {
              if (isKeyboardVisible && _controller.isAttached) {
                _controller.animateTo(
                  0.9,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              } else if (_controller.isAttached) {
                _controller.animateTo(
                  0.6,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
              return DraggableScrollableSheet(
                controller: _controller,
                initialChildSize: .6,
                minChildSize: .59,
                maxChildSize: .9,
                expand: false,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(width: 3, color: Colors.grey.shade300),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30.0),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                "Comments",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Divider(
                                color: Theme.of(context).dividerColor,
                                thickness: 1,
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: BottomCommentSheet(
                              postID: postId,
                              scrollController: scrollController,
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            2,
                            2,
                            2,
                            MediaQuery.of(context).viewInsets.bottom + 12,
                          ),
                          child: Consumer(
                            builder: (context, ref, _) {
                              return Column(
                                children: [
                                  if (ref.watch(hintTextProvider) != "")
                                    SizedBox(
                                      height: 40.0,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              ref.watch(hintTextProvider),
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.cancel_outlined,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              ref
                                                  .read(
                                                    hintTextProvider.notifier,
                                                  )
                                                  .state = '';
                                              ref
                                                  .read(
                                                    replyTargetProvider
                                                        .notifier,
                                                  )
                                                  .state = null;
                                              _commentController.clear();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.0,
                                          ),
                                          child: TextField(
                                            controller: _commentController,
                                            focusNode: commentFocusNode,
                                            decoration: InputDecoration(
                                              hint: Row(
                                                children: [
                                                  Icon(
                                                    Icons.comment,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(width: 8.0),
                                                  Text("Write a comment..."),
                                                ],
                                              ),
                                            ),
                                            onChanged: (value) {
                                              setState(() {
                                                canSend =
                                                    value.trim().isNotEmpty;
                                              });
                                            },
                                            onSubmitted: (value) {
                                              if (value.trim().isNotEmpty) {
                                                _commentController.clear();
                                                setState(() {
                                                  canSend = false;
                                                });
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 4.0),
                                      Padding(
                                        padding: EdgeInsets.only(right: 8.0),
                                        child: IconButton(
                                          onPressed:
                                              canSend
                                                  ? () async {
                                                    final replyTo = ref.read(
                                                      replyTargetProvider,
                                                    );
                                                    final comment =
                                                        _commentController.text
                                                            .trim();
                                                    if (comment.isNotEmpty) {
                                                      final commentRef =
                                                          FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'posts',
                                                              )
                                                              .doc(postId)
                                                              .collection(
                                                                'comments',
                                                              )
                                                              .doc();
                                                      final newComment = {
                                                        'commentID':
                                                            commentRef.id,
                                                        'postID': postId,
                                                        'authorID':
                                                            FirebaseAuth
                                                                .instance
                                                                .currentUser
                                                                ?.uid,
                                                        'author':
                                                            FirebaseAuth
                                                                .instance
                                                                .currentUser
                                                                ?.displayName, // get this from user state
                                                        'content': comment,
                                                        'parentID': replyTo,
                                                      };
                                                      ref
                                                          .read(
                                                            commentsProvider(
                                                              postId,
                                                            ).notifier,
                                                          )
                                                          .addComment(
                                                            newComment,
                                                            replyTo: replyTo,
                                                          );
                                                      _commentController
                                                          .clear();
                                                      ref
                                                          .read(
                                                            commentsProvider(
                                                              postId,
                                                            ).notifier,
                                                          )
                                                          .storeComments(
                                                            newComment,
                                                          ); //store in firebase

                                                      WidgetsBinding.instance.addPostFrameCallback((
                                                        _,
                                                      ) {
                                                        final key =
                                                            commentKeys[newComment['commentID']];

                                                        if (key != null &&
                                                            key.currentContext !=
                                                                null) {
                                                          final box =
                                                              key.currentContext!
                                                                      .findRenderObject()
                                                                  as RenderBox;
                                                          final position = box
                                                              .localToGlobal(
                                                                Offset.zero,
                                                              );
                                                          final scrollableBox =
                                                              scrollController
                                                                      .position
                                                                      .context
                                                                      .storageContext
                                                                      .findRenderObject()
                                                                  as RenderBox;
                                                          final scrollOffset =
                                                              scrollController
                                                                  .offset +
                                                              position.dy -
                                                              scrollableBox
                                                                  .localToGlobal(
                                                                    Offset.zero,
                                                                  )
                                                                  .dy;

                                                          scrollController.animateTo(
                                                            scrollOffset,
                                                            duration: Duration(
                                                              milliseconds: 300,
                                                            ),
                                                            curve:
                                                                Curves
                                                                    .easeInOut,
                                                          );
                                                        }
                                                      });

                                                      ref
                                                          .read(
                                                            replyTargetProvider
                                                                .notifier,
                                                          )
                                                          .state = null;
                                                      ref
                                                          .read(
                                                            hintTextProvider
                                                                .notifier,
                                                          )
                                                          .state = "";

                                                      setState(() {
                                                        canSend = false;
                                                      });
                                                    }
                                                  }
                                                  : null,
                                          icon: Icon(
                                            Icons.send,
                                            color:
                                                canSend
                                                    ? Color(0xFF71BB7B)
                                                    : Colors.grey.shade400,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      );
    },
  );
}
