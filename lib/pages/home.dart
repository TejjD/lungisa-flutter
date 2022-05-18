import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:location/location.dart' as location_package;
import 'package:shared_preferences/shared_preferences.dart';

import '../common/card_picture.dart';
import '../common/take_photo.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late CameraDescription _cameraDescription;
  final List<String> _images = [];
  String? imagePath;
  String? issues;
  String? comments;
  String? severity;
  String? date;
  http.MultipartFile? multipartFile;
  Map<String, String> dataMap = {};
  Position? _currentPosition;
  final Geolocator geolocator = Geolocator()..forceAndroidLocationManager;
  String VM_VAR = dotenv.get('VM_URL');
  bool showLoading = false;
  bool showMessage = false;
  bool noImage = false;
  var issueList = {
    'Pothole',
    'Sinkhole',
    'Burst Pipe',
    'Traffic robot',
    'Water outage',
    'Street lights',
    'Other'
  };
  late final SharedPreferences prefs;

  static const spinkit = SpinKitCircle(
    color: Colors.blue,
    size: 50.0,
  );

  static Text responseMessage = const Text("");
  static Text noImageAdded =
      const Text("Please add an image!", style: TextStyle(color: Colors.red));
  static const uploadSuccessMessage = Text(
      "Your issue has been acknowledged! Thank you for making your community better!",
      style: TextStyle(color: Colors.green));
  static const uploadErrorMessage = Text(
      "An unexpected issue has occurred, please attempt to submit at a later stage",
      style: TextStyle(color: Colors.red));

  Future<void> submitData() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('kk:mm:ss \n EEE d MMM').format(now);

    await _getCurrentLocation();

    multipartFile = await http.MultipartFile.fromPath('image', _images.first);

    dataMap["issue"] = issues!;
    dataMap["severity"] = severity!;
    dataMap["datetime"] = formattedDate;
    dataMap["comment"] = comments!;

    setState(() {
      noImage = false;
      showMessage = false;
      showLoading = true;
    });
  }

  showSafetyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: const Text("Safety warning"),
          content: const Text(
              "Its important to always be safe! Please ensure you are not driving and are in a safe area when reporting an issue."),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: const Text("I understand!"),
              onPressed: () {
                // Save an double value to 'decimal' key.
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  showErrorDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            TextButton(
              child: const Text("I understand!"),
              onPressed: () {
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  uploadFile() async {
    var postUri = Uri.parse("http://$VM_VAR:8080/data/api/v1/addFlutterData");
    var request = http.MultipartRequest("POST", postUri);
    request.fields['flutterData'] = json.encode(dataMap);
    request.files.add(multipartFile!);

    request.send().then((response) {
      setState(() {
        showLoading = false;
        showMessage = true;
      });
      if (response.statusCode == 200) {
        setState(() {
          _formKey.currentState?.reset();
          _images.clear();
        });
        responseMessage = uploadSuccessMessage;
      } else {
        responseMessage = uploadErrorMessage;
      }
    });
  }

  _getCurrentLocation() {
    geolocator
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.best)
        .then((Position position) {
      setState(() {
        _currentPosition = position;
        dataMap["location"] = "${position.latitude},${position.longitude}";
        uploadFile();
      });
    }).catchError((e) {
      print(e);
    });
  }

  @override
  void initState() {
    availableCameras().then((cameras) {
      final camera = cameras
          .where((camera) => camera.lensDirection == CameraLensDirection.back)
          .toList()
          .first;

      setState(() {
        _cameraDescription = camera;
      });
    });

    checkUserConnection();
    checkLocationActive();
    checkSafetyCheck();
  }

  Future checkSafetyCheck() async {
    prefs = await SharedPreferences.getInstance();

    final bool? safetyCheckAck = prefs.getBool('safetyCheckAck');

    if (safetyCheckAck == null) {
      await prefs.setBool('safetyCheckAck', true);
      showSafetyDialog();
    }
  }

  Future checkLocationActive() async {
    var location = location_package.Location();
    bool enabled = await location.serviceEnabled();

    if (!enabled) {
      showErrorDialog("Location",
          "This app requires your location to operate. Please enable and relaunch the application");
    }
  }

  bool activeConnection = false;

  Future checkUserConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        setState(() {
          activeConnection = true;
        });
      }
    } on SocketException catch (_) {
      setState(() {
        activeConnection = false;
        showErrorDialog("Internet Connection",
            "This app requires an internet connection to operate. Please enable and relaunch the application");
      });
    }
  }

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
      child: FormBuilder(
        key: _formKey,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 130.0, horizontal: 50.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            if (showLoading) spinkit,
            if (showMessage) responseMessage,
            FormBuilderDropdown(
              name: 'issues',
              onChanged: (val) {
                issues = val as String?;
              },
              decoration: const InputDecoration(
                labelText: 'Issue',
              ),
              // initialValue: 'Male',
              allowClear: true,
              hint: const Text('Select issue'),
              validator: FormBuilderValidators.required(),
              items: issueList
                  .map((issue) => DropdownMenuItem(
                        value: issue,
                        child: Text(issue),
                      ))
                  .toList(),
            ),
            FormBuilderChoiceChip(
              name: 'choice_chip',
              validator: FormBuilderValidators.required(),
              onChanged: (val) {
                severity = val as String?;
              },
              decoration: const InputDecoration(
                labelText: 'Select a severity',
              ),
              options: const [
                FormBuilderFieldOption(value: 'low', child: Text('Low')),
                FormBuilderFieldOption(value: 'medium', child: Text('Medium')),
                FormBuilderFieldOption(value: 'high', child: Text('High')),
                FormBuilderFieldOption(
                    value: 'critical', child: Text('Critical')),
              ],
            ),
            FormBuilderTextField(
              name: 'comments',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp("^[A-Za-z\\s0-9]*")),
              ],
              onChanged: (val) {
                comments = val;
              },
              validator: FormBuilderValidators.required(),
              decoration: const InputDecoration(
                labelText: 'Comments',
              ),
            ),
            const Spacer(),
            if (_images.isEmpty)
              CardPicture(
                onTap: () async {
                  final String? imagePath =
                      await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TakePhoto(
                                camera: _cameraDescription,
                              )));

                  print('imagepath: $imagePath');
                  if (imagePath != null) {
                    setState(() {
                      _images.clear();
                      _images.add(imagePath);
                    });
                  }
                },
              ),
            if (_images.isNotEmpty)
              CardPicture(
                  imagePath: _images.first,
                  onTap: () async {
                    imagePath =
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TakePhoto(
                                  camera: _cameraDescription,
                                )));

                    print('imagepath: $imagePath');
                    if (imagePath != null) {
                      setState(() {
                        _images.clear();
                        _images.add(imagePath!);
                      });
                    }
                  }),
            const Spacer(),
            if (noImage) noImageAdded,
            MaterialButton(
              color: Colors.green,
              // color: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.all(10.0),
              height: 50,
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                _formKey.currentState!.save();
                if (_images.isEmpty) {
                  setState(() {
                    noImage = true;
                  });
                } else {
                  setState(() {
                    noImage = false;
                  });
                }
                if (_formKey.currentState!.validate()) {
                  submitData();
                }
              },
            ),
          ]),
        ),
      ),
    ));
  }
}
