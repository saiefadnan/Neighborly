import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neighborly/pages/authPage.dart';

class NewPass extends ConsumerStatefulWidget {
  final String title;
  const NewPass({super.key, required this.title});
  @override
  ConsumerState<NewPass> createState() => _NewPassState();
}

class _NewPassState extends ConsumerState<NewPass> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  void onTapUpdate() {
    ref.read(pageNumberProvider.notifier).state = 5;
  }

  @override
  void initState() {
    super.initState();
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 40.0),

          // Title
          Container(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Set a New Password",
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                Container(
                  width: 160.0,
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

          // Subtitle
          Text(
            "Create a new password. Ensure it differs from previous ones for security.",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 40.0),

          // Password Field
          Text(
            "New Password",
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
              hintText: "Enter new password",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
                fontSize: 18.0,
              ),
              prefixIcon: Icon(
                Icons.lock_outline,
                color:
                    _isPasswordFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
                size: 20.0,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color:
                      _obscurePassword
                          ? Colors.grey.shade400
                          : Color(0xFF71BB7B),
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
              hintText: "Confirm new password",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
                fontSize: 18.0,
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
          SizedBox(height: 40.0),

          // Update Password Button
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
              onPressed: () => onTapUpdate(),
              child: Text(
                "Update Password",
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
    );
  }
}
