import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:lungisa/pages/camera.dart';

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
  var issueList = {
    'Pothole',
    'Sinkhole',
    'Burst Pipe',
    'Traffic robot',
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
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        child: FormBuilder(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(35.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
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
                    FormBuilderFieldOption(
                        value: 'medium', child: Text('Medium')),
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
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Camera()));
                  },
                  icon: const Icon(
                    // <-- Icon
                    Icons.camera_alt,
                    size: 24.0,
                  ),
                  label: const Text('Add picture'), // <-- Text
                ),
                MaterialButton(
                  color: Theme.of(context).colorScheme.secondary,
                  padding: const EdgeInsets.all(10.0),
                  child: const Text(
                    "Submit",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
