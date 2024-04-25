import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';

class MyInputImageMust extends StatelessWidget {
  final String title;
  final String placeholder;
  final Function()? onTapFunct;
  final Widget? widget;

  MyInputImageMust({
    super.key,
    required this.title,
    required this.placeholder,
    required this.onTapFunct,
    this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: subHeaderStyleGrey,
          ),
          const SizedBox(
            height: 5,
          ),
          Container(
            padding: const EdgeInsets.only(
              left: 10,
              right: 10,
            ),
            alignment: Alignment.center,
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(10),
              color: Color.fromARGB(255, 166, 204, 255),
            ),
            child: GestureDetector(
              onTap: onTapFunct,
              child: Text(
                "Click here to change your ${placeholder}",
                style: textStyle,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
