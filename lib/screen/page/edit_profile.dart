// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pickleapp/auth.dart';
import 'package:pickleapp/screen/components/alert_information.dart';
import 'package:pickleapp/theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class MyEditProfile extends StatefulWidget {
  final String name;
  final String urlPhoto;

  const MyEditProfile({super.key, required this.name, required this.urlPhoto});

  @override
  State<MyEditProfile> createState() => _MyEditProfileState();
}

class _MyEditProfileState extends State<MyEditProfile> {
  final TextEditingController _prefNameCont = TextEditingController();

  String _prefName = "";
  File? _urlPhoto;
  DateTime nowTime = DateTime.now();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // _prefNameCont = widget.name;
  }

  // void submit() async {
  //   final response = await http.post(
  //     Uri.parse("http://192.168.1.12:8012/picklePHP/editProfile.php"),
  //     body: {
  //       'name': _prefName,
  //       // change the path using lambda expression if user click submit but doesn't wanna change the profile pict
  //       'path': widget.urlPhoto,
  //       'updated': nowTime.toString(),
  //       'email': widget.email,
  //     },
  //   );
  //   if (response.statusCode == 200) {
  //     print(response.body);
  //     Map json = jsonDecode(response.body);
  //     if (json['result'] == 'success') {
  //       if (!mounted) {
  //         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //             content: Text('Check your connection, please :)')));
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //             const SnackBar(content: Text('You successed edit your data')));
  //       }
  //     }
  //   } else {
  //     throw Exception('Failed to read API');
  //   }
  // }

  // Show 2 choices of image picker
  void imagePicker(context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              color: Colors.white,
            ),
            child: Wrap(
              children: [
                ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Gallery'),
                  onTap: () {
                    imageGallery();
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  tileColor: Colors.white,
                  leading: const Icon(Icons.camera_alt_rounded),
                  title: const Text('Camera'),
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
    if (img == null) {
      print("No picture selected");
    } else {
      final directory = await getApplicationDocumentsDirectory();

      // Create a new file path with the userID as the file name
      final newPath =
          path.join(directory.path, '$userID${path.extension(img.path)}');
      final newImage = await File(img.path).copy(newPath);

      setState(() {
        _urlPhoto = newImage;
        print("Gallery: $_urlPhoto");
      });
    }
  }

  // Show camera image picker
  imageCamera() async {
    final pick = ImagePicker();
    final img = await pick.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      preferredCameraDevice: CameraDevice.front,
    );
    if (img == null) {
      print("Test");
    } else {
      final directory = await getApplicationDocumentsDirectory();

      // Create a new file path with the userID as the file name
      final newPath =
          path.join(directory.path, '$userID${path.extension(img.path)}');
      final newImage = await File(img.path).copy(newPath);

      setState(() {
        _urlPhoto = newImage;
        print("Gallery: $_urlPhoto");
      });
    }
  }

  Future<void> updateUserProfile(
      File? image, String userId, String? name) async {
    try {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );
      if ((name == null || name == "") && image != null) {
        String file = '$userId${path.extension(image.path)}';
        String filePath = 'user_profile/$file';
        File fileImage = image;

        await FirebaseStorage.instance
            .ref('user_profile')
            .child(file)
            .putFile(fileImage);

        await _firestore.collection('users').doc(userId).update({
          'path': filePath,
          'update_at': Timestamp.fromDate(DateTime.now()),
        });
      } else if ((name != "" || name != null) && image == null) {
        await _firestore.collection('users').doc(userId).update({
          'name': name,
          'update_at': Timestamp.fromDate(DateTime.now()),
        });
      } else {
        String file = '$userId${path.extension(image!.path)}';
        String filePath = 'user_profile/$file';
        File fileImage = image;

        await FirebaseStorage.instance
            .ref('user_profile')
            .child(file)
            .putFile(fileImage);

        await _firestore.collection('users').doc(userId).update({
          'path': filePath,
          'name': name,
          'update_at': Timestamp.fromDate(DateTime.now()),
        });
      }

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      AlertInformation.showDialogBox(
        context: context,
        title: "Profile Updated",
        message: "Your Profile has been updated successfully, thank you.",
      );
    } catch (e) {
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      AlertInformation.showDialogBox(
        context: context,
        title: "Error",
        message: "$e",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: headerStyleBold,
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _urlPhoto == null
                    ? Container(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: MediaQuery.of(context).size.width * 0.4,
                        margin: const EdgeInsets.only(
                          top: 20,
                          bottom: 5,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromARGB(255, 3, 0, 66),
                            width: 2,
                          ),
                          image: DecorationImage(
                            image: NetworkImage(widget.urlPhoto),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: MediaQuery.of(context).size.width * 0.4,
                            margin: const EdgeInsets.only(
                              top: 20,
                              bottom: 5,
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color.fromARGB(255, 3, 0, 66),
                                width: 2,
                              ),
                              image: DecorationImage(
                                image: FileImage(_urlPhoto!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            top: 10,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _urlPhoto = null;
                                });
                              },
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Color.fromARGB(255, 3, 0, 66),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                Text(
                  widget.name,
                  style: subHeaderStyleBold,
                ),
                const SizedBox(height: 30),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Photo Profile",
                          style: textStyle,
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Container(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                          ),
                          alignment: Alignment.center,
                          height: 50,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            color: const Color.fromARGB(255, 3, 0, 66),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              imagePicker(context);
                            },
                            child: Text(
                              "Click here to change your photo profile",
                              style: textStyleBoldWhite,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Preferred name",
                          style: textStyle,
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
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.text,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  autofocus: false,
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
                    const SizedBox(
                      height: 50,
                    ),
                    GestureDetector(
                      onTap: () {
                        if (_prefName.isNotEmpty || _urlPhoto != null) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text(
                                  'Profile Changes',
                                  style: subHeaderStyleBold,
                                ),
                                content: Text(
                                  'Are you sure want to change it?',
                                  style: textStyle,
                                ),
                                actions: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      updateUserProfile(
                                          _urlPhoto, userID, _prefName);
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          width: 1,
                                          color: const Color.fromARGB(
                                              255, 3, 0, 66),
                                        ),
                                      ),
                                      child: // Space between icon and text
                                          Text(
                                        'Change it',
                                        style: textStyleBold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      width: double.infinity,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        color:
                                            const Color.fromARGB(255, 3, 0, 66),
                                      ),
                                      child: // Space between icon and text
                                          Text(
                                        'Cancel',
                                        style: textStyleBoldWhite,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Information',
                                      style: subHeaderStyleBold,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  ],
                                ),
                                content: Text(
                                  'There are no change in your profile, please make any change if you want to save it.',
                                  style: textStyle,
                                ),
                              );
                            },
                          );
                        }
                      },
                      child: Container(
                        alignment: Alignment.center,
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: const Color.fromARGB(255, 3, 0, 66),
                        ),
                        child: Text(
                          "Save Profile",
                          style: textStyleBoldWhite,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
