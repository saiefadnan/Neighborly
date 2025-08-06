import 'package:flutter/material.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:markdown_widget/config/all.dart';
import 'package:neighborly/components/comment_sheet.dart';
import 'package:like_button/like_button.dart';
import 'package:readmore/readmore.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostCard extends ConsumerStatefulWidget {
  final dynamic post;
  const PostCard({super.key, required this.post});
  @override
  ConsumerState<PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<PostCard> {
  Future<bool> OnTap(bool isLiked) async {
    return !isLiked;
  }

  String _getFormattedTime(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays >= 1) {
      // Show like "Jul 25"
      return '${_getMonthAbbreviation(date.month)} ${date.day}, ${date.year}';
    } else {
      return timeago.format(date);
    }
  }

  String _getMonthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Icon _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'urgent':
        return const Icon(
          Icons.schedule_outlined,
          size: 16,
          color: Colors.white,
        );
      case 'emergency':
        return const Icon(
          Icons.warning_amber_outlined,
          size: 16,
          color: Colors.white,
        );
      case 'ask':
        return const Icon(Icons.help_outline, size: 16, color: Colors.white);
      case 'news':
        return const Icon(
          Icons.newspaper_outlined,
          size: 16,
          color: Colors.white,
        );
      case 'general':
      default:
        return const Icon(
          Icons.chat_bubble_outline,
          size: 16,
          color: Colors.white,
        );
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'urgent':
        return Colors.redAccent;
      case 'emergency':
        return Colors.deepOrange;
      case 'ask':
        return Colors.blueAccent;
      case 'news':
        return Colors.green;
      case 'general':
      default:
        return Colors.teal; // <---- switched to teal here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Author Info Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/dummy.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.post['author'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getFormattedTime(widget.post['timestamp']),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Spacer(), // push category chip right

                Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _getCategoryIcon(widget.post['category']),
                      const SizedBox(width: 6),
                      Text(
                        widget.post['category'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: _getCategoryColor(
                    widget.post['category'],
                  ).toOpacity(0.75          ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              child: Text(
                widget.post['title'],
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.indigo[800],
                  fontSize: 22,
                ),
              ),
            ),
            // Title
            const SizedBox(height: 12),

            // Content with ReadMore
            ReadMoreText(
              widget.post['content'],
              trimLines: 2,
              trimCollapsedText: 'Show more',
              trimExpandedText: '',
              style: TextStyle(
                height: 1.4,
                color: Colors.grey[800],
                fontSize: 18,
              ),
              moreStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            // Image if exists
            if (widget.post['imageUrl'] != null) ...[
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  widget.post['imageUrl'],
                  // width: 300,
                  // height: 300,
                  // fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 300,
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          value:
                              loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder:
                      (context, error, stackTrace) => SizedBox(
                        width: double.infinity,
                        height: 200,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                ),
              ),
            ],
            if (widget.post['poll'] != null) ...[
              const SizedBox(height: 20),
              FlutterPolls(
                pollId: widget.post['postID'].toString(),
                onVoted: (PollOption option, int selectedIndex) async {
                  return true;
                },
                pollTitle: Text(widget.post['poll']['question']),
                pollOptions:
                    widget.post['poll']['options']
                        .map<PollOption>(
                          (option) => PollOption(
                            title: Text(option['title']),
                            votes: option['votes'],
                          ),
                        )
                        .toList(),
              ),
            ],
            const SizedBox(height: 20),
            // Actions row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    LikeButton(
                      isLiked: true,
                      likeCount: widget.post['reacts'],
                      countPostion: CountPostion.right,
                      size: 26,
                      likeBuilder: (isLiked) {
                        return Icon(
                          Icons.favorite,
                          color: isLiked ? Colors.redAccent : Colors.grey,
                        );
                      },
                      onTap: OnTap,
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined),
                      iconSize: 26,
                      tooltip: "Comments",
                      onPressed: () {
                        showCommentBox(context, ref, widget.post['postID']);
                      },
                    ),
                    Text(
                      '${widget.post['totalComments']}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.flag_outlined),
                      tooltip: "Report",
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: "Share",
                      onPressed: () => Share.share(widget.post['link']),
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
