import 'package:attention_minder/constant/colors.dart';
import 'package:attention_minder/constant/spaces.dart';
import 'package:attention_minder/constant/text_field.dart';
import 'package:flutter/material.dart';

class CustomLabelPassTextFiled extends StatefulWidget {
  const CustomLabelPassTextFiled({
    super.key,
    required this.hint,
    required this.label,
    required this.controller,
    this.validator,
    this.showObscureIcon = true,
  });

  final String label;
  final String hint;
  final bool showObscureIcon;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  _CustomLabelPassTextFiledState createState() =>
      _CustomLabelPassTextFiledState();
}

class _CustomLabelPassTextFiledState extends State<CustomLabelPassTextFiled> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyles.poppinsM14Black,
        ),
        kH10,
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          obscureText: widget.showObscureIcon ? _obscureText : false,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyles.poppinsM14Black.copyWith(
              color: Colors.grey.shade600,
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.borderGreyColor),
            ),
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
            // suffixIcon: widget.showObscureIcon
            //     ? GestureDetector(
            //   onTap: () {
            //     setState(() {
            //       _obscureText = !_obscureText;
            //     });
            //   },
            //   child: Padding(
            //     padding: const EdgeInsets.all(12.0),
            //     child: Image.asset(
            //       "assets/images/obscure_icon.png",
            //       width: 20,
            //       height: 20,
            //       color: Colors.grey.shade700, // Adjust color if needed
            //     ),
            //   ),
            // )
            //     : null, // Hide suffix icon if showObscureIcon is false
          ),
        ),
      ],
    );
  }
}
