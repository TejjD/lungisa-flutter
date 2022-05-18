import 'dart:convert';

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

import '../common/card_picture.dart';
import '../common/take_photo.dart';

class Home extends StatefulWidget {
  const Home({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

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
        print(_currentPosition);
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
