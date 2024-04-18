import 'package:flutter/material.dart';

import 'package:pickleapp/theme.dart';

class Report extends StatefulWidget {
  @override
  _ReportState createState() => _ReportState();
}

class _ReportState extends State<Report> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(
          top: 40,
          bottom: 20,
          left: 20,
          right: 20,
        ),
        color: Colors.cyan,
        child: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                "My Reports",
                style: screenTitleStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
