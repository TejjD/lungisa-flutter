import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

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

  var issueList = {
    'Pothole',
    'Sinkhole',
    'Burst Pipe',
    'Traffic robot',
    'Water outage',
    'Street lights',
    'Other'
  };

  final _formKey = GlobalKey<FormBuilderState>();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
        body: Center(
      child: FormBuilder(
        key: _formKey,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 130.0, horizontal: 50.0),
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            FormBuilderDropdown(
              name: 'issues',
              decoration: const InputDecoration(
                labelText: 'Issue',
              ),
              // initialValue: 'Male',
              allowClear: true,
              hint: const Text('Select issue'),
              validator: FormBuilderValidators.compose(
                  [FormBuilderValidators.required()]),
              items: issueList
                  .map((issue) => DropdownMenuItem(
                        value: issue,
                        child: Text(issue),
                      ))
                  .toList(),
            ),
            FormBuilderChoiceChip(
              name: 'choice_chip',
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
            FormBuilderDateTimePicker(
              name: 'date',
              // onChanged: _onChanged,
              inputType: InputType.both,
              decoration: const InputDecoration(
                labelText: 'Date spotted',
              ),
              initialTime: const TimeOfDay(hour: 8, minute: 0),
              initialValue: DateTime.now(),
              // enabled: true,
            ),
            FormBuilderTextField(
              name: 'comments',
              decoration: const InputDecoration(
                labelText:
                    'Comments',
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
                  }),
            const Spacer(),
            MaterialButton(
              color: Colors.green,
              // color: Theme.of(context).colorScheme.secondary,
              padding: const EdgeInsets.all(10.0),
              height: 50,
              child: const Text(
                "Submit",
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {},
            ),
          ]),
        ),
      ),
    ));
  }
}
