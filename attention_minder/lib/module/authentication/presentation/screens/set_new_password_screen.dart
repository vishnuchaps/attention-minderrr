import 'package:attention_minder/Config/widgets/custom_elevated_button.dart';
import 'package:attention_minder/Config/widgets/custom_password_label.dart';
import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/spaces.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:attention_minder/module/authentication/presentation/screens/password_change_success_screen.dart';
import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SetNewPasswordScreen extends StatefulWidget {
  final String email;

  const SetNewPasswordScreen({super.key, required this.email});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        if (state is ChangePasswordLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
        } else {
          Navigator.of(context, rootNavigator: true).pop(); // Close loader
        }

        if (state is ChangePasswordSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const PasswordChangeSuccessScreen(),
            ),
          );
        } else if (state is ChangePasswordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColor.whiteColor,
        body: Container(
          width: deviceWidth,
          height: deviceHeight,
          color: AppColor.whiteColor,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  Padding(
                    padding: EdgeInsets.all(deviceWidth * 0.02),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: deviceWidth * 0.1,
                        height: deviceWidth * 0.1,
                        padding: EdgeInsets.only(left: deviceWidth * 0.02),
                        decoration: const BoxDecoration(
                          color: Color(0xFFECECEC),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.arrow_back_ios,
                            size: deviceWidth * 0.05,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(
                    height: deviceHeight * 0.45,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.065),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Set a new password",
                            style: TextStyles.poppinsS20Black,
                          ),
                          kH10,
                          Text(
                            "Create a new password. Ensure it differs \nfrom previous ones for security",
                            style: TextStyles.poppinsR16Black,
                            textAlign: TextAlign.center,
                          ),
                          kH15,

                          // Password Field
                            CustomLabelPassTextFiled(
                              hint: "Password",
                              label: "Password",
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter password';
                                } else if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            kH15,

                            // Confirm Password Field
                            CustomLabelPassTextFiled(
                              hint: "Confirm Password",
                              label: "Confirm Password",
                              controller: _confirmPasswordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm password';
                                }
                                return null;
                              },
                            ),
                          kH15,

                          // Submit Button
                          CustomElevatedbutton(
                            width: deviceWidth * 0.87,
                            label: "Update Password",
                            callBack: () {
                              if (_formKey.currentState!.validate()) {
                                if (_passwordController.text !=
                                    _confirmPasswordController.text) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text("Passwords do not match")),
                                  );
                                  return;
                                }

                                context.read<AuthenticationBloc>().add(
                                  ChangePasswordRequested(
                                    email: widget.email,
                                    newPassword:
                                    _passwordController.text,
                                  ),
                                );
                              }
                            },
                          ),
                          kH20,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
