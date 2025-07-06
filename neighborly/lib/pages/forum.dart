import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/post_card.dart';
import 'package:neighborly/functions/fetchData.dart';

class ForumPage extends ConsumerWidget {
  const ForumPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(fetchData('posts'));
    return asyncPosts.when(
      data:(posts) => posts.isNotEmpty? ListView.builder(
            itemCount: posts.length,
            itemBuilder: (_, i) => PostCard(post: posts[i]),
          ):
          Center(child: Text("No posts found"),),
      error: (e, _) => Center(child: Text('Error: $e')),
      loading: ()=> const Center(child: CircularProgressIndicator()),
    );
  }
}



// FutureBuilder(
//       future: fetchData(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return CircularProgressIndicator();
//         } else if (!snapshot.hasData) {
//           return Center(child: Text('No posts found'));
//         }

    //     final posts = snapshot.data!;
    //     return ListView.builder(
    //       itemCount: posts.length,
    //       itemBuilder: (context, index) {
    //         //     final post = posts[index];
    //         //     return Padding(
    //         //       padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
    //         //       child: Column(
    //         //         children: [
    //         //           Column(
    //         //             crossAxisAlignment: CrossAxisAlignment.start,
    //         //             children: [
    //         //               Text(
    //         //                 post['title'],
    //         //                 style: TextStyle(fontWeight: FontWeight.bold),
    //         //               ),
    //         //               SizedBox(height: 8.0),
    //         //               Row(
    //         //                 crossAxisAlignment: CrossAxisAlignment.center,
    //         //                 children: [
    //         //                   Text(
    //         //                     post['content'],
    //         //                     maxLines: 2,
    //         //                     overflow: TextOverflow.ellipsis,
    //         //                   ),
    //         //                   SizedBox(width: 8.0),
    //         //                   ClipOval(
    //         //                     child: Image.asset(
    //         //                       'assets/images/dummy.png',
    //         //                       height: 40,
    //         //                       width: 40,
    //         //                     ),
    //         //                   ),
    //         //                 ],
    //         //               ),
    //         //             ],
    //         //           ),
    //         //           Divider(height: 1, thickness: 0.5, indent: 0, endIndent: 0),
    //         //         ],
    //         //       ),
    //         //     );
    //       },
    //     );
    //   },
    // );