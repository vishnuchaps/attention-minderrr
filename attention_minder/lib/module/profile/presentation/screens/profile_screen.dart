import 'package:attention_minder/Config/widgets/arrow_left_icon_widget.dart';
import 'package:attention_minder/constant/app_constant.dart';
import 'package:attention_minder/module/authentication/presentation/screens/login_screen.dart';
import 'package:attention_minder/module/landing/presentation/screens/landing_screen.dart';
import 'package:attention_minder/module/profile/data/model/user_data_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:iconly/iconly.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bloc/profile_bloc.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String gender = 'Male';
  String country = 'Select country';
  String? dob;
  double height = 0;
  double weight = 0;
  String? profileImageUrl;
  bool _hasFetchedProfile = false;
  final List<String> countries = [
    'Select country',
    'USA',
    'India',
    'Canada',
    'UK',
  ];
  final List<String> genders = ['Male', 'Female', 'Other'];

  late TextEditingController dobController;
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? id = prefs.getInt('userId');

      if (_formKey.currentState!.validate()) {
        final formData = FormData.fromMap({
          'id': id,
          'username': name,
          'email': email,
          'dob': dob,
          'gender': gender.toUpperCase(),
          'country': country,
          'height': height.toString(),
          'weight': weight.toString(),
          'profile_image': await MultipartFile.fromFile(
            _image!.path,
            filename: _image!.path.split('/').last,
          ),
        });

        context.read<ProfileBloc>().add(UpdateProfilePictureEvent(formData));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    dobController = TextEditingController();
    nameController = TextEditingController();
    emailController = TextEditingController();
    heightController = TextEditingController();
    weightController = TextEditingController();

    // Fetch profile on screen load
    context.read<ProfileBloc>().add(GetTheProfileEvent());
  }

  @override
  void dispose() {
    dobController.dispose();
    nameController.dispose();
    emailController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    final parsedDate = DateTime.tryParse(date);
    return parsedDate != null
        ? DateFormat('dd/MM/yyyy').format(parsedDate)
        : '';
  }

  void _populateProfileData(UserData profile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (profile.profileImageUrl != null &&
        profile.profileImageUrl!.isNotEmpty) {
      await prefs.setString('profileImageUrl', profile.profileImageUrl!);
    }

    setState(() {
      name = profile.username;
      email = profile.email;
      gender = _mapApiGenderToUi(profile.gender);
      country = _validateCountry(profile.country ?? 'USA');
      dob = profile.dob;
      height = profile.height ?? 0;
      weight = profile.weight ?? 0;
      profileImageUrl = profile.profileImageUrl;
      _hasFetchedProfile = true;

      nameController.text = name;
      emailController.text = email;
      dobController.text = _formatDate(dob);
      heightController.text = height.toString();
      weightController.text = weight.toString();
    });
  }

  String _validateCountry(String countryFromApi) {
    return countries.contains(countryFromApi)
        ? countryFromApi
        : countries.first;
  }

  String _mapApiGenderToUi(String apiGender) {
    switch (apiGender.toUpperCase()) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      default:
        return 'Other';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = dob != null ? DateTime.tryParse(dob!) : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        dob = DateFormat('yyyy-MM-dd').format(picked);
        dobController.text = _formatDate(dob);
      });
    }
  }

  void _saveProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? id = prefs.getInt('userId');
    if (_formKey.currentState!.validate()) {
      final userData = {
        'id': id,
        'username': name,
        'email': email,
        'dob': dob,
        'gender': gender.toUpperCase(),
        'country': country,
        'height': height.toString(),
        'weight': weight.toString(),
      };

      context.read<ProfileBloc>().add(UpdateProfileEvent(userData));
    }
  }

  bool get _isProfileComplete {
    final hasName = nameController.text.trim().isNotEmpty;
    final hasEmail = emailController.text.trim().isNotEmpty;
    final hasDob = dob != null && dob!.trim().isNotEmpty;
    final hasGender = gender.trim().isNotEmpty;
    final hasCountry = country.trim().isNotEmpty && country != 'Select country';
    final hasHeight =
        double.tryParse(heightController.text.trim()) != null &&
        (double.tryParse(heightController.text.trim()) ?? 0) > 0;
    final hasWeight =
        double.tryParse(weightController.text.trim()) != null &&
        (double.tryParse(weightController.text.trim()) ?? 0) > 0;

    return hasName &&
        hasEmail &&
        hasDob &&
        hasGender &&
        hasCountry &&
        hasHeight &&
        hasWeight;
  }

  bool get _shouldWarnBeforeLeaving {
    return _hasFetchedProfile && !_isProfileComplete;
  }

  Future<void> _handleBackNavigation() async {
    if (_shouldWarnBeforeLeaving) {
      await showCompleteProfileWarning(context);
      return;
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LandingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: !_shouldWarnBeforeLeaving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBackNavigation();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEAEBED),
        body: SafeArea(
          child: BlocConsumer<ProfileBloc, ProfileState>(
            listenWhen: (previous, current) {
              return current is FetchProfileSuccess ||
                  current is FetchProfileFailed ||
                  current is UpdateProfileSuccess ||
                  current is UpdateProfileFailed ||
                  current is UpdateProfilePictureSuccess ||
                  current is UpdateProfilePictureFailed;
            },

            listener: (context, state) {
              final messenger = ScaffoldMessenger.of(context);

              if (state is FetchProfileSuccess) {
                _populateProfileData(state.data);
              } else if (state is FetchProfileFailed) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Failed to load profile: ${state.message}'),
                  ),
                );
              } else if (state is UpdateProfileSuccess) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );

                // Avoid duplicate trigger during rebuild
                Future.microtask(() {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LandingScreen()),
                  );
                });
              } else if (state is UpdateProfileFailed) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(content: Text('Failed to update profile')),
                );
              } else if (state is UpdateProfilePictureSuccess) {
                if (state.profileImageUrl != null &&
                    state.profileImageUrl!.isNotEmpty) {
                  setState(() {
                    profileImageUrl = state.profileImageUrl;
                    _image = null;
                  });
                } else {
                  context.read<ProfileBloc>().add(GetTheProfileEvent());
                }

                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Profile picture updated successfully'),
                  ),
                );
              } else if (state is UpdateProfilePictureFailed) {
                messenger.clearSnackBars();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Failed to update profile picture'),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ProfileLoading && profileImageUrl == null) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: screenHeight * 0.02),
                      _buildProfileAvatar(screenWidth),
                      SizedBox(height: screenHeight * 0.025),
                      AboutProfileInformationCard(),
                      SizedBox(height: screenHeight * 0.02),

                      // Name field
                      _buildInputField(
                        label: "User Name",
                        controller: nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                        onChanged: (val) => name = val,
                      ),

                      // Email field
                      _buildInputField(
                        label: "Email",
                        controller: emailController,
                        readOnly: true,
                        helperText: 'Email cannot be changed',
                        suffixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          color: Color(0xFF8A93A6),
                          size: 20,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[\w-+\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onChanged: (_) {},
                      ),

                      // Date of Birth field
                      _buildDatePickerField(
                        label: "Date of Birth",
                        controller: dobController,
                        validator: (value) {
                          if (dob == null || dob!.isEmpty) {
                            return 'Please select your date of birth';
                          }
                          return null;
                        },
                      ),

                      // Gender dropdown
                      _buildDropdownField(
                        label: "Gender",
                        value: gender,
                        items: genders,
                        validator: (value) {
                          if (value == null || value == 'Select gender') {
                            return 'Please select your gender';
                          }
                          return null;
                        },
                        onChanged: (val) => gender = val!,
                      ),

                      // Country dropdown
                      _buildDropdownField(
                        label: "Country/Region",
                        value: country,
                        items: countries,
                        validator: (value) {
                          if (value == null || value == 'Select country') {
                            return 'Please select your country';
                          }
                          return null;
                        },
                        onChanged: (val) => country = val!,
                      ),

                      // Height field
                      _buildInputField(
                        label: "Height in cm",
                        controller: heightController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height <= 0) {
                            return 'Please enter a valid height';
                          }
                          return null;
                        },
                        onChanged: (val) => height = double.tryParse(val) ?? 0,
                      ),

                      // Weight field
                      _buildInputField(
                        label: "Weight in kg",
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight <= 0) {
                            return 'Please enter a valid weight';
                          }
                          return null;
                        },
                        onChanged: (val) => weight = double.tryParse(val) ?? 0,
                      ),
                      SizedBox(height: screenHeight * 0.01),

                      WhyImportantCard(),
                      SizedBox(height: screenHeight * 0.02),
                      _buildSaveButton(screenWidth),
                      // SizedBox(height: screenHeight * 0.04),
                      // _buildNextButton(),
                      SizedBox(height: screenHeight * 0.02),
                      _buildLogoutButton(),
                      SizedBox(height: screenHeight * 0.04),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> showCompleteProfileWarning(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const CompleteProfileWarningDialog(),
    );
  }

  Widget _buildSaveButton(double screenWidth) {
    return Center(
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: state is ProfileLoading ? null : _saveProfile,
            child: Container(
              height: 59,
              width: double.infinity,
              decoration: BoxDecoration(
                color: state is ProfileLoading ? Colors.grey : Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: state is ProfileLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Handle next button action
        },
        child: Container(
          height: 43,
          width: 130,
          decoration: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Next",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                // Icon(IconlyLight.arrow_right, color: Colors.white)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 68,
                height: 68,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFD9ECFF),
                      Color(0xFF2387EA),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.16),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: const Color(0xFF2387EA).withValues(alpha: 0.18),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image(
                      image: _editableProfileImageProvider(),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildProfileImageFallback();
                      },
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2387EA),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Container(
          width: screenWidth * 0.7,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: const LinearGradient(
              begin: Alignment(-1, 0),
              end: Alignment(1, 0),
              colors: [Color(0xFF1F4F8D), Color(0xFF14345C)],
              stops: [-0.0331, 1.0752],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 45,
                height: 40,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('asset/images/Badge2.png'),
                  ),
                ),
                child: const Center(
                  child: GradientText(
                    "5 ",
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFCC60), Color(0xFFFDC654)],
                    ),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const SizedBox(
                width: 145,
                child: Text(
                  "You have earned 4 points",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 5),
              CircularPercentIndicator(
                radius: 20.0,
                lineWidth: 5.0,
                percent: 0.3,
                center: const Text(
                  "30%",
                  style: TextStyle(fontSize: 10, color: Color(0xFFFFB61D)),
                ),
                progressColor: const Color(0xFFFFB61D),
                backgroundColor: const Color(0xFFB4B4B4),
                circularStrokeCap: CircularStrokeCap.round,
              ),
            ],
          ),
        ),
      ],
    );
  }

  ImageProvider _editableProfileImageProvider() {
    if (_image != null) {
      return FileImage(_image!);
    }

    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      final imageUrl = profileImageUrl!.startsWith('http')
          ? profileImageUrl!
          : Uri.parse(baseUrl).resolve(profileImageUrl!).toString();

      return NetworkImage(imageUrl);
    }

    return const AssetImage('asset/images/Ellipse 125.png');
  }

  Widget _buildProfileImageFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF4FF), Color(0xFFB9DCFF)],
        ),
      ),
      child: const Icon(
        Icons.person_rounded,
        size: 34,
        color: Color(0xFF1F6FB8),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
    required Function(String) onChanged,
    TextInputType? keyboardType,
    bool readOnly = false,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            validator: validator,
            onChanged: onChanged,
            autovalidateMode:
                AutovalidateMode.onUserInteraction, // Add this line
            style: TextStyle(
              color: readOnly
                  ? const Color(0xFF6D7484)
                  : const Color(0xFF111827),
              fontWeight: readOnly ? FontWeight.w600 : FontWeight.w400,
            ),

            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly
                  ? const Color(0xFFE8EBF0)
                  : const Color(0xFFF6F7FA),
              helperText: helperText,
              helperStyle: const TextStyle(
                color: Color(0xFF7C8598),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              // suffixIcon: const Icon(IconlyLight.edit_square),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required TextEditingController controller,
    required FormFieldValidator<String> validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            readOnly: true,
            validator: validator,
            onTap: () => _selectDate(context),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF6F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              // suffixIcon: const Icon(IconlyLight.calendar),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ArrowLeftIconWidget(callback: _handleBackNavigation),
        const SizedBox(height: 20),
        const Text(
          'Profile',
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            height: 1.4,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required FormFieldValidator<String?> validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: onChanged,
            validator: validator,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF6F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.clear();
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            }
          }
        },
        child: Container(
          height: 59,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FA),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text(
                "Logout",
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompleteProfileWarningDialog extends StatelessWidget {
  const CompleteProfileWarningDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: width < 380 ? 14 : 20,
        vertical: 24,
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF777777), width: 7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -4,
              right: -5,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.close_rounded,
                  size: 24,
                  color: Color(0xFF555555),
                ),
              ),
            ),

            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),

                Container(
                  width: 43,
                  height: 43,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFFB800),
                  ),
                  child: const Icon(
                    Icons.priority_high_rounded,
                    color: Colors.white,
                    size: 33,
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  'Please Complete Your Profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 13),

                const Text(
                  'To provide accurate attention assessments and\n'
                  'age-appropriate activities, we recommend\n'
                  'completing the profile now.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.6,
                    height: 1.28,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF151515),
                  ),
                ),

                const SizedBox(height: 13),

                const Text(
                  'If this account is being created by a parent,\n'
                  'please make sure the details belong to the\n'
                  'actual user (for example, your child).',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.6,
                    height: 1.28,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF151515),
                  ),
                ),

                const SizedBox(height: 15),

                Container(height: 1, color: const Color(0xFFE0E0E0)),

                const SizedBox(height: 12),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Without accurate profile information:',
                    style: TextStyle(
                      fontSize: 13.7,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                const _WarningPoint(
                  text: 'Questions may not match the user’s age',
                ),
                const SizedBox(height: 7),
                const _WarningPoint(
                  text: 'Recommendations may be less effective',
                ),
                const SizedBox(height: 7),
                const _WarningPoint(
                  text: 'Progress insights may be inaccurate',
                ),

                const SizedBox(height: 19),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: const Color(0xFF0A84FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Complete Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningPoint extends StatelessWidget {
  final String text;

  const _WarningPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.cancel_outlined, size: 16, color: Color(0xFFD94A4A)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.4,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202124),
            ),
          ),
        ),
      ],
    );
  }
}

