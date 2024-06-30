import 'package:flutter/material.dart';

class CheckBoxDropdown extends StatefulWidget {
  final List<String> items;
  const CheckBoxDropdown({super.key, required this.items});

  @override
  State<CheckBoxDropdown> createState() => _CheckBoxDropdown();
}

class _CheckBoxDropdown extends State<CheckBoxDropdown> {
  List<bool> checkList = [];

  @override
  void initState() {
    super.initState();

    checkList = List<bool>.generate(
      widget.items.length,
      (index) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      items: List.generate(
        widget.items.length,
        (index) => DropdownMenuItem(
          value: widget.items[index],
          child: CheckboxListTile(
            value: checkList[index],
            onChanged: (value) {
              setState(
                () {
                  checkList[index] = value!;
                },
              );
            },
            title: Text(
              widget.items[index],
              style: checkList[index]
                  ? const TextStyle(
                      decoration: TextDecoration
                          .lineThrough) // Menyisipkan garis melintang jika item terpilih
                  : null,
            ),
          ),
        ),
      ),
      onChanged: (value) {},
    );
  }
}
