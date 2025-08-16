import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:neighborly/components/snackbar.dart';
import 'package:neighborly/functions/valid_email.dart';
import 'package:neighborly/pages/authPage.dart';

class SignupForm extends ConsumerStatefulWidget {
  final String title;
  const SignupForm({super.key, required this.title});
  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isUsernameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  String name = '', email = '', pswd = '', cnfrmPswd = '';

  void onTapSignup(BuildContext context) async {
    name = _usernameController.text.trim();
    email = _emailController.text.trim();
    pswd = _passwordController.text.trim();
    cnfrmPswd = _confirmPasswordController.text.trim();
    if (name.isEmpty || email.isEmpty || pswd.isEmpty || cnfrmPswd.isEmpty) {
      showSnackBarError(context, 'All fields must be filled!');
      return;
    } else if (!isValidEmail(email)) {
      showSnackBarError(context, 'Please enter a valid email');
      return;
    } else if (name.length < 3) {
      showSnackBarError(context, 'Name is too short!');
      return;
    } else if (pswd.length < 6) {
      showSnackBarError(
        context,
        "Password must be at least of 6 characters long!",
      );
      return;
    } else if (pswd != cnfrmPswd) {
      showSnackBarError(context, "Passwords don't match. Try again!");
      return;
    }
    final authNotifier = ref.read(authUserProvider.notifier);
    await authNotifier.userAuthentication(
      name: name,
      email: email,
      password: pswd,
    );
  }

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(() {
      setState(() {
        _isUsernameFocused = _usernameFocusNode.hasFocus;
      });
    });
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
    _passwordFocusNode.addListener(() {
      setState(() {
        _isPasswordFocused = _passwordFocusNode.hasFocus;
      });
    });
    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        _isConfirmPasswordFocused = _confirmPasswordFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  Widget buildSignUpForm(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Sign up",
                style: TextStyle(
                  fontSize: 32.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Container(
                width: 60.0,
                height: 3.0,
                margin: EdgeInsets.only(top: 8.0),
                decoration: BoxDecoration(
                  color: Color(0xFF71BB7B),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.0),

        // Username Field
        Text(
          "Username",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.0),
        TextField(
          controller: _usernameController,
          focusNode: _usernameFocusNode,
          decoration: InputDecoration(
            filled: false,
            hintText: "Enter your username",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.person_outline,
              color:
                  _isUsernameFocused ? Color(0xFF71BB7B) : Colors.grey.shade400,
              size: 20.0,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
        SizedBox(height: 24.0),

        // Email Field
        Text(
          "Email",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.0),
        TextField(
          controller: _emailController,
          focusNode: _emailFocusNode,
          decoration: InputDecoration(
            filled: false,
            hintText: "Enter your email",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.email_outlined,
              color: _isEmailFocused ? Color(0xFF71BB7B) : Colors.grey.shade400,
              size: 20.0,
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
        SizedBox(height: 24.0),

        // Password Field
        Text(
          "Password",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.0),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            filled: false,
            hintText: "Enter your password",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color:
                  _isPasswordFocused ? Color(0xFF71BB7B) : Colors.grey.shade400,
              size: 20.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color:
                    _obscurePassword ? Colors.grey.shade400 : Color(0xFF71BB7B),
                size: 20.0,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
        SizedBox(height: 24.0),

        // Confirm Password Field
        Text(
          "Confirm Password",
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 8.0),
        TextField(
          controller: _confirmPasswordController,
          focusNode: _confirmPasswordFocusNode,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            filled: false,
            hintText: "Confirm your password",
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color:
                  _isConfirmPasswordFocused
                      ? Color(0xFF71BB7B)
                      : Colors.grey.shade400,
              size: 20.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color:
                    _obscureConfirmPassword
                        ? Colors.grey.shade400
                        : Color(0xFF71BB7B),
                size: 20.0,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF71BB7B), width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 12.0),
          ),
        ),
        SizedBox(height: 30.0),

        // Create Account Button
        SizedBox(
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
            onPressed: () => onTapSignup(context),
            child: Text(
              "Create Account",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16.0,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Divider(
                color: Colors.grey.shade400,
                thickness: 1.5,
                indent: 25.0,
                endIndent: 25.0,
              ),
            ),
            Text("or"),
            Expanded(
              child: Divider(
                color: Colors.grey.shade400,
                thickness: 1.5,
                indent: 25.0,
                endIndent: 25.0,
              ),
            ),
          ],
        ),
        SizedBox(height: 15.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.google, color: Color(0xFF71BB7B), size: 30),
            SizedBox(width: 30.0),
            FaIcon(
              FontAwesomeIcons.facebook,
              color: Color(0xFF71BB7B),
              size: 30,
            ),
            SizedBox(width: 30.0),
            FaIcon(
              FontAwesomeIcons.xTwitter,
              color: Color(0xFF71BB7B),
              size: 30,
            ),
          ],
        ),
        SizedBox(height: 15.0),
        // Already have account text
        Center(
          child: RichText(
            text: TextSpan(
              text: "Already have an account? ",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16.0,
                fontWeight: FontWeight.w400,
              ),
              children: [
                TextSpan(
                  text: "Sign in",
                  style: TextStyle(
                    color: Color(0xFF71BB7B),
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer:
                      TapGestureRecognizer()
                        ..onTap = () {
                          ref.read(pageNumberProvider.notifier).state = 0;
                        },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncAuthUser = ref.watch(authUserProvider);
    return asyncAuthUser.when(
      data: (isAuthenticated) {
        if (!isAuthenticated) {
          return buildSignUpForm(context);
        } else {
          return SizedBox.shrink();
        }
      },
      loading: () {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          alignment: Alignment.center,
          child: LoadingAnimationWidget.staggeredDotsWave(
            color: Colors.green,
            size: 50,
          ),
        );
      },
      error: (error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign in failed! Try again.')),
          );
          ref.read(authUserProvider.notifier).initState();
        });
        return buildSignUpForm(context);
      },
    );
  }
}