class GradientText extends StatelessWidget {
  final String text;
  final Gradient gradient;
  final double fontSize;
  final FontWeight fontWeight;

  const GradientText(
    this.text, {
    super.key,
    required this.gradient,
    this.fontSize = 40,
    this.fontWeight = FontWeight.normal,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
        textAlign: TextAlign.start,
      ),
    );
  }
}

class WhyImportantCard extends StatelessWidget {
  const WhyImportantCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isSmall = width < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isSmall ? 15 : 18,
        18,
        isSmall ? 15 : 18,
        18,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFBEDCFF), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 13,
            backgroundColor: Color(0xFF2387EA),
            child: Icon(Icons.shield_outlined, color: Colors.white, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Why this is important?',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152B4A),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Accurate information helps us provide\nage-appropriate assessments, activities\nand meaningful progress insights.',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.38,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF202124),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AboutProfileInformationCard extends StatelessWidget {
  const AboutProfileInformationCard({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isSmall = width < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isSmall ? 16 : 18,
        17,
        isSmall ? 16 : 18,
        14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBEDCFF), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: Color(0xFF2387EA),
                child: Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'About Profile Information',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152B4A),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          const Text(
            'Please enter the details of the actual person who\nwill use the app.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.42,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202124),
            ),
          ),

          const SizedBox(height: 13),

          const Text(
            'If you are a parent creating this account for your\nchild, kindly provide your child\'s age and other\ninformation. This helps us personalize questions\nand activities correctly.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.42,
              fontWeight: FontWeight.w500,
              color: Color(0xFF202124),
            ),
          ),

          const SizedBox(height: 24),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileInfoFeature(
                icon: Icons.sentiment_satisfied_alt_rounded,
                label: 'Age-based\nexercises',
              ),
              _ProfileInfoFeature(
                icon: Icons.trending_up_rounded,
                label: 'Better progress\ntracking',
              ),
              _ProfileInfoFeature(
                icon: Icons.star_border_rounded,
                label: 'Personalized\nrecommendations',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ProfileInfoFeature({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Icon(icon, size: 34, color: const Color(0xFF2387EA)),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              height: 1.18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111111),
            ),
          ),
        ],
      ),
    );
  }
}
