import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';

class MyInputDropdown extends StatelessWidget {
  final String title;
  final String placeholder;
  final List? list;
  final TextEditingController? controller;
  final Widget? widget;

  const MyInputDropdown({
    super.key,
    required this.title,
    required this.placeholder,
    this.list,
    this.controller,
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
            alignment: Alignment.centerLeft,
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                // Expanded(
                  // child: 
                  // DropdownButton(
                  //   value: placeholder,
                  //   items: list,
                  // ),
                  // TextFormField(
                  //   readOnly: widget == null ? false : true,
                  //   keyboardType: TextInputType.text,
                  //   textCapitalization: TextCapitalization.sentences,
                  //   autofocus: false,
                  //   controller: controller,
                  //   style: textStyle,
                  //   decoration: InputDecoration(
                  //     hintText: placeholder,
                  //     hintStyle: textStyleGrey,
                  //   ),
                  // ),
                // ),
                widget == null
                    ? Container()
                    : Container(
                        child: widget,
                      ),
              ],
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
