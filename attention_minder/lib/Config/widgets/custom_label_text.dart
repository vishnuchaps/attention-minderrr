import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/spaces.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:flutter/material.dart';

class CustomLabelTextFiled extends StatelessWidget {
  const CustomLabelTextFiled({
    super.key,
    required this.hint,
    required this.label,
    required this.controller,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyles.poppinsM14Black,
        ),
        kH10,
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyles.poppinsM10Black
                .copyWith(color: Colors.grey.shade600),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.redColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.borderGreyColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.borderGreyColor),
            ),
            filled: true,
            fillColor: AppColor.lightGreyColor,
          ),
          validator: validator,
        ),
      ],
    );
  }
}