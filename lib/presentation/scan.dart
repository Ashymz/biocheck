import 'dart:math';

import 'package:biocheck/utils/functions.dart';
import 'package:biocheck/utils/media.dart';
import 'package:biocheck/widgets/alert.dart';
import 'package:biocheck/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

// import 'package:firebase_ml_vision/firebase_ml_vision.dart';
// import 'package:local_auth/local_auth.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final String storageKey = 'attendanceData';

  Future<void> _saveAttendance(String id, String timestamp) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> data = {
      'id': id,
      'timestamp': timestamp,
    };
    final String jsonData = jsonEncode(data);
    await prefs.setString(storageKey, jsonData);
  }

  Future<Map<String, dynamic>?> _getAttendance() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? jsonData = prefs.getString(storageKey);
    if (jsonData != null) {
      return jsonDecode(jsonData);
    }
    return null;
  }

  File? _imageFile;
  Future<File?> captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }

  // Future<bool> _compareImages(File newImage) async {
  //   final Map<String, dynamic>? storedData = await _getAttendance();
  //   if (storedData != null) {
  //     // Here you can implement facial recognition or image comparison logic.
  //     // For simplicity, let's compare image file paths.
  //     return storedData['id'] == newImage.path;
  //   }
  //   return false;
  // }
  Future<bool> _compareImages(File newImage) async {
    print('Comparing images...');
    final Map<String, dynamic>? storedData = await _getAttendance();
    if (storedData != null) {
      print('Stored data found.');
      // Load the stored image
      final File storedImageFile = File(storedData['id']);

      // Load the new image
      final GoogleVisionImage storedVisionImage =
          GoogleVisionImage.fromFilePath(storedImageFile.path);
      final GoogleVisionImage newVisionImage =
          GoogleVisionImage.fromFilePath(newImage.path);

      // Create an instance of FaceDetector
      final FaceDetector faceDetector = GoogleVision.instance.faceDetector();

      // Detect faces in the stored image
      final List<Face> storedFaces =
          await faceDetector.processImage(storedVisionImage);

      // Detect faces in the new image
      final List<Face> newFaces =
          await faceDetector.processImage(newVisionImage);

      // Check if the number of detected faces is the same
      if (storedFaces.length == 1 && newFaces.length == 1) {
        // Check if the faces match
        final double similarity =
            _calculateSimilarity(storedFaces[0], newFaces[0]);
        if (similarity > 0.9) {
          return true; // Faces match
        }
      } else {
        print('No stored data found.');
      }

      // No match found
      return false;
    }
    return false;
  }

  double _calculateSimilarity(Face face1, Face face2) {
    // Calculate similarity between two faces
    // You can use various metrics to compare faces
    // Here's a simple example using distance between eye landmarks
    final double eyeDistance1 = _calculateEyeDistance(face1);
    final double eyeDistance2 = _calculateEyeDistance(face2);

    // Calculate similarity as the ratio of the smaller eye distance to the larger eye distance
    final double similarity = eyeDistance1 < eyeDistance2
        ? eyeDistance1 / eyeDistance2
        : eyeDistance2 / eyeDistance1;

    return similarity;
  }

  double _calculateEyeDistance(Face face) {
    // Calculate the distance between the eyes
    final double leftEyeX =
        face.getLandmark(FaceLandmarkType.leftEye)?.position.dx ?? 0.0;
    final double leftEyeY =
        face.getLandmark(FaceLandmarkType.leftEye)?.position.dy ?? 0.0;
    final double rightEyeX =
        face.getLandmark(FaceLandmarkType.rightEye)?.position.dx ?? 0.0;
    final double rightEyeY =
        face.getLandmark(FaceLandmarkType.rightEye)?.position.dy ?? 0.0;

    final double distance =
        sqrt(pow(rightEyeX - leftEyeX, 2) + pow(rightEyeY - leftEyeY, 2));
    return distance;
  }
  // final LocalAuthentication localAuth = LocalAuthentication();

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
                            bool isMatch = await _compareImages(capturedImage);
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
                              _saveAttendance(capturedImage.path, timestamp);
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('New Attendance Marked!'),
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
}
