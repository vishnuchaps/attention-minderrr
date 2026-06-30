import 'package:attention_minder/Config/Theme/Text_style.dart';
import 'package:attention_minder/Config/widgets/custom_button.dart';
import 'package:attention_minder/Config/widgets/custom_text_form_field.dart';
import 'package:attention_minder/Config/widgets/loading_widget.dart';
import 'package:attention_minder/Config/widgets/social_login_widget.dart';
import 'package:attention_minder/constant/asset_path.dart';
import 'package:attention_minder/dependency_injection/injection_container.dart';
import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:attention_minder/module/authentication/presentation/screens/login_screen.dart';
import 'package:attention_minder/module/authentication/presentation/screens/welcome_attention_screen.dart';
import 'package:attention_minder/utils/validators/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final AuthenticationBloc authenticationBloc = getIt<AuthenticationBloc>();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocProvider.value(
      value: authenticationBloc,
      child: Scaffold(
        body: BlocListener<AuthenticationBloc, AuthenticationState>(
          listener: (context, state) {
            if (state is AuthenticationSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => WelcomeAttentionScreen(),
                ),
              );
            } else if (state is AuthenticationError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: screenHeight * 0.7,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                  ),
                ),
              );
            }
          },
          child: BlocBuilder<AuthenticationBloc, AuthenticationState>(
            builder: (context, state) {
              bool isLoading = state is AuthenticationLoading;

              return Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: Container(
                      decoration: gradientDecoration,
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.02),
                          Stack(
                            children: [
                              Image.asset(
                                backgroundVector,
                                width: double.infinity,
                                height: screenHeight * 0.25,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                left: screenWidth * 0.25,
                                top: screenHeight * 0.02,
                                right: screenWidth * 0.25,
                                child: Image.asset(
                                  height: screenHeight * 0.2,
                                  onBoardingImage,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAEBED),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(40.0),
                                  topRight: Radius.circular(40.0),
                                ),
                              ),
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: screenHeight * 0.02),
                                      Center(
                                        child: Text(
                                          'Register',
                                          style: GoogleFonts.nunitoSans(
                                            fontSize: screenWidth * 0.045,
                                            fontWeight: FontWeight.w700,
                                            height: 22.4 / 16.0,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      CustomTextFormField(
                                        controller: nameController,
                                        labelText: 'Name',
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Name is required';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      CustomTextFormField(
                                        controller: emailController,
                                        labelText: 'Email',
                                        validator: validateEmail,
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      CustomTextFormField(
                                        controller: passwordController,
                                        labelText: 'Password',
                                        obscureText: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Password is required';
                                          }
                                          if (value.length < 6) {
                                            return 'Password must be at least 6 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      CustomTextFormField(
                                        controller: confirmPasswordController,
                                        labelText: 'Confirm Password',
                                        obscureText: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Confirm Password is required';
                                          }
                                          if (value !=
                                              passwordController.text) {
                                            return 'Passwords do not match';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: screenHeight * 0.025),
                                      BlocBuilder<
                                        AuthenticationBloc,
                                        AuthenticationState
                                      >(
                                        builder: (context, state) {
                                          return Column(
                                            children: [
                                              if (state is AuthenticationError)
                                                Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.all(
                                                    screenWidth * 0.03,
                                                  ),
                                                  margin: EdgeInsets.only(
                                                    bottom: screenHeight * 0.02,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red.shade50,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.red.shade300,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.error_outline,
                                                        color:
                                                            Colors.red.shade700,
                                                        size:
                                                            screenWidth * 0.05,
                                                      ),
                                                      SizedBox(
                                                        width:
                                                            screenWidth * 0.02,
                                                      ),
                                                      Expanded(
                                                        child: Text(
                                                          state.message,
                                                          style: TextStyle(
                                                            color: Colors
                                                                .red
                                                                .shade700,
                                                            fontSize:
                                                                screenWidth *
                                                                0.035,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              CustomButton(
                                                title: 'Register',
                                                color: const Color(0xFF0F79FF),
                                                onTap: () {
                                                  if (_formKey.currentState!
                                                      .validate()) {
                                                    authenticationBloc.add(
                                                      RegisterEvent(
                                                        email: emailController
                                                            .text
                                                            .trim(),
                                                        password:
                                                            passwordController
                                                                .text
                                                                .trim(),
                                                        name: nameController
                                                            .text
                                                            .trim(),
                                                        conformPassword:
                                                            confirmPasswordController
                                                                .text
                                                                .trim(),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: Colors.grey,
                                              thickness: 1,
                                              endIndent: screenWidth * 0.02,
                                            ),
                                          ),
                                          Text(
                                            'or',
                                            style: GoogleFonts.poppins(
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.w400,
                                              height: 24.0 / 16.0,
                                              decoration: TextDecoration.none,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: Colors.grey,
                                              thickness: 1,
                                              indent: screenWidth * 0.02,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      SocialLoginButton(
                                        label: 'Log in with Facebook',
                                        activeBorderColor: const Color(
                                          0xFF4883F7,
                                        ),
                                        activeBackgroundColor: const Color(
                                          0xFFC9D9F9,
                                        ),
                                        inactiveBackgroundColor: const Color(
                                          0xFFF6F7FA,
                                        ),
                                        onTap: () {},
                                        iconPath: facebookIcon,
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      SocialLoginButton(
                                        label: 'Log in with Google',
                                        activeBorderColor: const Color(
                                          0xFF4883F7,
                                        ),
                                        activeBackgroundColor: const Color(
                                          0xFFC9D9F9,
                                        ),
                                        inactiveBackgroundColor: const Color(
                                          0xFFF6F7FA,
                                        ),
                                        onTap: () {},
                                        iconPath: googleIcon,
                                      ),
                                      SizedBox(height: screenHeight * 0.02),
                                      Center(
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    LoginScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Already have an account? Sign In',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: screenWidth * 0.04,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading) const LoadingWidget(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
