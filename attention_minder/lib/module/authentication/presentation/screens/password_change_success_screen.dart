import 'package:attention_minder/Config/widgets/custom_elevated_button.dart';
import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/spaces.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';


class PasswordChangeSuccessScreen extends StatelessWidget {
  const PasswordChangeSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceHeight = MediaQuery.of(context).size.height;
    final deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColor.whiteColor,

      body: Container(
          width: deviceWidth,
          height: deviceHeight,
          color: AppColor.whiteColor,
          child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.all(deviceWidth * 0.02),
                    child: GestureDetector(
                      onTap: (){
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: deviceWidth * 0.1,
                        height: deviceWidth * 0.1,
                        padding: EdgeInsets.only(left: deviceWidth * 0.02),
                        decoration: const BoxDecoration(
                          color: Color(0xFFECECEC), // Background color
                          shape: BoxShape.circle, // Makes it rounded
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
                    height: deviceHeight * 0.35,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.065),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Stack(
                            alignment: Alignment.center, // Center the right_icon.png
                            children: [
                              Image.asset(
                                "asset/images/successful_icon.jpeg", // Background Image
                                height: deviceHeight * 0.15,
                                fit: BoxFit.contain,
                              ),
                              Image.asset(
                                "asset/images/right_icon.png", // Centered Image
                                height: deviceHeight * 0.08,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                          kH20,
                           Text(
                            "Successful",
                            style: TextStyles.poppinsS20Black,
                          ),
                          kH10,
                           Text(
                            "Congratulations! Your password has\nbeen changed. Click continue to login",
                            style: TextStyles.poppinsR16Black,
                            textAlign: TextAlign.center,
                          ),
                          kH20,

                          CustomElevatedbutton(
                            width: deviceWidth * 0.87,
                            label: "Login",
                            callBack: (){
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );

                            },


                          ),
                          kH20,
                        ],
                      ),
                    ),
                  ),
                ],
              ))),
    );
  }
}

