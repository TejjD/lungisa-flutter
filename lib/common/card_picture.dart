import 'dart:io';
import 'package:flutter/material.dart';

class CardPicture extends StatelessWidget {
  CardPicture({this.onTap, this.imagePath});

  final Function()? onTap;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    if (imagePath != null) {
      return Card(
          elevation: 3,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 300,
              padding: const EdgeInsets.all(10.0),
              width: size.width * .70,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(File(imagePath as String))),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    child: const Icon(
                      Icons.photo_camera,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ));
    } else {
      return Card(
          elevation: 3,
          child: InkWell(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
              width: size.width * .35,
              color: Theme.of(context).colorScheme.secondary,
              height: 56,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                            text: "Picture ",
                            style:
                                TextStyle(fontSize: 17.0, color: Colors.white)),
                        WidgetSpan(
                          child: Icon(Icons.camera_alt,
                              size: 17, color: Colors.white),
                        ),
                      ],
                    ),
                  )
                  // Text(
                  //   'Attach Picture',
                  //   style: TextStyle(fontSize: 17.0, color: Colors.grey[600]),
                  // ),
                  // Icon(
                  //   Icons.photo_camera,
                  //   color: Colors.indigo[400],
                  // )
                ],
              ),
            ),
          ));
    }
  }
}
