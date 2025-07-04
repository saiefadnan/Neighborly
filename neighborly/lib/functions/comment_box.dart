import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void showCommentBox(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.all(8.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 300,
            minWidth: double.infinity,
          ),
          child: Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [Text("No comments yet",style: TextStyle(fontSize: 25.0,fontWeight: FontWeight.w600),
            ),Text("Start the conversation")])),
        ),
      );
    },
  );
}
