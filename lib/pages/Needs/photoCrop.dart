import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../router/router.dart';
import '../../data/inputState.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vector_math/vector_math_64.dart' show Vector3;

// Conditional import - will choose the right implementation
import '../../functions/helpers/photo_service_web.dart' if (dart.library.io) '../../functions/photo_service_mobile.dart';

class PhotoCropPage extends StatefulWidget {
  final XFile imageFile;
  const PhotoCropPage({Key? key, required this.imageFile}) : super(key: key);
  @override
  State<PhotoCropPage> createState() => _PhotoCropPageState();
}

class _PhotoCropPageState extends State<PhotoCropPage> {
  late File _originalFile;
  Uint8List? _originalBytes;
  TransformationController _controller = TransformationController();
  GlobalKey _imageKey = GlobalKey();

  bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      widget.imageFile.readAsBytes().then((bytes) {
        setState(() {
          _originalBytes = bytes;
        });
      });
    } else {
      _originalFile = File(widget.imageFile.path);
      _originalFile.readAsBytes().then((bytes) {
        setState(() {
          _originalBytes = bytes;
        });
      });
    }
  }

  Future<void> _autoCropAndSubmit() async {
    if (_originalBytes == null) return;
    setState(() => _isCropping = true);

    try {
      // 1. Get the rendered image size
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox == null) {
        throw Exception("RenderBox not found");
      }
      final renderedSize = renderBox.size;
      
      // 2. Decode the original image to get its dimensions
      final originalImage = img.decodeImage(_originalBytes!);
      if (originalImage == null) {
        throw Exception("Could not decode image");
      }
      final originalWidth = originalImage.width.toDouble();
      final originalHeight = originalImage.height.toDouble();
      
      // 3. Calculate the scale ratios between original and rendered image
      // We need to handle potential letterboxing from BoxFit.contain
      final originalAspect = originalWidth / originalHeight;
      final renderedAspect = renderedSize.width / renderedSize.height;
      
      double scaleX, scaleY, offsetX = 0, offsetY = 0;
      
      if (originalAspect > renderedAspect) {
        // Image is wider than container - letterboxing on top/bottom
        scaleX = originalWidth / renderedSize.width;
        scaleY = scaleX; // Maintain aspect ratio
        offsetY = (renderedSize.height - (originalHeight / scaleX)) / 2;
      } else {
        // Image is taller than container - letterboxing on sides
        scaleY = originalHeight / renderedSize.height;
        scaleX = scaleY; // Maintain aspect ratio
        offsetX = (renderedSize.width - (originalWidth / scaleY)) / 2;
      }
      
      // 4. Get the screen overlay coordinates
      const overlayWidth = 300.0;
      const overlayHeight = 375.0;
      final screenWidth = MediaQuery.of(context).size.width;
      const screenHeight = 500.0;
      
      final overlayLeft = (screenWidth - overlayWidth) / 2;
      final overlayTop = (screenHeight - overlayHeight) / 2;
      
      // 5. Apply the current transformation from InteractiveViewer
      final matrix = _controller.value;
      final inverseMatrix = Matrix4.inverted(matrix);
      
      // 6. Map the overlay corners to the transformed image space
      final screenCorners = [
        Vector3(overlayLeft, overlayTop, 0),
        Vector3(overlayLeft + overlayWidth, overlayTop, 0),
        Vector3(overlayLeft, overlayTop + overlayHeight, 0),
        Vector3(overlayLeft + overlayWidth, overlayTop + overlayHeight, 0)
      ];
      
      final imageCorners = screenCorners.map((corner) {
        final transformed = inverseMatrix.transform3(corner);
        // Apply scaling and offset to get to original image coordinates
        return Vector3(
          (transformed.x - offsetX) * scaleX,
          (transformed.y - offsetY) * scaleY,
          0
        );
      }).toList();
      
      // 7. Find the bounding box in the original image
      final minX = imageCorners.map((v) => v.x).reduce((a, b) => a < b ? a : b).clamp(0, originalWidth);
      final minY = imageCorners.map((v) => v.y).reduce((a, b) => a < b ? a : b).clamp(0, originalHeight);
      final maxX = imageCorners.map((v) => v.x).reduce((a, b) => a > b ? a : b).clamp(0, originalWidth);
      final maxY = imageCorners.map((v) => v.y).reduce((a, b) => a > b ? a : b).clamp(0, originalHeight);
      
      // 8. Crop the image using these bounds
      final cropX = minX.toInt();
      final cropY = minY.toInt();
      final cropW = (maxX - minX).toInt().clamp(1, originalImage.width - cropX);
      final cropH = (maxY - minY).toInt().clamp(1, originalImage.height - cropY);
      final croppedImage = img.copyCrop(originalImage,x: cropX,y: cropY,width: cropW,height: cropH);
      
      // Save the cropped image - using platform-specific approach
      final croppedBytes = Uint8List.fromList(img.encodeJpg(croppedImage));

      String? localPath;

      if (kIsWeb) {
        // Web: synchronous blob URL creation
        localPath = PhotoServicePlatform.createObjectUrl(croppedBytes);
      } else {
        // Mobile: get temp directory first, then create file
        final appDir = await getApplicationDocumentsDirectory();
        localPath = PhotoServicePlatform.createObjectUrlSync(croppedBytes, appDir.path);
      }

      final inputPhoto = InputPhoto(croppedBytes: croppedBytes, localPath: localPath);
      final inputState = Provider.of<InputState>(context, listen: false);
      inputState.photoInputs = [...inputState.photoInputs, inputPhoto];

      if (context.mounted) {
        print('Image saved to InputState Successfully: $inputPhoto');
        Navigator.pushNamed(context, AppRoutes.photos);
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isCropping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Crop Photo")),
      body: _originalBytes == null
      ? const Center(child: CircularProgressIndicator())
      : Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 500,
              child: InteractiveViewer(
                transformationController: _controller,
                boundaryMargin: const EdgeInsets.all(100),
                child: Image.memory(_originalBytes!, key: _imageKey, fit: BoxFit.contain),
              ),
            ),
            IgnorePointer(
              child: Container(
                width: double.infinity,
                height: 500,
                color: Colors.black.withOpacity(0.4),
                child: Center(
                  child: Container(
                    width: 300,
                    height: 375,
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
      bottomNavigationBar: CustomAppBar(
        onPressed: _isCropping
        ? () {}
        : () => _autoCropAndSubmit(),
      ),
    );
  }
}