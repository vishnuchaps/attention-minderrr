import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? suffixIcon;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: GoogleFonts.poppins(
          fontSize: 16.0, // Font size
          fontWeight: FontWeight.w400, // Font weight
          height: 24.0 / 16.0, // Line height ratio
          color: Colors.black, // Label text color
        ),
        filled: true,
        fillColor: const Color(0xFFF6F7FA), // Background color
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)), // Rounded corners
          borderSide: BorderSide.none, // No border
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15), // Adjust content padding
        suffixIcon: suffixIcon, // Optional suffix icon
      ),
      style: GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: FontWeight.w400,
        height: 24.0 / 16.0,
      ),
      validator: validator,
    );
  }
}
