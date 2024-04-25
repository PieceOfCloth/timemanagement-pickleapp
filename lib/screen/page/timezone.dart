import 'package:flutter/material.dart';
import 'package:pickleapp/theme.dart';

class MyTimeZones extends StatelessWidget {
  const MyTimeZones({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Time Zone",
          style: screenTitleStyle,
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(20),
        color: Colors.amber,
        child: Column(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      color: Colors.black,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          // readOnly: widget == null ? false : true,
                          keyboardType: TextInputType.emailAddress,
                          // textCapitalization: TextCapitalization.sentences,
                          autofocus: false,
                          // controller: _email,
                          style: textStyle,
                          decoration: InputDecoration(
                            hintText: "Enter your email here",
                            hintStyle: textStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}
