import 'package:flutter/material.dart';
import 'package:pickleapp/screen/class/activity_detail.dart';

class ActivityEditDetails extends StatefulWidget {
  final DetailActivities activity;
  const ActivityEditDetails({super.key, required this.activity});

  @override
  // ignore: library_private_types_in_public_api
  _ActivityEditDetailsState createState() => _ActivityEditDetailsState();
}

class _ActivityEditDetailsState extends State<ActivityEditDetails> {
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
        children: [Text("ini ActivityEditDetails")],
      ),
    );
  }
}
