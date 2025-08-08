import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_link_previewer/flutter_link_previewer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:neighborly/components/snackbar.dart';
import 'package:neighborly/functions/media_upload.dart';
import 'package:neighborly/functions/post_notifier.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' show LinkPreviewData;

class AddPostPage extends ConsumerStatefulWidget {
  final String title;
  const AddPostPage({super.key, required this.title});

  @override
  ConsumerState<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends ConsumerState<AddPostPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _linkController = TextEditingController();
  LinkPreviewData? linkPreviewData;
  String _selectedCategory = 'General';
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  File? _pickedVideo;
  bool _pickedLink = false;
  bool _pickedPoll = false;
  VideoPlayerController? _videoController;
  TextEditingController pollTitleController = TextEditingController();
  List<TextEditingController> optionsController = [
    TextEditingController(),
    TextEditingController(),
  ];
  final _linkFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _linkFocusNode.addListener(() {
      if (!_linkFocusNode.hasFocus) {
        setState(() {}); // triggers LinkPreview update
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.dispose();
        _videoController = null;
      }

      setState(() {
        _pickedPoll = false;
        _pickedLink = false;
        _pickedImage = File(image.path);
        _pickedVideo = null;
        _videoController = null;
      });
    }
  }

  Future<void> _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      // Dispose previous controller if any
      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.dispose();
        _videoController = null;
      }
      final file = File(video.path);
      final controller = VideoPlayerController.file(file);

      await controller.initialize(); // wait for init
      controller.setLooping(true);
      controller.play();

      if (!mounted) return; // avoid setState if widget disposed

      setState(() {
        _pickedPoll = false;
        _pickedLink = false;
        _pickedVideo = file;
        _pickedImage = null;
        _videoController = controller;
      });
    }
  }

  void _pickLink() {
    setState(() {
      _pickedPoll = false;
      _pickedLink = true;
      _pickedImage = null;
      _pickedVideo = null;
      _videoController = null;
    });
  }

  void _pickPoll() {
    setState(() {
      _pickedPoll = true;
      _pickedLink = false;
      _pickedImage = null;
      _pickedVideo = null;
      _videoController = null;
    });
  }

  final List<String> categories = [
    'General',
    'Urgent',
    'Emergency',
    'Ask',
    'News',
  ];

  void postSubmission(String type) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      showSnackBarError(context, "Please fill up the title");
      return;
    }
    final mediaUrl =
        type == 'image'
            ? await uploadFile(_pickedImage)
            : (type == 'video' ? await uploadFile(_pickedVideo) : null);
    final newPost = {
      'timestamp': FieldValue.serverTimestamp(),
      'authorID': FirebaseAuth.instance.currentUser!.uid,
      'author': FirebaseAuth.instance.currentUser!.displayName.toString(),
      'title': title,
      'content': body,
      'type': type,
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (type == 'poll')
        "poll": {
          "question": pollTitleController.text.trim(),
          "options":
              List.generate(optionsController.length, (index) {
                final option = optionsController[index];
                return option.text.trim().isNotEmpty
                    ? {
                      "id": index.toString(),
                      "title": option.text.trim(),
                      "votes": 0,
                    }
                    : null;
              }).whereType<Map<String, dynamic>>().toList(),
          "hasVoted": false,
          "userVotedOptionId": null,
        },
      if (type == 'link') 'url': _linkController.text.trim(),
      'upvotes': 0,
      'downvotes': 0,
      'link': "https://example.com/post/dummy",
      'totalComments': 0,
      'reacts': 0,
      'category': _selectedCategory,
    };
    final docRef = await FirebaseFirestore.instance
        .collection('posts')
        .add(newPost);
    await docRef.update({'postID': docRef.id});
    newPost['postID'] = docRef.id;
    ref.read(postsProvider.notifier).addPosts(newPost);
    if (!mounted) return;
    context.go('/appShell');
  }

  Widget _buildMediaButton(IconData icon) {
    return OutlinedButton(
      onPressed: () {
        if (icon == Icons.image) {
          _pickImage();
        } else if (icon == Icons.play_arrow_rounded) {
          _pickVideo();
        } else if (icon == Icons.add_link_rounded) {
          _pickLink();
        } else {
          _pickPoll();
        }
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFFF7F2E7),
        side: const BorderSide(color: Color(0xFF71BB7B)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Icon(icon, color: Colors.black),
    );
  }

  @override
  void dispose() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text(
          "Create  Post",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Color(0xFFF7F2E7),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (_pickedImage != null) {
                postSubmission("image"); //done
              } else if (_pickedVideo != null) {
                postSubmission("video"); //done
              } else if (_pickedPoll) {
                postSubmission("poll"); //done
              } else if (_pickedLink) {
                postSubmission("link"); //done
              } else {
                postSubmission(''); //done
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Post Submitted!")));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF71BB7B),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Post",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return Column(
              children: [
                // Scrollable form content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: "Select Category",
                            border: OutlineInputBorder(),
                          ),
                          items:
                              categories
                                  .map(
                                    (cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCategory = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: "Title",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_pickedImage != null ||
                            (_pickedVideo != null &&
                                _videoController != null)) ...[
                          SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              // Max width available in the parent widget
                              final maxWidth = constraints.maxWidth;

                              double? aspectRatio;
                              if (_pickedImage != null) {
                                aspectRatio = 1; // or whatever fallback
                              } else if (_videoController != null) {
                                aspectRatio =
                                    _videoController!.value.aspectRatio;
                              }

                              double width = maxWidth;
                              double height =
                                  aspectRatio != null
                                      ? width / aspectRatio
                                      : 200;

                              return Stack(
                                children: [
                                  SizedBox(
                                    width: width,
                                    height: height,
                                    child:
                                        _pickedImage != null
                                            ? Image.file(
                                              _pickedImage!,
                                              fit: BoxFit.cover,
                                            )
                                            : AspectRatio(
                                              aspectRatio: aspectRatio ?? 1,
                                              child: VideoPlayer(
                                                _videoController!,
                                              ),
                                            ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_videoController != null) {
                                          _videoController!.pause();
                                          _videoController!.dispose();
                                          _videoController = null;
                                        }
                                        setState(() {
                                          _pickedImage = null;
                                          _pickedVideo = null;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.cancel,
                                          color: Colors.redAccent,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                        if (_pickedLink) ...[
                          SizedBox(height: 16),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _linkController,
                                      focusNode: _linkFocusNode,
                                      decoration: const InputDecoration(
                                        labelText: "Enter link",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _linkController.clear();
                                        linkPreviewData = null;
                                        _pickedLink = false;
                                      });
                                    },
                                    child: const Icon(
                                      Icons.cancel,
                                      color: Colors.redAccent,
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 6),
                              LinkPreview(
                                onLinkPreviewDataFetched: (data) {
                                  setState(() {
                                    linkPreviewData = data;
                                  });
                                },
                                text: _linkController.text,
                                borderRadius: 4,
                                sideBorderColor: Colors.white,
                                sideBorderWidth: 4,
                                insidePadding: const EdgeInsets.fromLTRB(
                                  12,
                                  8,
                                  8,
                                  8,
                                ),
                                outsidePadding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                ),
                                titleTextStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (_pickedPoll) ...[
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Create a Poll",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    TextField(
                                      controller: pollTitleController,
                                      decoration: InputDecoration(
                                        labelText: 'Poll title',
                                      ),
                                    ),
                                    ...optionsController.map(
                                      (optionController) => TextField(
                                        controller: optionController,
                                        decoration: InputDecoration(
                                          labelText: 'Poll option',
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      icon: Icon(Icons.add),
                                      onPressed:
                                          () => setState(() {
                                            optionsController.add(
                                              TextEditingController(),
                                            );
                                          }),

                                      label: Text("Add options"),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 24,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () {
                                    for (var optCntrl in optionsController) {
                                      optCntrl.dispose();
                                    }
                                    optionsController = [
                                      TextEditingController(),
                                      TextEditingController(),
                                    ];
                                    setState(() {
                                      _pickedPoll = false;
                                    });
                                  },
                                  child: Icon(
                                    Icons.cancel,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: _bodyController,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: "Body text (optional)",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky bottom media buttons
                Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 8,
                    bottom: bottomInset > 0 ? bottomInset + 12 : 24,
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildMediaButton(Icons.add_link_rounded),
                      _buildMediaButton(Icons.image),
                      _buildMediaButton(Icons.play_arrow_rounded),
                      _buildMediaButton(Icons.poll_outlined),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
