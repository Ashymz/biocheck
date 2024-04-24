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
import 'dart:io';
import 'package:image_compare/image_compare.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_compare/image_compare.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:image/image.dart' as imag;

// import 'package:supabase_flutter/supabase_flutter.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final String storageKey = 'attendanceData';

  File? snappedImage;
  File? storeImage;

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

      // Retrieve existing attendance list
      final List<String>? existingList =
          prefs.getStringList('attendanceList') ?? [];

      // Add new data to the list
      existingList!.add(jsonData);

      // Save updated list
      prefs.setStringList('attendanceList', existingList);

      // Save image to the new file path
      await imageFile.copy(newPath);
      print('Saved data in SharedPreferences: $jsonData');

      print('Saved attendance list: $existingList');

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

    print('Attempting to retrieve data for matricNo: $matricNo');

    final List<String>? attendanceList = prefs.getStringList('attendanceList');

    // Debug: Print the entire attendance list
    print('Retrieved attendance list: $attendanceList');

    if (attendanceList != null && attendanceList.isNotEmpty) {
      for (String jsonData in attendanceList) {
        final Map<String, dynamic> data = jsonDecode(jsonData);
        if (data['matricNo'] == matricNo) {
          print('Retrieved Data for matricNo $matricNo: $jsonData');
          return data;
        }
      }
    } else {
      print('No data found for matricNo: $matricNo');
    }

    return null;
  }

  // Future<bool> _compareImages(File newImage) async {
  //   // Retrieve all stored image paths
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final String? storedDataJson = prefs.getString('attendance_list');

  //   if (storedDataJson != null) {
  //     final List<Map<String, dynamic>> attendanceList =
  //         List<Map<String, dynamic>>.from(jsonDecode(storedDataJson));

  //     for (var attendanceData in attendanceList) {
  //       final String storedImagePath = attendanceData['image_path'];
  //       final File storedImageFile = File(storedImagePath);

  //       if (await storedImageFile.exists()) {
  //         final similarityScore =
  //             await _runPythonImageComparison(storedImageFile, newImage);

  //         print(
  //             'Similarity Score with stored image $storedImagePath: $similarityScore');

  //         if (similarityScore > 0.9) {
  //           print('Match found!!!!');
  //           return true; // Images match
  //         }
  //       }
  //     }
  //   } else {
  //     print('No stored image data found.');
  //   }

  //   print('No match found.');
  //   return false;
  // }

  // Future<bool> _compareImages(File newImage) async {
  //   // Retrieve all stored image paths
  //   final SharedPreferences prefs = await SharedPreferences.getInstance();
  //   final String? storedDataJson = prefs.getString('attendance_list');

  //   if (storedDataJson != null) {
  //     final List<Map<String, dynamic>> attendanceList =
  //         List<Map<String, dynamic>>.from(jsonDecode(storedDataJson));

  //     for (var attendanceData in attendanceList) {
  //       final String storedImagePath = attendanceData['image_path'];
  //       final File storedImageFile = File(storedImagePath);

  //       print(storedImageFile);
  //       if (await storedImageFile.exists()) {
  //         var bytes1 = await newImage.readAsBytes();
  //         var bytes2 = await storedImageFile.readAsBytes();

  //         var image1 = decodeImage(bytes1);
  //         var image2 = decodeImage(bytes2);

  //         var similarity = await compareImages(
  //             src1: image1,
  //             src2: image2,
  //             algorithm: ChiSquareDistanceHistogram());

  //         print(
  //             'Similarity with stored image $storedImagePath: ${similarity * 100}%');

  //         if (similarity > 0.9) {
  //           print('Match found!!!!');
  //           return true; // Images match
  //         }
  //       }
  //     }
  //   } else {
  //     print('No stored image data found.');
  //   }

  //   print('No match found.');
  //   return false;
  // }

  Future<double> _runPythonImageComparison(
      File storedImage, File newImage) async {
    const scriptPath = 'lib/presentation/compare_images.py';
    final process = await Process.start(
        'python', [scriptPath, storedImage.path, newImage.path]);

    final output = await process.stdout.transform(utf8.decoder).toList();
    final similarityScore = double.parse(output.first.trim());

    return similarityScore;
  }

  Future<File?> captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  Future<bool> _compareImages(File newImage, File storedImage) async {
    var bytes1 = await newImage.readAsBytes();
    var bytes2 = await storedImage.readAsBytes();

    var image1 = img.decodeImage(bytes1);
    var image2 = img.decodeImage(bytes2);

    if (image1 != null && image2 != null) {
      var similarity = await compareImages(
        src1: image1,
        src2: image2,
        algorithm: ChiSquareDistanceHistogram(),
      );

      print('Similarity with stored image: ${similarity * 100}%');

      if (similarity > 0.9) {
        print('Match found!!!!');
        return true; // Images match
      }
    }

    print('No match found.');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    // Color myColor = const Color.fromARGB(255, 124, 12, 180);
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
                    snappedImage != null
                        ? Image.file(
                            snappedImage!,
                            width: 200,
                            height: 200,
                          )
                        : const SizedBox.shrink(),
                    storeImage != null
                        ? Image.file(
                            storeImage!,
                            width: 200,
                            height: 200,
                          )
                        : const SizedBox.shrink(),
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
                            // bool isMatch = await _compareImages(capturedImage);
                            // if (isMatch) {
                            //   print(
                            //       'Match found. Showing "Already Present" dialog.');

                            //   // showDialog(
                            //   //   context: context,
                            //   //   builder: (context) => AlertDialog(
                            //   //     title: Text('Attendance Marked!'),
                            //   //     content: const Text('Already Present'),
                            //   //     actions: [
                            //   //       TextButton(
                            //   //         onPressed: () {
                            //   //           Navigator.pop(context);
                            //   //         },
                            //   //         child: Text('OK'),
                            //   //       ),
                            //   //     ],
                            //   //   ),
                            //   // );
                            // }
                            // else {
                            //   print(
                            //       'No match found. Showing "New Attendance Marked" dialog.');
                            //   // Save new attendance
                            //   DateTime now = DateTime.now();
                            //   String timestamp = now.toIso8601String();
                            //   _saveAttendance(timestamp, timestamp, timestamp,
                            //       capturedImage, context);
                            //   // showDialog(
                            //   //   context: context,
                            //   //   builder: (context) => AlertDialog(
                            //   //     title: Text('New Attendance Marked!'),
                            //   //     content: Text('You are marked present.'),
                            //   //     actions: [
                            //   //       TextButton(
                            //   //         onPressed: () {
                            //   //           Navigator.pop(context);
                            //   //         },
                            //   //         child: Text('OK'),
                            //   //       ),
                            //   //     ],
                            //   //   ),
                            //   // );
                            // }
                          }
                        },
                        child: Custombutton.button(
                            Colors.black45, 'Mark Attendance'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: GestureDetector(
                        onTap: () async {
                          if (snappedImage != null && storeImage != null) {
                            bool isMatch = await _compareImages(
                                snappedImage!, storeImage!);
                            if (isMatch) {
                              print(
                                  'Match found. Showing "Already Present" dialog.');
                            } else {
                              print(
                                  'No match found. Showing "New Attendance Marked" dialog.');
                            }
                          }
                        },
                        child: Custombutton.button(
                          Colors.black45,
                          'Compare Images',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
