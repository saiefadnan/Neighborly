import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/components/forget_pass.dart';
import 'package:neighborly/components/new_pass.dart';
import 'package:neighborly/components/signin_form.dart';
import 'package:neighborly/components/signup_form.dart';
import 'package:neighborly/components/success.dart';
import 'package:neighborly/components/verify_email.dart';

final pageNumberProvider = StateProvider<int>((ref) => 0);

class AuthPage extends ConsumerStatefulWidget {
  final String title;
  const AuthPage({super.key, required this.title});
  @override
  ConsumerState<AuthPage> createState() => _SigninPageState();
}

class _SigninPageState extends ConsumerState<AuthPage> {
  void onTapSignin(BuildContext context) {
    ref.read(signedInProvider.notifier).state = true;
    context.go('/mapHomePage');
  }

  @override
  Widget build(BuildContext context) {
    int pageNumber = ref.watch(pageNumberProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: Colors.transparent,
                child: AnimatedSlide(
                  offset: Offset(
                    0,
                    pageNumber == 0 ? -0.42 : (pageNumber == 1 ? -0.62 : pageNumber == 4 ? -0.52 : pageNumber == 5 ? -0.60 : -0.37),
                  ),
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  child: Image.asset(
                    "assets/images/signin.png",
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      pageNumber == 0 ? 250 : (pageNumber == 1 ? 120 : pageNumber == 3 ? 270 : pageNumber == 4 ? 220 : pageNumber == 5 ? 150 : 250),
                      0,
                      10,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight > 160
                                ? constraints.maxHeight -
                                    (pageNumber == 2 ? 300 : 270)
                                : 160,
                      ),
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 250),
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: Offset(0, 0.1), // from slightly below
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child:
                            pageNumber == 0
                                ? SigninForm(
                                  title: 'signin page',
                                  key: ValueKey('signin'),
                                )
                                : (pageNumber == 1
                                    ? SignupForm(
                                      title: 'signup page',
                                      key: ValueKey('signup'),
                                    )
                                    : (pageNumber == 2
                                        ? ForgetPass(
                                          title: "Forget password",
                                          key: ValueKey('forgetPass'),
                                        )
                                        : (pageNumber == 3
                                            ? VerifyEmail(
                                              title: 'Verify Email',
                                              key: ValueKey("verifyEmail"),
                                            )
                                            : (pageNumber == 4
                                                ? NewPass(
                                                  title: "Update password",
                                                  key: ValueKey('updatePass'),
                                                )
                                                : Success(
                                                  title: 'Success',
                                                  key: ValueKey('success'),
                                                ))))),
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 25,
              left: 20,
              child: Visibility(
                visible: pageNumber != 0 && pageNumber != 1 && pageNumber != 4 && pageNumber != 5,
                child: GestureDetector(
                  onTap: () {
                    ref.read(pageNumberProvider.notifier).state = 0;
                  },
                  child: Container(
                    width: 33,
                    height: 33,
                    decoration: BoxDecoration(
                      color: Color(0xFFFAF4E8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back,
                      color: Color(0xFF71BB7B),
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
