import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF800000);
const Color kPrimaryLight = Color(0xFFA52A2A);
const Color kPrimaryDark = Color(0xFF5D0000);
const Color kSecondaryColor = Color(0xFF1A1A1A);
const Color kAccentColor = Color(0xFFD4AF37);
const Color kLinkColor = Color(0xFF0056B3);
const Color kBackgroundColor = Color(0xFFF4F7F6);
const Color kSurfaceColor = Color(0xFFFFFFFF);
const Color kSuccessColor = Color(0xFF28A745);
const Color kInfoColor = Color(0xFF17A2B8);
const Color kWarningColor = Color(0xFFFFC107);
const Color kErrorColor = Color(0xFFDC3545);
const Color kTextPrimary = Color(0xFF212529);
const Color kTextSecondary = Color(0xFF6C757D);
const Color kGrey100 = Color(0xFFF8F9FA);
const Color kGrey200 = Color(0xFFE9ECEF);
const Color kGrey300 = Color(0xFFDEE2E6);
const Color kGrey400 = Color(0xFFCED4DA);
const Color kGrey500 = Color(0xFFADB5BD);
const Color kGrey600 = Color(0xFF6C757D);
const Color kGrey700 = Color(0xFF495057);
const Color kGrey800 = Color(0xFF343A40);
const Color kGrey900 = Color(0xFF212529);
const Color kGreyLight = kGrey200;
const Color kGreyMedium = kGrey500;
const Color kGreyDark = kGrey700;

const Color maroon = kPrimaryColor;
const Color silver = kGreyMedium;

class AppColors {
  static const Color primary = kPrimaryColor;
  static const Color primaryLight = kPrimaryLight;
  static const Color primaryDark = kPrimaryDark;
  static const Color secondary = kSecondaryColor;
  static const Color accent = kAccentColor;
  static const Color background = kBackgroundColor;
  static const Color surface = kSurfaceColor;
  static const Color success = kSuccessColor;
  static const Color info = kInfoColor;
  static const Color warning = kWarningColor;
  static const Color error = kErrorColor;
  static const Color textPrimary = kTextPrimary;
  static const Color textSecondary = kTextSecondary;
  static const Color grey100 = kGrey100;
  static const Color grey200 = kGrey200;
  static const Color grey300 = kGrey300;
  static const Color grey400 = kGrey400;
  static const Color grey500 = kGrey500;
  static const Color grey600 = kGrey600;
  static const Color grey700 = kGrey700;
  static const Color grey800 = kGrey800;
  static const Color grey900 = kGrey900;

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [kPrimaryColor, kPrimaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
