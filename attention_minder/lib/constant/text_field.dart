import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class TextStyles {
  static TextStyle _poppins({
    required double size,
    required FontWeight weight,
    required Color color,
    TextOverflow? overflow,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  // Font Weights
  static const _regular = FontWeight.w400;
  static const _medium = FontWeight.w500;
  static const _semiBold = FontWeight.w600;
  static const _bold = FontWeight.w700;

  // Sizes from 10 to 22
  static final poppinsR10White =
      _poppins(size: 10, weight: _regular, color: AppColor.whiteColor);
  static final poppinsR10Black =
      _poppins(size: 10, weight: _regular, color: AppColor.designBlackColor);
  static final poppinsM10White =
      _poppins(size: 10, weight: _medium, color: AppColor.whiteColor);
  static final poppinsM10Black =
      _poppins(size: 10, weight: _medium, color: AppColor.designBlackColor);
  static final poppinsS10White =
      _poppins(size: 10, weight: _semiBold, color: AppColor.whiteColor);
  static final poppinsS10Black =
      _poppins(size: 10, weight: _semiBold, color: AppColor.designBlackColor);
  static final poppinsB10White =
      _poppins(size: 10, weight: _bold, color: AppColor.whiteColor);
  static final poppinsB10Black =
      _poppins(size: 10, weight: _bold, color: AppColor.designBlackColor);

  static final poppinsR12White =
      _poppins(size: 12, weight: _regular, color: AppColor.whiteColor);
  static final poppinsR12Black =
      _poppins(size: 12, weight: _regular, color: AppColor.designBlackColor);
  static final poppinsM12White =
      _poppins(size: 12, weight: _medium, color: AppColor.whiteColor);
  static final poppinsM12Black =
      _poppins(size: 12, weight: _medium, color: AppColor.designBlackColor);
  static final poppinsS12White =
      _poppins(size: 12, weight: _semiBold, color: AppColor.whiteColor);
  static final poppinsS12Black =
      _poppins(size: 12, weight: _semiBold, color: AppColor.designBlackColor);
  static final poppinsB12White =
      _poppins(size: 12, weight: _bold, color: AppColor.whiteColor);
  static final poppinsB12Black =
      _poppins(size: 12, weight: _bold, color: AppColor.designBlackColor);

  static final poppinsR14White =
      _poppins(size: 14, weight: _regular, color: AppColor.whiteColor);
  static final poppinsR14Black =
      _poppins(size: 14, weight: _regular, color: AppColor.designBlackColor);
  static final poppinsM14White =
      _poppins(size: 14, weight: _medium, color: AppColor.whiteColor);
  static final poppinsM14Black =
      _poppins(size: 14, weight: _medium, color: AppColor.designBlackColor);
  static final poppinsS14White =
      _poppins(size: 14, weight: _semiBold, color: AppColor.whiteColor);
  static final poppinsS14Black =
      _poppins(size: 14, weight: _semiBold, color: AppColor.designBlackColor);
  static final poppinsB14White =
      _poppins(size: 14, weight: _bold, color: AppColor.whiteColor);
  static final poppinsB14Black =
      _poppins(size: 14, weight: _bold, color: AppColor.designBlackColor);

  static final poppinsR16White =
      _poppins(size: 16, weight: _regular, color: AppColor.whiteColor);
  static final poppinsR16Black =
      _poppins(size: 16, weight: _regular, color: AppColor.designBlackColor);
  static final poppinsM16White =
      _poppins(size: 16, weight: _medium, color: AppColor.whiteColor);
  static final poppinsM16Black =
      _poppins(size: 16, weight: _medium, color: AppColor.designBlackColor);
  static final poppinsS16White =
      _poppins(size: 16, weight: _semiBold, color: AppColor.whiteColor);
  static final poppinsS16Black =
      _poppins(size: 16, weight: _semiBold, color: AppColor.designBlackColor);
  static final poppinsB16White =
      _poppins(size: 16, weight: _bold, color: AppColor.whiteColor);
  static final poppinsB16Black =
      _poppins(size: 16, weight: _bold, color: AppColor.designBlackColor);

  static final poppinsR18White =
      _poppins(size: 18, weight: _regular, color: AppColor.whiteColor);
  static final poppinsR18Black =
      _poppins(size: 18, weight: _regular, color: AppColor.designBlackColor);
  static final poppinsM18White =
      _poppins(size: 18, weight: _medium, color: AppColor.whiteColor);
  static final poppinsM18Black =
      _poppins(size: 18, weight: _medium, color: AppColor.designBlackColor);
  static final poppinsS18White =
      _poppins(size: 18, weight: _semiBold, color: AppColor.whiteColor);
  static final poppinsS18Black =
      _poppins(size: 18, weight: _semiBold, color: AppColor.designBlackColor);
  static final poppinsB18White =
      _poppins(size: 18, weight: _bold, color: AppColor.whiteColor);
  static final poppinsB18Black =
      _poppins(size: 18, weight: _bold, color: AppColor.designBlackColor);

  static final poppinsR20White =
      _poppins(size: 20, weight: _regular, color: AppColor.whiteColor);
  static final poppinsR20Black =
      _poppins(size: 20, weight: _regular, color: AppColor.designBlackColor);
  static final poppinsM20White =
      _poppins(size: 20, weight: _medium, color: AppColor.whiteColor);
  static final poppinsM20Black =
      _poppins(size: 20, weight: _medium, color: AppColor.designBlackColor);
  static final poppinsS20White =
      _poppins(size: 20, weight: _semiBold, color: AppColor.whiteColor);
  static final poppinsS20Black =
      _poppins(size: 20, weight: _semiBold, color: AppColor.designBlackColor);
  static final poppinsB20White =
      _poppins(size: 20, weight: _bold, color: AppColor.whiteColor);
  static final poppinsB20Black =
      _poppins(size: 20, weight: _bold, color: AppColor.designBlackColor);

  static final poppinsR22White =
      _poppins(size: 22, weight: _regular, color: AppColor.whiteColor);
  static final poppinsR22Black =
      _poppins(size: 22, weight: _regular, color: AppColor.designBlackColor);
  static final poppinsM22White =
      _poppins(size: 22, weight: _medium, color: AppColor.whiteColor);
  static final poppinsM22Black =
      _poppins(size: 22, weight: _medium, color: AppColor.designBlackColor);
  static final poppinsS22White =
      _poppins(size: 22, weight: _semiBold, color: AppColor.whiteColor);
  static final poppinsS22Black =
      _poppins(size: 22, weight: _semiBold, color: AppColor.designBlackColor);
  static final poppinsB22White =
      _poppins(size: 22, weight: _bold, color: AppColor.whiteColor);
  static final poppinsB22Black =
      _poppins(size: 22, weight: _bold, color: AppColor.designBlackColor);
}
