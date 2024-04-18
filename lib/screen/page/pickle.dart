import 'package:flutter/material.dart';

class Pickle extends StatefulWidget {
  @override
  _PickleState createState() => _PickleState();
}

class _PickleState extends State<Pickle> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [Text("ini pickle")],
      ),
    );
  }
}
