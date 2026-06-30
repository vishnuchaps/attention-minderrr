import 'package:attention_minder/Config/widgets/custom_elevated_button.dart';
import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/spaces.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:attention_minder/module/authentication/presentation/bloc/authentication_bloc.dart';
import 'package:attention_minder/module/authentication/presentation/screens/set_new_password_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email; // pass the email here

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());

  String getOtp() {
    return _controllers.map((c) => c.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColor.whiteColor,
      body: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) {
          if (state is OtpVerificationLoading) {
            // show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );
          } else if (state is OtpVerificationSuccess) {
            Navigator.pop(context); // close loading
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ));
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SetNewPasswordScreen(
                  email: widget.email,
                ),
              ),
            );
          } else if (state is OtpVerificationError) {
            Navigator.pop(context); // close loading
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ));
          }
        },
        child: SingleChildScrollView(
          child: SizedBox(
            width: deviceWidth,
            height: deviceHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Padding(
                  padding: EdgeInsets.all(deviceWidth * 0.02),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: deviceWidth * 0.1,
                      height: deviceWidth * 0.1,
                      padding: EdgeInsets.only(left: deviceWidth * 0.02),
                      decoration: const BoxDecoration(
                        color: Color(0xFFECECEC),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.arrow_back_ios, size: deviceWidth * 0.05),
                      ),
                    ),
                  ),
                ),
                // OTP instruction and form
                SizedBox(
                  height: deviceHeight * 0.55,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.065),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Check your email",
                            style: TextStyles.poppinsS20Black),
                        kH10,
                        Text(
                          "We sent a reset link to ${widget.email}\nEnter the 6-digit code from the email",
                          style: TextStyles.poppinsR16Black,
                          textAlign: TextAlign.center,
                        ),
                        kH20,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return Container(
                              width: deviceWidth * 0.12,
                              height: deviceWidth * 0.12,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: const Color(0xFFE1E1E1), width: 1),
                              ),
                              child: Center(
                                child: TextField(
                                  controller: _controllers[index],
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                      fontSize: deviceWidth * 0.05,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    if (value.isNotEmpty && index < 5) {
                                      FocusScope.of(context).nextFocus();
                                    } else if (value.isEmpty && index > 0) {
                                      FocusScope.of(context).previousFocus();
                                    }
                                  },
                                ),
                              ),
                            );
                          }),
                        ),
                        kH15,
                        CustomElevatedbutton(
                          width: deviceWidth * 0.87,
                          label: "Verify Code",
                          callBack: () {
                            final otp = getOtp();
                            if (otp.length == 6) {
                              context.read<AuthenticationBloc>().add(
                                    OtpVerificationRequested(
                                      email: widget.email,
                                      otp: otp,
                                    ),
                                  );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter 6-digit OTP."),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                        ),
                        kH40,
                        RichText(
                          text: TextSpan(
                            text: "Haven't got the email yet? ",
                            style: TextStyles.poppinsM12Black,
                            children: [
                              TextSpan(
                                text: "Resend email",
                                style: TextStyles.poppinsM12White.copyWith(
                                  color: const Color(0xFF514CF9),
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: Handle resend OTP here
                                  },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
