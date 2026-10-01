import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

enum FW { regular, medium, semiBold, bold, extraBold }

FontWeight getFW(FW? fw) {
  switch (fw) {
    case FW.regular:
      return FontWeight.w400;
    case FW.medium:
      return FontWeight.w500;
    case FW.semiBold:
      return FontWeight.w600;
    case FW.bold:
      return FontWeight.w700;
    case FW.extraBold:
      return FontWeight.w900;
    default:
      return FontWeight.w400;
  }
}

const String poppinsFonts = "Poppins";

// Helper Base Function (Clean DRY Code with Poppins Typography)
TextStyle _baseStyle({
  required double fontSize,
  FW? fw,
  Color? fontColor,
  String? fontFamily,
  double? letterSpacing,
  TextDecoration? decoration,
  double? height,
}) {
  return GoogleFonts.poppins(
    fontSize: fontSize,
    fontWeight: getFW(fw),
    color: fontColor ?? AppColors.textPrimary,
    letterSpacing: letterSpacing,
    decoration: decoration,
    height: height,
  );
}

// 🔤 Custom Typography Functions
TextStyle size7({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 7, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size8({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 8, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size9({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 9, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size10({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 10, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size11({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 11, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size12({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 12, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size13({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 13, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size14({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 14, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size15({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 15, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size16({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 16, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size17({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 17, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size18({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 18, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size20({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 20, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size21({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 21, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size22({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 22, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size24({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) =>
    _baseStyle(fontSize: 24, fw: fw, fontColor: fontColor, fontFamily: fontFamily, letterSpacing: letterSpacing, decoration: decoration, height: height);

TextStyle size28({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) => _baseStyle(
      fontSize: 28,
      fw: fw ?? FW.bold,
      fontColor: fontColor,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      decoration: decoration,
      height: height,
    );

TextStyle size30({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) => _baseStyle(
      fontSize: 30,
      fw: fw ?? FW.bold,
      fontColor: fontColor,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      decoration: decoration,
      height: height,
    );

TextStyle size32({FW? fw, Color? fontColor, String? fontFamily, double? letterSpacing, TextDecoration? decoration, double? height}) => _baseStyle(
      fontSize: 32,
      fw: fw ?? FW.bold,
      fontColor: fontColor,
      fontFamily: fontFamily,
      letterSpacing: letterSpacing,
      decoration: decoration,
      height: height,
    );
