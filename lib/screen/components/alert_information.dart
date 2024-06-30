import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';

class AlertInformation {
  static void showDialogBox({
    required BuildContext context,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext ctxt) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: subHeaderStyleBold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.of(ctxt).pop();
                },
              ),
            ],
          ),
          content: Text(
            message,
            style: textStyle,
          ),
        );
      },
    );
  }
}
