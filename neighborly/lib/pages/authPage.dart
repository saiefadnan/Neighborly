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

  bool isImageSliding = false;
  bool isFormSliding = false;
  final portraitFactors = {
    0: 0.35, // Signin
    1: 0.16, // Signup
    2: 0.5, // Forget Password
    3: 0.4, // Verify Email
    4: 0.5, // New Password
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
        return VerifyEmail(title: 'Verify Email', key: ValueKey("verifyEmail"));
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

    return Scaffold(
      body:
      // SafeArea(
      //   child:
      SingleChildScrollView(
        child: Column(
          children: [
            AnimatedSlide(
              duration: Duration(milliseconds: 300),
              offset:
                  isImageSliding
                      ? Offset(0, -1)
                      : Offset(0, 0), // Slide in from the top
              child: SizedBox(
                key: ValueKey('page$pageNumber'),
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
            ),
            //),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 5),
              child: AnimatedSlide(
                duration: Duration(milliseconds: 600),
                offset:
                    isFormSliding
                        ? Offset(0, 1)
                        : Offset(0, 0), // Slide in from the bottom
                child: _getformWidget(
                  pageNumber,
                ), // your form with keys already
              ),
            ),
          ],
        ),
      ),
      // ),
    );
  }
}




// Positioned(
        //   top: 0,
        //   left: 0,
        //   child: Visibility(
        //     visible: pageNumber != 0 && pageNumber != 1,
        //     child: IconButton(
        //       onPressed: () {
        //         ref.read(pageNumberProvider.notifier).state = 0;
        //       },
        //       icon: Icon(Icons.arrow_back),
        //       iconSize: 28,
        //       color: Colors.black,
        //     ),
        //   ),
        // ),