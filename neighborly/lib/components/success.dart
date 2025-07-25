import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/authPage.dart';
<<<<<<< HEAD
=======
import 'dart:math' as math;
>>>>>>> aa8ca408330cda85f5616fa3a0e3f2b40991ec0a

class Success extends ConsumerStatefulWidget {
  final String title;
  const Success({super.key, required this.title});

  @override
  ConsumerState<Success> createState() => _SuccessState();
}

<<<<<<< HEAD
class _SuccessState extends ConsumerState<Success> {
  void navigateToSignin() {
    // Navigate to the Signin page
    ref.read(pageNumberProvider.notifier).state = 0;
=======
class _SuccessState extends ConsumerState<Success>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _particleAnimation;

  void onTapContinue() {
    ref.read(pageNumberProvider.notifier).state = 0; // Navigate to sign-in page
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _particleController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );

    // Start animations with delays
    Future.delayed(Duration(milliseconds: 200), () {
      if (mounted) {
        _animationController.forward();
      }
    });

    Future.delayed(Duration(milliseconds: 600), () {
      if (mounted) {
        _particleController.forward();
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
>>>>>>> aa8ca408330cda85f5616fa3a0e3f2b40991ec0a
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: Colors.black, size: 45.0),
            Text(
              "Congratulations!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28.0),
            ),
          ],
        ),
        SizedBox(height: 30.0),
        Text(
          "Congratulations! Your password has been changed. Click continue to sign in.",
          style: TextStyle(fontSize: 16.0, color: Colors.grey.shade700),
        ),
        SizedBox(height: 20.0),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF71BB7B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
              elevation: 3,
            ),
            onPressed: () => navigateToSignin(),
            child: Text(
              "Continue",
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
      ],
=======
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Success Icon with Enhanced Animation
          AnimatedBuilder(
            animation: Listenable.merge([
              _animationController,
              _pulseController,
              _particleController,
            ]),
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Particle effects
                  ...List.generate(8, (index) {
                    final angle = (index * 45.0) * (3.14159 / 180);
                    final distance = 60.0 * _particleAnimation.value;
                    return Transform.translate(
                      offset: Offset(
                        distance * math.cos(angle),
                        distance * math.sin(angle),
                      ),
                      child: Opacity(
                        opacity: (1.0 - _particleAnimation.value) * 0.8,
                        child: Container(
                          width: 4.0,
                          height: 4.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF71BB7B),
                          ),
                        ),
                      ),
                    );
                  }),
                  // Pulsing ring
                  Transform.scale(
                    scale: _pulseAnimation.value * _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value * 0.3,
                      child: Container(
                        width: 120.0,
                        height: 120.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF71BB7B),
                            width: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Main success icon
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        width: 100.0,
                        height: 100.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Color(0xFF71BB7B),
                            width: 2.0,
                          ),
                          color: const Color.fromARGB(44, 113, 187, 123),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF71BB7B).withOpacity(0.3),
                              blurRadius: 10.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check,
                          color: Color(0xFF71BB7B),
                          size: 40.0,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: 32.0),

          // Success Title
          Text(
            "Successful",
            style: TextStyle(
              fontSize: 28.0,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16.0),

          // Success Message
          Text(
            "Congratulations! Your password has been changed. Click continue to login",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 40.0),

          // Continue Button
          Container(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF71BB7B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.symmetric(vertical: 16.0),
                elevation: 0,
              ),
              onPressed: onTapContinue,
              child: Text(
                "Continue",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16.0,
                ),
              ),
            ),
          ),
        ],
      ),
>>>>>>> aa8ca408330cda85f5616fa3a0e3f2b40991ec0a
    );
  }
}
