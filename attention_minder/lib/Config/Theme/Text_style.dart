import 'package:flutter/cupertino.dart';

BoxDecoration gradientDecoration = const BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDE6B5),
      Color(0xFFC3DAEF), // #C3DAEF
// #FDE6B5
    ],
    stops: [-0.0557, 1.2837], // Converted from percentage values
  ),
);
