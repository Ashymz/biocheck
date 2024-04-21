import 'dart:math';

import 'package:biocheck/constants/supabase.dart';
import 'package:biocheck/utils/functions.dart';
import 'package:biocheck/utils/media.dart';
import 'package:biocheck/widgets/alert.dart';
import 'package:biocheck/widgets/button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_vision/google_ml_vision.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
// import 'package:local_auth/local_auth.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase/supabase.dart';

import 'dart:convert';
import 'dart:typed_data';

// import 'package:supabase_flutter/supabase_flutter.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final String storageKey = 'attendanceData';

  Future<void> _saveAttendance(String id, String matricNo, String timestamp,
      File imageFile, BuildContext context) async {
    final String path = 'attendance_images/$id.jpg';
    final String newPath =
        '${(await getApplicationDocumentsDirectory()).path}/$path';

    try {
      // Create directory if it doesn't exist
      final Directory directory = Directory(dirname(newPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      // Store attendance data locally using shared_preferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      final Map<String, dynamic> data = {
        'id': id,
        'matricNo': matricNo,
        'timestamp': timestamp,
        'image_path': newPath,
      };
      print(data);

      final String jsonData = jsonEncode(data);
      print('Data to be saved: $data');
      await prefs.setString('attendance_$id', jsonData);
      print(jsonData);
      // Save image to the new file path
      await imageFile.copy(newPath);
      print('Saved data in SharedPreferences: $jsonData');

      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Attendance Marked!'),
          content: Text('You are marked present.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error saving attendance: $e');
    }
  }

  Future<Map<String, dynamic>?> _getAttendance(String matricNo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String key = matricNo;

    print('Attempting to retrieve data for matricNo: $matricNo');

    if (prefs.containsKey(key)) {
      final String? jsonData = prefs.getString(key);

      if (jsonData != null) {
        print('Retrieved Data for matricNo $matricNo: $jsonData');
        return jsonDecode(jsonData);
      } else {
        print('Data for matricNo $matricNo is null.');
      }
    } else {
      print('No data found for matricNo: $matricNo');
    }

    return null;
  }

  Future<bool> _compareImages(File newImage, String matricNo) async {
    final storeData = await _getAttendance(matricNo);
    print('Retrieved Data: $storeData');
    print('Comparing images...');
    print('Comparing images...');
    print('Comparing images...');
    print('Comparing images...');

    final Map<String, dynamic>? storedData = await _getAttendance(matricNo);

    if (storedData != null) {
      print('Stored image data found.');
      print('Stored image data found.');
      print('Stored image data found.');

      final String storedImagePath = storedData['image_path'];
      final File storedImageFile = File(storedImagePath);
      print('Stored Image Path: $storedImagePath');
      print('Stored Image Path: $storedImagePath');
      print('Stored Image Path: $storedImagePath');

      if (await storedImageFile.exists()) {
        final List<int> storedImageBytes = await storedImageFile.readAsBytes();
        final List<int> newImageBytes = await newImage.readAsBytes();

        print('Stored Image Bytes Length: ${storedImageBytes.length}');
        print('Stored Image Bytes Length: ${storedImageBytes.length}');
        print('Stored Image Bytes Length: ${storedImageBytes.length}');
        print('New Image Bytes Length: ${newImageBytes.length}');
        print('New Image Bytes Length: ${newImageBytes.length}');
        print('New Image Bytes Length: ${newImageBytes.length}');

        final Uint8List storedImageUint8List =
            Uint8List.fromList(storedImageBytes);
        final Uint8List newImageUint8List = Uint8List.fromList(newImageBytes);

        final model = GenerativeModel(
            model: 'gemini-pro-vision',
            apiKey: 'AIzaSyBt9ubx4BOLLoOAkMYXhkzHhKfoK6wx5do');

        final prompt = TextPart("What's different between these pictures?");
        final imageParts = [
          DataPart('image/jpeg', storedImageUint8List),
          DataPart('image/jpeg', newImageUint8List),
        ];

        final response = await model.generateContent([
          Content.multi([prompt, ...imageParts])
        ]);

        print('Response: $response');

        if (response.promptFeedback == 'success') {
          final similarityScore = double.parse(response.text!);
          print('Similarity Score: $similarityScore');

          if (similarityScore > 0.9) {
            print('Matched!!!!');
            return true; // Faces match
          }
        } else {
          print('Error in model response: ${response.promptFeedback}');
        }
      } else {
        print('Stored image file does not exist.');
      }
    } else {
      print('No stored image data found.');
    }

    return false;
  }

  Future<File?> captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Color myColor = const Color.fromARGB(255, 124, 12, 180);
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    return MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(0.85)),
        child: WillPopScope(
          onWillPop: () async {
            return false;
          },
          child: Scaffold(
            // appBar: AppBar(
            //   leading: const Icon(Icons.arrow_back),
            //   title: const Text(
            //     'Wallet',
            //   ),
            // ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 90),
                    Text(greeting(),
                        style: const TextStyle(
                            fontSize: 21,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    const Text('',
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.normal)),
                    const SizedBox(height: 10),
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    //   child: GestureDetector(
                    //       onTap: () async {

                    //         // _detectAndCompareFaces();
                    //         // Get.to(const CreateWallet());
                    //       },
                    //       child:
                    //           Custombutton.button(myColor, 'Mark Attendance')),
                    // )
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: GestureDetector(
                        onTap: () async {
                          File? capturedImage = await captureImage();
                          if (capturedImage != null) {
                            DateTime now = DateTime.now();
                            String timestamp = now.toIso8601String();
                            _saveAttendance(timestamp, timestamp, timestamp,
                                capturedImage, context);
                            bool isMatch =
                                await _compareImages(capturedImage, timestamp);
                            if (isMatch) {
                              print(
                                  'Match found. Showing "Already Present" dialog.');

                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Attendance Marked!'),
                                  content: const Text('Already Present'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            } else {
                              print(
                                  'No match found. Showing "New Attendance Marked" dialog.');
                              // Save new attendance
                              DateTime now = DateTime.now();
                              String timestamp = now.toIso8601String();
                              _saveAttendance(timestamp, timestamp, timestamp,
                                  capturedImage, context);
                              // showDialog(
                              //   context: context,
                              //   builder: (context) => AlertDialog(
                              //     title: Text('New Attendance Marked!'),
                              //     content: Text('You are marked present.'),
                              //     actions: [
                              //       TextButton(
                              //         onPressed: () {
                              //           Navigator.pop(context);
                              //         },
                              //         child: Text('OK'),
                              //       ),
                              //     ],
                              //   ),
                              // );
                            }
                          }
                        },
                        child: Custombutton.button(myColor, 'Mark Attendance'),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ));
  }
// }

// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:collection/collection.dart';

// class Scan extends StatefulWidget {
//   const Scan({Key? key}) : super(key: key);

//   @override
//   _ScanState createState() => _ScanState();
// }

// class _ScanState extends State<Scan> {
//   final ImagePicker _picker = ImagePicker();
//   File? savedImage;

//   Future<void> _saveImage(File image) async {
//     final Directory directory = await getApplicationDocumentsDirectory();
//     final String path = '${directory.path}/saved_image.jpg';

//     await image.copy(path);
//     setState(() {
//       savedImage = File(path);
//     });
//   }

//   Future<File?> _captureImage() async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera);

//     if (pickedFile != null) {
//       return File(pickedFile.path);
//     }
//     return null;
//   }

//   Future<bool> _compareImages(File newImage) async {
//     if (savedImage == null) {
//       return false;
//     }

//     final List<int> savedImageBytes = await savedImage!.readAsBytes();
//     final List<int> newImageBytes = await newImage.readAsBytes();

//     bool isMatch = ListEquality().equals(savedImageBytes, newImageBytes);

//     return isMatch;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Image Comparison'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             savedImage != null
//                 ? Image.file(savedImage!)
//                 : Text('No saved image'),
//             ElevatedButton(
//               onPressed: () async {
//                 File? capturedImage = await _captureImage();
//                 if (capturedImage != null) {
//                   await _saveImage(capturedImage);
//                   bool isMatch = await _compareImages(capturedImage);
//                   if (isMatch) {
//                     showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         title: Text('Image Match!'),
//                         content: Text('Images are identical.'),
//                         actions: [
//                           TextButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             child: Text('OK'),
//                           ),
//                         ],
//                       ),
//                     );
//                   } else {
//                     showDialog(
//                       context: context,
//                       builder: (context) => AlertDialog(
//                         title: Text('Image Mismatch!'),
//                         content: Text('Images are different.'),
//                         actions: [
//                           TextButton(
//                             onPressed: () {
//                               Navigator.pop(context);
//                             },
//                             child: Text('OK'),
//                           ),
//                         ],
//                       ),
//                     );
//                   }
//                 }
//               },
//               child: Text('Capture and Compare Image'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
}
