import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/components/forget_pass.dart';
import 'package:neighborly/components/new_pass.dart';
import 'package:neighborly/components/signin_form.dart';
import 'package:neighborly/components/signup_form.dart';
import 'package:neighborly/components/success.dart';
import 'package:neighborly/components/verify_email.dart';
import 'package:neighborly/components/verify_email_alt.dart';
import 'package:neighborly/functions/auth_user.dart';

final pageNumberProvider = StateProvider<int>((ref) => 0);
final authUserProvider = AsyncNotifierProvider<AuthUser, bool>(AuthUser.new);

class AuthPage extends ConsumerStatefulWidget {
  final String title;
  const AuthPage({super.key, required this.title});
  @override
  ConsumerState<AuthPage> createState() => _SigninPageState();
}

class _SigninPageState extends ConsumerState<AuthPage> {
  // void onTapSignin(BuildContext context) {
  //   ref.read(signedInProvider.notifier).state = true;
  //   context.go('/mapHomePage');
  // }

  int? _lastPage;
  bool isFormSliding = false;

  //Don't change the values!!!
  final portraitFactors = {
    0: 0.25, // Signin
    1: 0.15, // Signup
    2: 0.4, // Forget Password
    3: 0.4, // Verify Email
    4: 0.3, // New Password
  };

  Widget _getformWidget(int pagenum) {
    switch (pagenum) {
      case 0:
        return SigninForm(title: 'signin page', key: ValueKey('signin'));
      case 1:
        return SignupForm(title: 'signup page', key: ValueKey('signup'));
      case 2:
        return ForgetPass(
          title: 'Forget password',
          key: ValueKey('forgetPass'),
        );
      case 3:
        // return VerifyEmail(title: 'Verify Email', key: ValueKey("verifyEmail"));
        return VerifyEmailAlt(
          title: 'Verify Email',
          key: ValueKey("verifyEmail"),
        );
      case 4:
        return NewPass(title: "Update password", key: ValueKey('updatePass'));
      default:
        return Success(title: 'Success', key: ValueKey('success'));
    }
  }

  double _getHeightFactor(int pageNumber, BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    return isPortrait ? (portraitFactors[pageNumber] ?? 0.45) : 0.7;
  }

  @override
  Widget build(BuildContext context) {
    int pageNumber = ref.watch(pageNumberProvider);

    ref.listen<int>(pageNumberProvider, (prev, next) {
      if (_lastPage != next) {
        setState(() {
          isFormSliding = true;
        });

        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              isFormSliding = false;
            });
          }
        });

        _lastPage = next;
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeInOut,
                  height:
                      MediaQuery.of(context).size.height *
                      _getHeightFactor(pageNumber, context),
                  width: double.infinity,
                  child: Image.asset(
                    "assets/images/signin.png",
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 0, 32, 10),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    offset:
                        isFormSliding
                            ? const Offset(0, 0.1)
                            : const Offset(0, 0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      transitionBuilder:
                          (child, animation) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -0.1),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                      child: _getformWidget(pageNumber),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 24,
            left: 16,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder:
                  (child, animation) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.5),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
              child:
                  (pageNumber != 0 && pageNumber != 1)
                      ? Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          key: const ValueKey("backButton"),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.chevron_left,
                            size: 30,
                            color: Colors.green,
                          ),
                          onPressed:
                              () =>
                                  ref.read(pageNumberProvider.notifier).state =
                                      0,
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}
