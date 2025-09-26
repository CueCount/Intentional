import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/photogrid.dart';
import '/router/router.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../functions/uiService.dart';

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({Key? key}) : super(key: key);
  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final inputState = Provider.of<InputState>(context, listen: false);
      final photoPaths = await inputState.getInput('photos');
      if (photoPaths != null && photoPaths is List) {
        inputState.photoInputs.clear();
        for (String path in photoPaths) {
          if (path.startsWith('data:')) {
            final base64String = path.split(',')[1];
            final bytes = base64Decode(base64String);
            inputState.photoInputs.add(InputPhoto(croppedBytes: bytes));
          } else {
            inputState.photoInputs.add(InputPhoto(localPath: path));
          }
        }
        setState(() {}); 
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputState = Provider.of<InputState>(context);
    final photos = inputState.photoInputs;

    return Scaffold(
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CustomStatusBar(),
            const SizedBox(height: 20),
            Text(
              'Photos',
              style: AppTextStyles.headingLarge.copyWith(color: ColorPalette.peach),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: PhotoGrid(
                  photoInputs: photos,
                  isLoading: _isLoading,
                  context: context,
                  onReorder: (oldIndex, newIndex) async {
                    setState(() {
                      if (oldIndex < photos.length && newIndex <= photos.length) {
                        final item = photos.removeAt(oldIndex);
                        photos.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
                        inputState.photoInputs = [...photos];
                      }
                    });
                    await inputState.savePhotosLocally();
                  },
                  onRemovePhoto: (index) async {
                    setState(() {
                      photos.removeAt(index);
                      inputState.photoInputs = [...photos];
                    });
                    await inputState.savePhotosLocally();
                  },
                  onAddPhoto: () => UserActions().sendPhotoToCrop(context),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: Builder(
        builder: (context) {
          final isLoggedIn = FirebaseAuth.instance.currentUser != null;

          return CustomAppBar(
            buttonText: isLoggedIn ? 'Save' : 'Continue',
            buttonIcon: isLoggedIn ? Icons.save : Icons.arrow_forward,
            onPressed: () async {
              await inputState.savePhotosLocally();

              if (isLoggedIn) {
                if (context.mounted) {
                  Navigator.pushNamed(context, AppRoutes.settings);
                }
              } else {
                if (context.mounted) {
                  Navigator.pushNamed(context, AppRoutes.register);
                }
              }
            },
          );
        },
      ),
    );
  }
}