import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../providers/inputState.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../functions/photo_service_web.dart' if (dart.library.io) '../../functions/photo_service_mobile.dart';

class PhotoEditorPage extends StatefulWidget {
  final XFile? imageFile;
  final InputPhoto? existingPhoto;

  const PhotoEditorPage({
    Key? key,
    this.imageFile,
    this.existingPhoto,
  }) : super(key: key);

  @override
  State<PhotoEditorPage> createState() => _PhotoEditorPageState();
}

class _PhotoEditorPageState extends State<PhotoEditorPage> {
  Uint8List? _imageBytes;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      // Load from XFile if provided (new photo)
      if (widget.imageFile != null) {
        _imageBytes = await widget.imageFile!.readAsBytes();
      } 
      // Load from existing InputPhoto (editing)
      else if (widget.existingPhoto != null) {
        if (widget.existingPhoto!.croppedBytes != null) {
          _imageBytes = widget.existingPhoto!.croppedBytes;
        } else if (widget.existingPhoto!.localPath != null) {
          final file = File(widget.existingPhoto!.localPath!);
          _imageBytes = await file.readAsBytes();
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEditedImage(Uint8List editedBytes) async {
    try {
      String? localPath;

      if (kIsWeb) {
        // Web: Create blob URL
        localPath = PhotoServicePlatform.createObjectUrl(editedBytes);
      } else {
        // Mobile: Save to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(editedBytes);
        localPath = file.path;
      }

      // Create InputPhoto and return to gallery
      final inputPhoto = InputPhoto(
        croppedBytes: editedBytes,
        localPath: localPath,
      );

      if (mounted) {
        Navigator.pop(context, inputPhoto);
      }
    } catch (e) {
      print('Error saving edited image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _imageBytes == null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // For pro_image_editor 5.3.0
    return ProImageEditor.memory(
      _imageBytes!,
      callbacks: ProImageEditorCallbacks(
        onImageEditingComplete: (bytes) async {
          await _saveEditedImage(bytes);
        },
        onCloseEditor: () async {
          Navigator.pop(context);
        },
      ),
      configs: ProImageEditorConfigs(
        // Design mode
        designMode: ImageEditorDesignModeE.material,
        
        // Hero animation tag
        heroTag: 'photo_editor',
        
        // Theme
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.blue,
            secondary: Colors.blueAccent,
          ),
        ),
        
        // Icon theme
        icons: const ImageEditorIcons(
          paintingEditor: IconsPaintingEditor(
            bottomNavBar: Icons.brush,
          ),
          textEditor: IconsTextEditor(
            bottomNavBar: Icons.text_fields,
          ),
          cropRotateEditor: IconsCropRotateEditor(
            bottomNavBar: Icons.crop,
          ),
          filterEditor: IconsFilterEditor(
            bottomNavBar: Icons.filter,
          ),
          emojiEditor: IconsEmojiEditor(
            bottomNavBar: Icons.emoji_emotions,
          ),
          stickerEditor: IconsStickerEditor(
            bottomNavBar: Icons.sticky_note_2,
          ),
        ),
        
        // Paint editor configuration
        paintEditorConfigs: const PaintEditorConfigs(
          enabled: false,
        ),
        
        // Text editor configuration
        textEditorConfigs: const TextEditorConfigs(
          enabled: false,
        ),
        
        // Crop & Rotate configuration
        cropRotateEditorConfigs: const CropRotateEditorConfigs(
          enabled: true,
          canRotate: true,
          canFlip: true,
        ),
        
        // Filter configuration
        filterEditorConfigs: FilterEditorConfigs(
          enabled: true,
          filterList: presetFiltersList,
        ),
        
        // Emoji editor configuration
        emojiEditorConfigs: const EmojiEditorConfigs(
          enabled: false, // Disabled for simplicity
        ),

        blurEditorConfigs: const BlurEditorConfigs(
          enabled: false,
        ),
        
        // State history (for undo/redo)
        stateHistoryConfigs: const StateHistoryConfigs(
          stateHistoryLimit: 4,
        ),
        
      ),
    );
  }
}