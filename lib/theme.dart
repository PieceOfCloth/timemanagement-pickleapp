import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:get';

const Color darkGreyClr = Color(0xFF121212);
const Color primary = Color.fromRGBO(173, 255, 47, 1);

class Themes {
  // static final light = ThemeData(
  //   // ignore: deprecated_member_use
  //   backgroundColor: Colors.white,
  //   primaryColor: const Color.fromRGBO(173, 255, 47, 1),
  //   brightness: Brightness.light,
  // );

  // static final dark = ThemeData(
  //   // ignore: deprecated_member_use
  //   backgroundColor: const Color.fromRGBO(128, 128, 128, 1),
  //   primaryColor: const Color.fromRGBO(128, 128, 128, 1),
  //   brightness: Brightness.dark,
  // );
}

TextStyle get screenTitleStyle {
  return const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );
}

TextStyle get screenTitleStyleGrey {
  return const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
  );
}

TextStyle get screenTitleStyleWhite {
  return const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

TextStyle get headerStyle {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 20,
      color: Colors.black,
    ),
  );
}

TextStyle get headerStyleGrey {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 20,
      color: Colors.grey,
    ),
  );
}

TextStyle get headerStyleWhite {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 20,
      color: Colors.white,
    ),
  );
}

TextStyle get headerStyleBold {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  );
}

TextStyle get headerStyleBoldGrey {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
  );
}

TextStyle get headerStyleBoldWhite {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );
}

TextStyle get subHeaderStyle {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 18,
      color: Colors.black,
    ),
  );
}

TextStyle get subHeaderStyleGrey {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 18,
      color: Colors.grey,
    ),
  );
}

TextStyle get subHeaderStyleWhite {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 18,
      color: Colors.white,
    ),
  );
}

TextStyle get subHeaderStyleBold {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  );
}

TextStyle get subHeaderStyleBoldGrey {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
  );
}

TextStyle get subHeaderStyleBoldWhite {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );
}

TextStyle get textStyle {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 14,
      color: Colors.black,
    ),
  );
}

TextStyle get textStyleGrey {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 14,
      color: Colors.grey,
    ),
  );
}

TextStyle get textStyleWhite {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 14,
      color: Colors.white,
    ),
  );
}

TextStyle get textStyleBold {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
  );
}

TextStyle get textStyleBoldGrey {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    ),
  );
}

TextStyle get textStyleBoldWhite {
  return GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  );
}
