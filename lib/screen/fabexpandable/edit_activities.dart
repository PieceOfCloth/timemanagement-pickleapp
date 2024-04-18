import 'package:flutter/material.dart';

class EditActivities extends StatefulWidget {
  @override
  _EditActivitiesState createState() => _EditActivitiesState();
}

class _EditActivitiesState extends State<EditActivities> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Activities'),
      ),
      body: Column(
        children: [Text("ini EditActivities")],
      ),
    );
  }
}
