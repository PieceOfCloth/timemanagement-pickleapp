import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';

// ignore: must_be_immutable
class InputText extends StatelessWidget {
  final String title;
  final String placeholder;
  TextEditingController? cont;

  InputText({
    super.key,
    required this.title,
    required this.placeholder,
    this.cont,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textStyle,
        ),
        const SizedBox(
          height: 5,
        ),
        Container(
          padding: const EdgeInsets.only(
            left: 10,
            right: 10,
          ),
          alignment: Alignment.centerLeft,
          height: 50,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Colors.grey,
              width: 1.0,
            ),
          ),
          child: cont == null
              ? TextFormField(
                  autofocus: false,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: textStyleGrey,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Opps, You need to fill this';
                    } else {
                      return null;
                    }
                  },
                )
              : TextFormField(
                  autofocus: false,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: textStyleGrey,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'Opps, You need to fill this';
                    } else {
                      return null;
                    }
                  },
                  controller: cont,
                ),
        ),
      ],
    );
  }
}
