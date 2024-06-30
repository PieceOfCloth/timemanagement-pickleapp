import 'package:flutter/material.dart';

class JarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    // Menggambar leher toples
    path.moveTo(size.width * 0.2, 0);
    path.lineTo(size.width * 0.8, 0);
    path.lineTo(size.width * 0.8, size.height * 0.1);

    // Menggambar kurva tubuh toples
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.15,
        size.width * 0.9, size.height * 0.3);
    path.lineTo(size.width * 0.9, size.height * 0.9);
    path.quadraticBezierTo(
        size.width * 0.85, size.height, size.width * 0.5, size.height);
    path.quadraticBezierTo(
        size.width * 0.15, size.height, size.width * 0.1, size.height * 0.9);
    path.lineTo(size.width * 0.1, size.height * 0.3);
    path.quadraticBezierTo(size.width * 0.15, size.height * 0.15,
        size.width * 0.2, size.height * 0.1);

    path.lineTo(size.width * 0.2, 0);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
