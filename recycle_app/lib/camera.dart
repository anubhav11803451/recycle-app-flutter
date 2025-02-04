import 'dart:async';
import 'dart:io';
import 'package:tflite/tflite.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'package:recycle_app/predict.dart';
import 'predict.dart';
import 'package:image_picker/image_picker.dart';

// A screen that allows users to take a picture using a given camera.
class Camera extends StatefulWidget {
  final CameraDescription camera;

  const Camera({
    Key key,
    @required this.camera,
  }) : super(key: key);

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<Camera> {
  CameraController _controller;
  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,
    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Take a picture')),
      // Wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner
      // until the controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return CameraPreview(_controller);
          } else {
            // Otherwise, display a loading indicator.
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera_alt),
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Construct the path where the image should be saved using the
            // pattern package.
            final path = join(
              // Store the picture in the temp directory.
              // Find the temp directory using the `path_provider` plugin.
              (await getTemporaryDirectory()).path,
              '${DateTime.now()}.png',
            );

            // Attempt to take a picture and log where it's been saved.
            await _controller.takePicture(path);

            print(path);

            // If the picture was taken, display it on a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(imagePath: path),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
      ),
    );
  }
}

// A widget that displays the picture taken by the user.
class DisplayPictureScreen extends StatefulWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  _DisplayPictureScreenState createState() => _DisplayPictureScreenState();
}

class _DisplayPictureScreenState extends State<DisplayPictureScreen> {
  String result;
  // File _image;
  List _recognitions;
  final picker = ImagePicker();

  // Future getImage() async {
  //   final pickedFile = await picker.getImage(source: ImageSource.camera);

  //   setState(() {
  //     if (pickedFile != null) {
  //       _image = File(pickedFile.path);
  //     } else {
  //       print('No image selected.');
  //     }
  //   });
  // }

  // Future predictImage(File image) async {
  //   if (image == null) return;

  Future classifyImage() async {
    print("classifyImage called");
    result = await Tflite.loadModel(
        model: "assets/recycle_detection_model.tflite",
        labels: "assets/labels.txt");
    print("model: " + result);
    var recognitions = await Tflite.detectObjectOnImage(
        path: widget.imagePath, numResultsPerClass: 6);
    setState(() {
      _recognitions = recognitions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Display the Picture')),
        // The image is stored as a file on the device. Use the `Image.file`
        // constructor with the given path to display the image.
        body: Container(
          child: Column(
            children: [
              Center(child: Image.file(File(widget.imagePath))),
              Center(
                child: RaisedButton(
                  child: Text('Predict', style: TextStyle(fontSize: 30)),
                  onPressed: () => classifyImage,
                ),
              ),
              _recognitions == null
                  ? Text(result)
                  : Text(_recognitions.toString())
            ],
          ),
        ));
  }
}

// import 'dart:async';
// import 'dart:io';
// import "package:flutter/material.dart";
// import 'package:recycle_app/results.dart';

// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:path/path.dart' show join;
// import 'package:path_provider/path_provider.dart';

// // A screen that allows users to take a picture using a given camera.
// class Camera extends StatefulWidget {
//   final CameraDescription camera;

//   const Camera({
//     Key key,
//     @required this.camera,
//   }) : super(key: key);

//   @override
//   TakePictureScreenState createState() => TakePictureScreenState();
// }

// class TakePictureScreenState extends State<Camera> {
//   CameraController _controller;
//   Future<void> _initializeControllerFuture;

//   @override
//   void initState() {
//     super.initState();
//     // To display the current output from the Camera,
//     // create a CameraController.
//     _controller = CameraController(
//       // Get a specific camera from the list of available cameras.
//       widget.camera,
//       // Define the resolution to use.
//       ResolutionPreset.medium,
//     );

//     // Next, initialize the controller. This returns a Future.
//     _initializeControllerFuture = _controller.initialize();
//   }

//   @override
//   void dispose() {
//     // Dispose of the controller when the widget is disposed.
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Camera')),
//       // Wait until the controller is initialized before displaying the
//       // camera preview. Use a FutureBuilder to display a loading spinner
//       // until the controller has finished initializing.
//       body: FutureBuilder<void>(
//         future: _initializeControllerFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.done) {
//             // If the Future is complete, display the preview.
//             return CameraPreview(_controller);
//           } else {
//             // Otherwise, display a loading indicator.
//             return Center(child: CircularProgressIndicator());
//           }
//         },
//       ),
//       floatingActionButton: FloatingActionButton(
//         child: Icon(Icons.camera_alt),
//         // Provide an onPressed callback.
//         onPressed: () async {
//           // Take the Picture in a try / catch block. If anything goes wrong,
//           // catch the error.
//           try {
//             // Ensure that the camera is initialized.
//             await _initializeControllerFuture;

//             // Construct the path where the image should be saved using the
//             // pattern package.
//             final path = join(
//               // Store the picture in the temp directory.
//               // Find the temp directory using the `path_provider` plugin.
//               (await getTemporaryDirectory()).path,
//               '${DateTime.now()}.png',
//             );

//             // Attempt to take a picture and log where it's been saved.
//             await _controller
//                 .takePicture(); //was .takePicture(path); but wouldnt run

//             // If the picture was taken, display it on a new screen.
//             Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder: (context) => Results(path),
//               ),
//             );
//           } catch (e) {
//             // If an error occurs, log the error to the console.
//             print(e);
//           }
//         },
//       ),
//     );
//   }
// }

// class DisplayPictureScreen extends StatelessWidget {
//   final String imagePath;

//   const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Display the Picture')),
//       // The image is stored as a file on the device. Use the `Image.file`
//       // constructor with the given path to display the image.
//       body: Image.file(File(imagePath)),
//     );
//   }
// }

// // A widget that displays the picture taken by the user.
// // class Results extends StatelessWidget {
// //   final String imagePath;

// //   const Results({Key key, this.imagePath}) : super(key: key);

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Results Page')),
// //       // The image is stored as a file on the device. Use the `Image.file`
// //       // constructor with the given path to display the image.
// //       body: Image.file(File(imagePath)),
// //     );
// //   }
// // }
// /*
// class Camera extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).backgroundColor,
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).primaryColor,
//         title: Text("Camera", style: TextStyle(fontSize: 25)),
//       ),
//       body: Center(
//         child: RaisedButton(
//           color: Theme.of(context).focusColor,
//           shape:
//               RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           padding: EdgeInsets.all(15),
//           textColor: Colors.white,
//           child: Text('Results', style: TextStyle(fontSize: 30)),
//           onPressed: () {
//             Navigator.push(
//               context,
//               MaterialPageRoute(builder: (context) => Results()),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }*/
