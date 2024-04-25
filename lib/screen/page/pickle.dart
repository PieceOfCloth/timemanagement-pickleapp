import 'package:flutter/material.dart';

class Pickle extends StatefulWidget {
  const Pickle({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PickleState createState() => _PickleState();
}

class _PickleState extends State<Pickle> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [Text("ini pickle")],
      ),
    );
  }
}
