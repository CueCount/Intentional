import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/appBar.dart'; 
import '../../router/router.dart'; 
import '../../data/inputState.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class PhotoCropPage extends StatefulWidget {
  final XFile imageFile;

  const PhotoCropPage({
    Key? key,
    required this.imageFile,
  }) : super(key: key);

  @override
  _PhotoCropPageState createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  File? _croppedPhoto;
  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _prepareImage();
  }

  Future<void> _prepareImage() async {
    setState(() {
      _isCropping = true;
    });

    try {
      // Create a File from XFile
      final File originalFile = File(widget.imageFile.path);
      setState(() {
        _croppedPhoto = originalFile;
        _isCropping = false;
      });
    } catch (e) {
      print("Error preparing image: $e");
      setState(() {
        _isCropping = false;
      });
    }
  }

  Future<void> _cropImage() async {
    if (_croppedPhoto == null) return;

    setState(() {
      _isCropping = true;
    });

    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _croppedPhoto!.path,
        aspectRatio: CropAspectRatio(
          ratioX: 600,
          ratioY: 750,
        ),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPickerButtonHidden: true,
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: CroppieBoundary(
              width: 600, 
              height: 750,
            ),
            viewPort: CroppieViewPort(
              width: 480,
              height: 600,
              type: 'rectangle',
            ),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _croppedPhoto = File(croppedFile.path);
        });
      }
    } catch (e) {
      print("Error cropping image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cropping image: $e')),
      );
    } finally {
      setState(() {
        _isCropping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crop Photo'),
        actions: [
          IconButton(
            icon: Icon(Icons.crop),
            onPressed: _cropImage,
          ),
        ],
      ),
      body: _isCropping
          ? Center(child: CircularProgressIndicator())
          : _croppedPhoto != null
              ? Center(
                  child: InteractiveViewer(
                    constrained: false,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // The actual image
                          Image.file(
                            _croppedPhoto!,
                            fit: BoxFit.contain,
                          ),
                          // Overlay with cut-out rectangle
                          IgnorePointer(
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                              ),
                              child: Center(
                                child: Container(
                                  width: 300, // Scaled down for screen display
                                  height: 375, // Maintaining the 600:750 ratio
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white, width: 2),
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Center(child: Text('No image selected')),

      bottomNavigationBar: CustomAppBar(
        onPressed: () async {
          if (_croppedPhoto != null) {
            final inputState = Provider.of<InputState>(context, listen: false);
            final bytes = await _croppedPhoto!.readAsBytes();
            final base64 = base64Encode(bytes);
            final filename = _croppedPhoto!.path.split('/').last;

            final inputPhoto = InputPhoto(
              base64Data: base64,
              localUrl: _croppedPhoto!.path,
              firestoreUrl: '',
              filename: filename,
            );

            // Overwrite or add to InputState
            inputState.photoInputs = [...inputState.photoInputs, inputPhoto];

            if (context.mounted) {
              Navigator.pushNamed(context, AppRoutes.photos);
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No cropped image to save')),
            );
          }
        },
      ),

    );
  }
}