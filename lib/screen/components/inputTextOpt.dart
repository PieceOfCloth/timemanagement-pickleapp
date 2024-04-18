import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';

class MyInputTextOpt extends StatefulWidget {
  final String title;
  final String placeholder;
  TextEditingController? controller;
  String value;
  final Widget? widget;

  MyInputTextOpt({
    super.key,
    required this.title,
    required this.placeholder,
    required this.controller,
    required this.value,
    this.widget,
  });

  @override
  State<MyInputTextOpt> createState() => _MyInputTextOptState();
}

class _MyInputTextOptState extends State<MyInputTextOpt> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
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
                Expanded(
                  child: TextFormField(
                    readOnly: widget.widget == null ? false : true,
                    keyboardType: TextInputType.text,
                    textCapitalization: TextCapitalization.sentences,
                    autofocus: false,
                    style: textStyle,
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: textStyleGrey,
                    ),
                    controller: widget.controller,
                    onChanged: (v) {
                      setState(() {
                        widget.value = v;
                      });
                    },
                  ),
                ),
                widget.widget == null
                    ? Container()
                    : Container(
                        child: widget.widget,
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
