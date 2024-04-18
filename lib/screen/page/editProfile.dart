import 'package:flutter/material.dart';
import 'package:pickleapp/screen/class/profile.dart';
import 'package:pickleapp/screen/components/buttonWhite.dart';
import 'package:pickleapp/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:pickleapp/screen/components/inputTextOpt.dart';
import 'package:pickleapp/screen/components/inputImage.dart';
import 'package:pickleapp/screen/components/buttonCalmBlue.dart';

import 'package:pickleapp/screen/page/home.dart';
import 'package:pickleapp/screen/page/profile.dart';

class MyEditProfile extends StatefulWidget {
  String email;
  TextEditingController name;
  String urlPhoto;
  MyEditProfile({
    super.key,
    required this.name,
    required this.email,
    required this.urlPhoto,
  });

  @override
  State<MyEditProfile> createState() => _MyEditProfileState();
}

class _MyEditProfileState extends State<MyEditProfile> {
  TextEditingController _prefNameCont = TextEditingController();

  String _prefName = "";
  File? _urlPhoto;
  File? _imageProcess;
  DateTime nowTime = DateTime.now();

  final _formKey = GlobalKey<FormState>();

  Profiles? Ps;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _prefNameCont = widget.name;
  }

  void submit() async {
    final response = await http.post(
      Uri.parse("http://192.168.1.12:8012/picklePHP/editProfile.php"),
      body: {
        'name': _prefName,
        // change the path using lambda expression if user click submit but doesn't wanna change the profile pict
        'path': widget.urlPhoto,
        'updated': nowTime.toString(),
        'email': widget.email,
      },
    );
    if (response.statusCode == 200) {
      print(response.body);
      Map json = jsonDecode(response.body);
      if (json['result'] == 'success') {
        if (!mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Check your connection, please :)')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You successed edit your data')));
        }
      }
    } else {
      throw Exception('Failed to read API');
    }
  }

  // Show 2 choices of image picker
  void imagePicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            color: Colors.white,
            child: Wrap(
              children: [
                ListTile(
                  tileColor: Colors.white,
                  leading: Icon(Icons.photo_library_rounded),
                  title: Text('Gallery'),
                  onTap: () {
                    imageGallery();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  tileColor: Colors.white,
                  leading: Icon(Icons.camera_alt_rounded),
                  title: Text('Camera'),
                  onTap: () {
                    imageCamera();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Processing image
  // void photoProcessing() {
  //   Future<Directory?> extDir = getTemporaryDirectory();
  // extDir.then((value) {
  //  String _timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  //  final String filePath = value!.path + '/${_timestamp()}.jpg';
  //  _imageProcess = File(filePath);
  //  img.Image? temp = img.readJpg(_urlPhoto!.readAsBytesSync());
  //  img.Image temp2 = img.copyResize(temp!, width: 480, height: 640);
  //  img.drawString(temp2, img.arial_24, 4, 4, 'Kuliah Flutter',
  //    color: img.getColor(250, 100, 100));
  //  setState(() {
  //   _imageProcess?.writeAsBytesSync(img.writeJpg(temp2));
  //  });
  // });

  // }

  // Show gallery image picker
  imageGallery() async {
    final pick = ImagePicker();
    final img = await pick.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxHeight: 600,
      maxWidth: 600,
    );
    if (img == null) return;
    setState(() {
      _urlPhoto = File(img.path);
    });
  }

  // Show camera image picker
  imageCamera() async {
    final pick = ImagePicker();
    final img = await pick.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      preferredCameraDevice: CameraDevice.front,
    );
    if (img == null) return;
    setState(() {
      _urlPhoto = File(img.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 166, 204, 255),
        title: Text(
          'Edit Profile',
          style: screenTitleStyle,
        ),
      ),
      body: Form(
        key: _formKey,
        child: Container(
          margin: const EdgeInsets.only(
            left: 20,
            top: 20,
            right: 20,
            bottom: 20,
          ),
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.width * 0.4,
                margin: const EdgeInsets.only(
                  bottom: 50,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color.fromARGB(255, 166, 204, 255),
                    width: 2,
                  ),
                  image: DecorationImage(
                    image: _urlPhoto != null
                        ? Image.file(_urlPhoto!).image
                        : AssetImage('assets/Default_Photo_Profile.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              MyInputImageMust(
                title: "Profile Photo",
                placeholder: "profile photo",
                onTapFunct: () {
                  imagePicker(context);
                },
              ),
              Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Preferred name",
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
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.sentences,
                              autofocus: false,
                              style: textStyle,
                              decoration: InputDecoration(
                                hintText: "Change your preferred name",
                                hintStyle: textStyleGrey,
                              ),
                              controller: _prefNameCont,
                              onChanged: (v) {
                                setState(() {
                                  _prefName = v;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 50,
              ),
              MyButtonCalmBlue(
                label: "Save Profile",
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Profile Changes',
                          style: subHeaderStyle,
                        ),
                        content: Text(
                          'Are you sure want to do it?',
                          style: textStyleGrey,
                        ),
                        actions: <Widget>[
                          MyButtonWhite(
                            label: "Change it",
                            onTap: () {
                              submit(); // Do something when "Yes" is pressed
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          MyButtonCalmBlue(
                            label: "Cancel",
                            onTap: () {
                              // Do something when "Cancel" is pressed
                              Navigator.of(context).pop(); // Close the dialog
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
