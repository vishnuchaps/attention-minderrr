import 'package:attention_minder/Config/widgets/custom_elevated_button.dart';
import 'package:attention_minder/Config/widgets/custom_label_text.dart';
import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/spaces.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/authentication_bloc.dart';
import 'otp_verification_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Enter a valid email address';
    }
    return null;
  }

  void _requestPasswordReset(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      BlocProvider.of<AuthenticationBloc>(context)
          .add(ForgotPasswordRequested(email: email));
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColor.whiteColor,
      body: BlocConsumer<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Password reset link sent to your email.')),
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationScreen(
                  email: _emailController.text,
                ),
              ),
            );
          } else if (state is ForgotPasswordError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Failed to send reset link: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          return Container(
            width: deviceWidth,
            height: deviceHeight,
            color: AppColor.whiteColor,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      height: deviceHeight * 0.55,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.065),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                "Forgot password",
                                style: TextStyles.poppinsS20Black,
                              ),
                              kH10,
                              Text(
                                "Please enter your email to reset the \n password",
                                style: TextStyles.poppinsR16Black,
                                textAlign: TextAlign.center,
                              ),
                              kH20,
                              CustomLabelTextFiled(
                                hint: "Enter Your Email",
                                label: "Email",
                                controller: _emailController,
                                validator: _validateEmail,
                              ),
                            kH15,
                            CustomElevatedbutton(
                              width: deviceWidth * 0.87,
                              label: state is ForgotPasswordLoading
                                  ? 'Sending...'
                                  : "Reset Password",
                              callBack: state is ForgotPasswordLoading
                                  ? null
                                  : () => _requestPasswordReset(context),
                              child: state is ForgotPasswordLoading
                                  ? SizedBox(
                                      height: deviceWidth * 0.05,
                                      width: deviceWidth * 0.05,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : null,
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
          );
        },
      ),
    );
  }
}
