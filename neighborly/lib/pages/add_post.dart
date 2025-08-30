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
import 'package:neighborly/notifiers/post_notifier.dart';
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
  bool isLoading = false;
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
    setState(() {
      isLoading = true;
    });
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
    showSnackBarSuccess(context, "Post submitted!");
    context.go('/appShell');
  }

  Widget _buildMediaButton(IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        if (icon == Icons.image_rounded) {
          _pickImage();
        } else if (icon == Icons.videocam_rounded) {
          _pickVideo();
        } else if (icon == Icons.add_link_rounded) {
          _pickLink();
        } else {
          _pickPoll();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
      backgroundColor: const Color(0xFFFAF8F5),
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Create Post",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFFAF8F5),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          !isLoading
              ? Container(
                margin: const EdgeInsets.only(right: 16),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_pickedImage != null) {
                      postSubmission("image");
                    } else if (_pickedVideo != null) {
                      postSubmission("video");
                    } else if (_pickedPoll) {
                      postSubmission("poll");
                    } else if (_pickedLink) {
                      postSubmission("link");
                    } else {
                      postSubmission('');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF71BB7B),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: const Color(0xFF71BB7B).withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    "Post",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              )
              : const SizedBox.shrink(),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;

            return !isLoading
                ? Column(
                  children: [
                    // Scrollable form content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Selection
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedCategory,
                                decoration: const InputDecoration(
                                  labelText: "Select Category",
                                  labelStyle: TextStyle(
                                    color: Color(0xFF5F6368),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                dropdownColor: Colors.white,
                                items:
                                    categories
                                        .map(
                                          (cat) => DropdownMenuItem(
                                            value: cat,
                                            child: Text(
                                              cat,
                                              style: const TextStyle(
                                                color: Color(0xFF2C3E50),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _selectedCategory = value);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Title Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _titleController,
                                style: const TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: const InputDecoration(
                                  labelText: "Title",
                                  labelStyle: TextStyle(
                                    color: Color(0xFF5F6368),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (_pickedImage != null ||
                                (_pickedVideo != null &&
                                    _videoController != null)) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF71BB7B,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final maxWidth = constraints.maxWidth;

                                    double? aspectRatio;
                                    if (_pickedImage != null) {
                                      aspectRatio = 1;
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
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: SizedBox(
                                            width: width,
                                            height: height,
                                            child:
                                                _pickedImage != null
                                                    ? Image.file(
                                                      _pickedImage!,
                                                      fit: BoxFit.cover,
                                                    )
                                                    : AspectRatio(
                                                      aspectRatio:
                                                          aspectRatio ?? 1,
                                                      child: VideoPlayer(
                                                        _videoController!,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
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
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.1),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              padding: const EdgeInsets.all(6),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                color: Colors.redAccent,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (_pickedLink) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF71BB7B,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF71BB7B,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.link_rounded,
                                            color: Color(0xFF71BB7B),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Add Link",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        const Spacer(),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _linkController.clear();
                                              linkPreviewData = null;
                                              _pickedLink = false;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.redAccent,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _linkController,
                                      focusNode: _linkFocusNode,
                                      style: const TextStyle(
                                        color: Color(0xFF2C3E50),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: const InputDecoration(
                                        labelText: "Enter link",
                                        labelStyle: TextStyle(
                                          color: Color(0xFF5F6368),
                                          fontWeight: FontWeight.w500,
                                        ),
                                        border: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFF71BB7B),
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Color(0xFF71BB7B),
                                            width: 2,
                                          ),
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(12),
                                          ),
                                        ),
                                        contentPadding: EdgeInsets.all(12),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    LinkPreview(
                                      onLinkPreviewDataFetched: (data) {
                                        setState(() {
                                          linkPreviewData = data;
                                        });
                                      },
                                      text: _linkController.text,
                                      borderRadius: 8,
                                      sideBorderColor: const Color(
                                        0xFF71BB7B,
                                      ).withOpacity(0.2),
                                      sideBorderWidth: 1,
                                      insidePadding: const EdgeInsets.all(12),
                                      outsidePadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                      titleTextStyle: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            if (_pickedPoll) ...[
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF71BB7B,
                                    ).withOpacity(0.2),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF71BB7B,
                                                  ).withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.poll_outlined,
                                                  color: Color(0xFF71BB7B),
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                "Create a Poll",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 18,
                                                  color: Color(0xFF2C3E50),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 20),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFAF8F5),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: const Color(
                                                  0xFF71BB7B,
                                                ).withOpacity(0.1),
                                                width: 1,
                                              ),
                                            ),
                                            child: TextField(
                                              controller: pollTitleController,
                                              style: const TextStyle(
                                                color: Color(0xFF2C3E50),
                                                fontWeight: FontWeight.w500,
                                              ),
                                              decoration: const InputDecoration(
                                                labelText: 'Poll question',
                                                labelStyle: TextStyle(
                                                  color: Color(0xFF5F6368),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.all(
                                                  16,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ...optionsController.asMap().entries.map((
                                            entry,
                                          ) {
                                            final index = entry.key;
                                            final optionController =
                                                entry.value;
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 12,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFAF8F5),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF71BB7B,
                                                  ).withOpacity(0.1),
                                                  width: 1,
                                                ),
                                              ),
                                              child: TextField(
                                                controller: optionController,
                                                style: const TextStyle(
                                                  color: Color(0xFF2C3E50),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Option ${index + 1}',
                                                  labelStyle: const TextStyle(
                                                    color: Color(0xFF5F6368),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  border: InputBorder.none,
                                                  contentPadding:
                                                      const EdgeInsets.all(16),
                                                  suffixIcon:
                                                      optionsController.length >
                                                              2
                                                          ? IconButton(
                                                            icon: const Icon(
                                                              Icons
                                                                  .remove_circle_outline,
                                                              color:
                                                                  Colors
                                                                      .redAccent,
                                                            ),
                                                            onPressed: () {
                                                              setState(() {
                                                                optionsController
                                                                    .removeAt(
                                                                      index,
                                                                    );
                                                              });
                                                            },
                                                          )
                                                          : null,
                                                ),
                                              ),
                                            );
                                          }),
                                          const SizedBox(height: 8),
                                          ElevatedButton.icon(
                                            onPressed:
                                                () => setState(() {
                                                  optionsController.add(
                                                    TextEditingController(),
                                                  );
                                                }),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF71BB7B,
                                              ).withOpacity(0.1),
                                              foregroundColor: const Color(
                                                0xFF71BB7B,
                                              ),
                                              elevation: 0,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            icon: const Icon(
                                              Icons.add_rounded,
                                              size: 20,
                                            ),
                                            label: const Text(
                                              "Add option",
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      top: 16,
                                      right: 16,
                                      child: GestureDetector(
                                        onTap: () {
                                          for (var optCntrl
                                              in optionsController) {
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
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.close_rounded,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            // Body Text Field
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xFF71BB7B,
                                  ).withOpacity(0.2),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _bodyController,
                                maxLines: 6,
                                style: const TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                                decoration: const InputDecoration(
                                  labelText: "What's on your mind?",
                                  labelStyle: TextStyle(
                                    color: Color(0xFF5F6368),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.all(16),
                                  hintStyle: TextStyle(
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Sticky bottom media buttons
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 20,
                        bottom: bottomInset > 0 ? bottomInset + 16 : 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Add to your post",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMediaButton(
                                  Icons.add_link_rounded,
                                  "Link",
                                  Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMediaButton(
                                  Icons.image_rounded,
                                  "Photo",
                                  Colors.green,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMediaButton(
                                  Icons.videocam_rounded,
                                  "Video",
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMediaButton(
                                  Icons.poll_outlined,
                                  "Poll",
                                  Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                )
                : Container(
                  decoration: const BoxDecoration(color: Color(0xFFFAF8F5)),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF71BB7B),
                          ),
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Creating your post...",
                          style: TextStyle(
                            color: Color(0xFF5F6368),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
          },
        ),
      ),
    );
  }
}
