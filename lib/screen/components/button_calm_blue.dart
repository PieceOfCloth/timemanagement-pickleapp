import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';

class MyButtonCalmBlue extends StatelessWidget {
  final String label;
  final Function()? onTap;
  const MyButtonCalmBlue({super.key, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color.fromARGB(255, 166, 204, 255),
        ),
        child: Text(
          label,
          style: subHeaderStyle,
        ),
      ),
    );
  }
}
