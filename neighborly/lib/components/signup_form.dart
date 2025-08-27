import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:neighborly/components/signin_form.dart';
import 'package:neighborly/components/snackbar.dart';
import 'package:neighborly/functions/alt_auth.dart';
import 'package:neighborly/functions/valid_email.dart';
import 'package:neighborly/pages/authPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignupForm extends ConsumerStatefulWidget {
  final String title;
  const SignupForm({super.key, required this.title});
  @override
  ConsumerState<SignupForm> createState() => _SignupFormState();
}

class _SignupFormState extends ConsumerState<SignupForm> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Basic form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Additional form controllers
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _divisionController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _preferredCommunityController =
      TextEditingController();

  // Focus nodes
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _addressLine1FocusNode = FocusNode();
  final FocusNode _addressLine2FocusNode = FocusNode();
  final FocusNode _cityFocusNode = FocusNode();
  final FocusNode _divisionFocusNode = FocusNode();
  final FocusNode _postalCodeFocusNode = FocusNode();
  final FocusNode _contactNumberFocusNode = FocusNode();
  final FocusNode _preferredCommunityFocusNode = FocusNode();

  // Focus states
  bool _isUsernameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;
  bool _isAddressLine1Focused = false;
  bool _isAddressLine2Focused = false;
  bool _isCityFocused = false;
  bool _isDivisionFocused = false;
  bool _isPostalCodeFocused = false;
  bool _isContactNumberFocused = false;
  bool _isPreferredCommunityFocused = false;

  String name = '', email = '', pswd = '', cnfrmPswd = '';
  String? selectedBloodGroup;

  // Blood group options
  final List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Updated method to save user info to Firestore with all fields
  Future<void> _postUserToFirestore({
    required String username,
    required String email,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String division,
    required String postalCode,
    required String contactNumber,
    required String bloodGroup,
    required String preferredCommunity,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('users').add({
        'username': username,
        'email': email,
        'addressLine1': addressLine1,
        'addressLine2': addressLine2 ?? '',
        'city': city,
        'division': division,
        'postalcode': postalCode,
        'contactNumber': contactNumber,
        'bloodGroup': bloodGroup,
        'preferredCommunity': preferredCommunity,
        'profilepicurl': '',
        'isAdmin': false,
        'blocked': false,
        'createdAt': Timestamp.now(),
      });
      print('✅ User data saved to Firestore successfully');
    } catch (e) {
      print('❌ Error saving user data to Firestore: $e');
      rethrow;
    }
  }

  void onTapSignup(BuildContext context) async {
    name = _usernameController.text.trim();
    email = _emailController.text.trim();
    pswd = _passwordController.text.trim();
    cnfrmPswd = _confirmPasswordController.text.trim();

    // Get additional form data
    final addressLine1 = _addressLine1Controller.text.trim();
    final addressLine2 = _addressLine2Controller.text.trim();
    final city = _cityController.text.trim();
    final division = _divisionController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final contactNumber = _contactNumberController.text.trim();
    final preferredCommunity = _preferredCommunityController.text.trim();

    // Validation
    if (name.isEmpty ||
        email.isEmpty ||
        pswd.isEmpty ||
        cnfrmPswd.isEmpty ||
        addressLine1.isEmpty ||
        city.isEmpty ||
        division.isEmpty ||
        postalCode.isEmpty ||
        contactNumber.isEmpty ||
        preferredCommunity.isEmpty ||
        selectedBloodGroup == null) {
      showSnackBarError(context, 'All required fields must be filled!');
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
        "Password must be at least 6 characters long!",
      );
      return;
    } else if (pswd != cnfrmPswd) {
      showSnackBarError(context, "Passwords don't match. Try again!");
      return;
    } else if (contactNumber.length < 10) {
      showSnackBarError(context, 'Please enter a valid contact number');
      return;
    }

    try {
      final authNotifier = ref.read(authUserProvider.notifier);
      await authNotifier.userAuthentication(
        name: name,
        email: email,
        password: pswd,
      );

      // After successful authentication, add user to Firestore
      await _postUserToFirestore(
        username: name,
        email: email,
        addressLine1: addressLine1,
        addressLine2: addressLine2.isNotEmpty ? addressLine2 : null,
        city: city,
        division: division,
        postalCode: postalCode,
        contactNumber: contactNumber,
        bloodGroup: selectedBloodGroup!,
        preferredCommunity: preferredCommunity,
      );
    } catch (e) {
      showSnackBarError(context, 'Registration failed. Please try again.');
    }
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
    _addressLine1FocusNode.addListener(() {
      setState(() {
        _isAddressLine1Focused = _addressLine1FocusNode.hasFocus;
      });
    });
    _addressLine2FocusNode.addListener(() {
      setState(() {
        _isAddressLine2Focused = _addressLine2FocusNode.hasFocus;
      });
    });
    _cityFocusNode.addListener(() {
      setState(() {
        _isCityFocused = _cityFocusNode.hasFocus;
      });
    });
    _divisionFocusNode.addListener(() {
      setState(() {
        _isDivisionFocused = _divisionFocusNode.hasFocus;
      });
    });
    _postalCodeFocusNode.addListener(() {
      setState(() {
        _isPostalCodeFocused = _postalCodeFocusNode.hasFocus;
      });
    });
    _contactNumberFocusNode.addListener(() {
      setState(() {
        _isContactNumberFocused = _contactNumberFocusNode.hasFocus;
      });
    });
    _preferredCommunityFocusNode.addListener(() {
      setState(() {
        _isPreferredCommunityFocused = _preferredCommunityFocusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _divisionController.dispose();
    _postalCodeController.dispose();
    _contactNumberController.dispose();
    _preferredCommunityController.dispose();

    // Dispose focus nodes
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _addressLine1FocusNode.dispose();
    _addressLine2FocusNode.dispose();
    _cityFocusNode.dispose();
    _divisionFocusNode.dispose();
    _postalCodeFocusNode.dispose();
    _contactNumberFocusNode.dispose();
    _preferredCommunityFocusNode.dispose();

    super.dispose();
  }

  Widget buildSignUpForm(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
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
                    _isUsernameFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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
                color:
                    _isEmailFocused ? Color(0xFF71BB7B) : Colors.grey.shade400,
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
          SizedBox(height: 40.0),

          // Section Header for Additional Information
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tell us about yourself",
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4.0),
                Text(
                  "This information helps us connect you with your community",
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                ),
                Container(
                  width: 80.0,
                  height: 2.0,
                  margin: EdgeInsets.only(top: 8.0),
                  decoration: BoxDecoration(
                    color: Color(0xFF71BB7B),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32.0),

          // Contact Number Field
          Text(
            "Contact Number",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _contactNumberController,
            focusNode: _contactNumberFocusNode,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              filled: false,
              hintText: "Enter your contact number",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.phone_outlined,
                color:
                    _isContactNumberFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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

          // Address Line 1 Field
          Text(
            "Address Line 1",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _addressLine1Controller,
            focusNode: _addressLine1FocusNode,
            decoration: InputDecoration(
              filled: false,
              hintText: "Enter your address line 1",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.home_outlined,
                color:
                    _isAddressLine1Focused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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

          // Address Line 2 Field (Optional)
          Text(
            "Address Line 2 (Optional)",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _addressLine2Controller,
            focusNode: _addressLine2FocusNode,
            decoration: InputDecoration(
              filled: false,
              hintText: "Enter your address line 2",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.home_outlined,
                color:
                    _isAddressLine2Focused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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

          // City and Division Row
          Row(
            children: [
              // City Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "City",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: _cityController,
                      focusNode: _cityFocusNode,
                      decoration: InputDecoration(
                        filled: false,
                        hintText: "Enter city",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.location_city_outlined,
                          color:
                              _isCityFocused
                                  ? Color(0xFF71BB7B)
                                  : Colors.grey.shade400,
                          size: 20.0,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF71BB7B),
                            width: 2.0,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.0),
              // Division Field
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Division",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: _divisionController,
                      focusNode: _divisionFocusNode,
                      decoration: InputDecoration(
                        filled: false,
                        hintText: "Enter division",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        prefixIcon: Icon(
                          Icons.map_outlined,
                          color:
                              _isDivisionFocused
                                  ? Color(0xFF71BB7B)
                                  : Colors.grey.shade400,
                          size: 20.0,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF71BB7B),
                            width: 2.0,
                          ),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.0),

          // Postal Code Field
          Text(
            "Postal Code",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _postalCodeController,
            focusNode: _postalCodeFocusNode,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              filled: false,
              hintText: "Enter postal code",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.local_post_office_outlined,
                color:
                    _isPostalCodeFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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

          // Blood Group Dropdown
          Text(
            "Blood Group",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          DropdownButtonFormField<String>(
            value: selectedBloodGroup,
            decoration: InputDecoration(
              filled: false,
              hintText: "Select your blood group",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.bloodtype_outlined,
                color:
                    selectedBloodGroup != null
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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
            items:
                bloodGroups.map((String bloodGroup) {
                  return DropdownMenuItem<String>(
                    value: bloodGroup,
                    child: Text(bloodGroup),
                  );
                }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                selectedBloodGroup = newValue;
              });
            },
          ),
          SizedBox(height: 24.0),

          // Preferred Community Field
          Text(
            "Preferred Community",
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8.0),
          TextField(
            controller: _preferredCommunityController,
            focusNode: _preferredCommunityFocusNode,
            decoration: InputDecoration(
              filled: false,
              hintText: "Enter preferred community to join",
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.groups_outlined,
                color:
                    _isPreferredCommunityFocused
                        ? Color(0xFF71BB7B)
                        : Colors.grey.shade400,
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
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('rememberMe', rememberMe);
                  ref.read(authUserProvider.notifier).stateOnRemember();
                  final result = await signInWithGoogle(context);
                  if (result == null) {
                    ref.read(authUserProvider.notifier).initState();
                  }
                },
                child: FaIcon(
                  FontAwesomeIcons.google,
                  color: Color(0xFF71BB7B),
                  size: 30,
                ),
              ),
              SizedBox(width: 30.0),
              GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('rememberMe', rememberMe);
                  ref.read(authUserProvider.notifier).stateOnRemember();
                  final result = await signInWithFacebook(context);
                  if (result == null) {
                    ref.read(authUserProvider.notifier).initState();
                  }
                },
                child: FaIcon(
                  FontAwesomeIcons.facebook,
                  color: Color(0xFF71BB7B),
                  size: 30,
                ),
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
          SizedBox(height: 20.0),
        ],
      ),
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
            const SnackBar(content: Text('Sign up failed! Try again.')),
          );
          ref.read(authUserProvider.notifier).initState();
        });
        return buildSignUpForm(context);
      },
    );
  }
}
