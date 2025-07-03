import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key, required this.title});
  final String title;

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  Future<List<dynamic>> fetchData() async {
    final String response = await rootBundle.loadString(
      'assets/data/post.json',
    );
    final Map<String, dynamic> data = jsonDecode(response);
    return data['posts'];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (!snapshot.hasData) {
          return Center(child: Text('No posts found'));
        }

        final posts = snapshot.data!;
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return ListTile(
              title: Text(post['title']),
              subtitle: Text(post['content']),
              trailing: Text('👍 ${post['upvotes']}'),
            );
          },
        );
      },
    );
  }
}
