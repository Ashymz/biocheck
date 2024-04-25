import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_compare/image_compare.dart';

class Scan extends StatefulWidget {
  @override
  _ScanState createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  File? _firstImageFile;
  File? _secondImageFile;
  String? _recognizedFaceId;
  String? _savedFaceId;
  bool _isComparing = false;

  @override
  void initState() {
    super.initState();
    _loadFaceId();
  }

  Future<void> _loadFaceId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _savedFaceId = prefs.getString('faceId');
    });
  }

  Future<void> _saveFaceId(String faceId) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('faceId', faceId);
  }

  Future<double> _compareImages(File imageFile1, File imageFile2) async {
    final bytes1 = await imageFile1.readAsBytes();
    final bytes2 = await imageFile2.readAsBytes();

    final result = await compareImages(
      src1: bytes1,
      src2: bytes2,
      algorithm: EuclideanColorDistance(ignoreAlpha: true),
    );
    print(result);
    return result;
  }

  Future<void> _showResult(double difference) async {
    String message;

    if (difference < 0.05) {
      message = 'Images match!';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Comparison Result'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      message = 'Images do not match!';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Comparison Result'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }

    // await showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     title: Text('Comparison Result'),
    //     content: Text(message),
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.of(context).pop(),
    //         child: Text('OK'),
    //       ),
    //     ],
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Facial Recognition'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _firstImageFile == null
                  ? Text('No image selected.')
                  : Image.file(
                      _firstImageFile!,
                      width: MediaQuery.of(context).size.width * 0.8,
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _pickImage(1),
                child: Text('Select First Image'),
              ),
              SizedBox(height: 20),
              _secondImageFile == null
                  ? Text('No second image selected.')
                  : Image.file(
                      _secondImageFile!,
                      width: MediaQuery.of(context).size.width * 0.8,
                    ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _pickImage(2),
                child: Text('Select Second Image'),
              ),
              SizedBox(height: 20),
              _isComparing
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _isComparing = true;
                        });
                        final difference = await _compareImages(
                            _firstImageFile!, _secondImageFile!);
                        setState(() {
                          _isComparing = false;
                        });
                        await _showResult(difference);
                      },
                      child: Text('Compare Images'),
                    ),
              // SizedBox(height: 20),
              // _recognizedFaceId != null
              //     ? Text('Recognized Face ID: $_recognizedFaceId')
              //     : SizedBox.shrink(),
              // _savedFaceId != null
              //     ? Text('Saved Face ID: $_savedFaceId')
              //     : SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(int imageNumber) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final faceId = imageFile.path;

      if (imageNumber == 1) {
        setState(() {
          _firstImageFile = imageFile;
        });
      } else {
        setState(() {
          _secondImageFile = imageFile;
        });
      }

      _saveFaceId(faceId);
    } else {
      print('No image selected.');
    }
  }
}
