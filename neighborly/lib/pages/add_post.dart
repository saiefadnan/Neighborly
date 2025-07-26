import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class AddPostPage extends ConsumerStatefulWidget {
  final String title;
  const AddPostPage({super.key, required this.title});

  @override
  ConsumerState<AddPostPage> createState() => _AddPostPageState();
}

class _AddPostPageState extends ConsumerState<AddPostPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedCategory = 'General';
  final ImagePicker _picker = ImagePicker();
  File? _pickedImage;
  File? _pickedVideo;
  VideoPlayerController? _videoController;
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (_videoController != null) {
        await _videoController!.pause();
        await _videoController!.dispose();
        _videoController = null;
      }

      setState(() {
        _pickedImage = File(image.path);
        _pickedVideo = null;
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
        _pickedVideo = file;
        _pickedImage = null;
        _videoController = controller;
      });
    }
  }

  final List<String> categories = [
    'General',
    'Urgent',
    'Emergency',
    'Ask',
    'News',
  ];

  Widget _buildMediaButton(IconData icon) {
    return OutlinedButton(
      onPressed: () {
        if (icon == Icons.image) {
          _pickImage();
        } else if (icon == Icons.play_arrow_rounded) {
          _pickVideo();
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Not implemented")));
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
                                          color: Colors.black54,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.cancel,
                                          color: Colors.white,
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
