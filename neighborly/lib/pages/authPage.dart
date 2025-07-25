import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:neighborly/app_routes.dart';
import 'package:neighborly/components/forget_pass.dart';
import 'package:neighborly/components/new_pass.dart';
import 'package:neighborly/components/signin_form.dart';
import 'package:neighborly/components/signup_form.dart';

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
    final scnHeight = MediaQuery.of(context).size.height;
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
                    pageNumber == 0 ? -0.4 : (pageNumber == 1 ? -0.55 : -0.2),
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
                      20,
                      pageNumber == 0 ? 150 : (pageNumber == 1 ? 60 : 250),
                      20,
                      10,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight:
                            constraints.maxHeight > 160
                                ? constraints.maxHeight -
                                    (pageNumber == 2 ? 300 : 160)
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
                                        : NewPass(
                                          title: "Update password",
                                          key: ValueKey('updatePass'),
                                        ))),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
