import 'package:flutter/material.dart';

class DeleteActivities extends StatefulWidget {
  @override
  _DeleteActivitesState createState() => _DeleteActivitesState();
}

class _DeleteActivitesState extends State<DeleteActivities> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Activities'),
      ),
      body: Column(
        children: [Text("ini DeleteActivites")],
      ),
    );
  }
}
