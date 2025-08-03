import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _fadeController;
  late Animation<double> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();

    // Text animation controller
    _textController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade out controller
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    // Text animations
    _textSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeIn));

    // Fade out animation
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // Start text animation
    await Future.delayed(Duration(milliseconds: 300));
    if (mounted) _textController.forward();

    // Wait for animations to complete, then navigate
    await Future.delayed(Duration(milliseconds: 2000));
    if (mounted) {
      _fadeController.forward();
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        // Mark that splash has been seen
        ref.read(hasSeenSplashProvider.notifier).state = true;
        //context.go('/auth');
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F1E8), // Cream/beige background
      body: AnimatedBuilder(
        animation: Listenable.merge([_textController, _fadeController]),
        builder: (context, child) {
          return Opacity(
            opacity:
                _fadeOutAnimation.value == 0.0 ? 1.0 : _fadeOutAnimation.value,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main Title - NEIGHBORLY
                  Transform.translate(
                    offset: Offset(0, _textSlideAnimation.value),
                    child: Opacity(
                      opacity: _textOpacityAnimation.value,
                      child: Text(
                        "NEIGHBORLY",
                        style: TextStyle(
                          fontSize: 42.0,
                          fontWeight: FontWeight.w900, // Extra bold
                          color: Color(0xFF066056), // Updated dark green
                          letterSpacing: 2.5,
                          fontFamily: 'Open Sans',
                          height: 0.8, // Reduce line height for tighter spacing
                        ),
                      ),
                    ),
                  ),

                  // Subtitle - moved up with negative transform
                  Transform.translate(
                    offset: Offset(
                      0,
                      _textSlideAnimation.value * 0.8 - 1.0,
                    ), // Less negative offset - less overlap
                    child: Opacity(
                      opacity: _textOpacityAnimation.value * 0.9,
                      child: Text(
                        "HELP STARTS NEXT DOOR!",
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF71BB79), // Updated light green
                          letterSpacing: 1.2,
                          fontFamily: 'Open Sans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
