import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/photogrid.dart';
import '../../functions/photoService.dart';
import '/router/router.dart';
import '../../providers/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';

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
      final photoPaths = await inputState.fetchInputFromLocal('photos');
      if (photoPaths != null && photoPaths is List) {
        inputState.photoInputs.clear();
        for (String path in photoPaths) {
          if (path.startsWith('data:')) {
            final base64String = path.split(',')[1];
            final bytes = base64Decode(base64String);
            inputState.photoInputs.add(InputPhoto(croppedBytes: bytes));
          } else if (path.startsWith('http://') || path.startsWith('https://')) {
            // Firebase Storage URL or other network URL
            inputState.photoInputs.add(InputPhoto(networkUrl: path));
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
    return Consumer<InputState>(
      builder: (context, inputState, child) {
        final inputState = Provider.of<InputState>(context, listen: false);
        final photos = inputState.photoInputs;

        bool isFormComplete() {
          return photos.length >= 1;
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const CustomStatusBar(),
                const SizedBox(height: 20),
                Text(
                  'Upload 4 Photos of Yourself',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: ColorPalette.peach
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: PhotoGrid(
                      photoInputs: photos,
                      isLoading: _isLoading,
                      context: context,
                      maxPhotos: 4,
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
                        await PhotoService.removePhoto(context, index);
                        setState(() {});
                      },
                      onAddPhoto: () async {
                        await PhotoService.pickAndEditPhoto(context);
                        setState(() {});
                      },
                      onEditPhoto: (index) async {
                        await PhotoService.editExistingPhoto(context, index);
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          bottomNavigationBar: Builder(
            builder: (context) {
              final isLoggedIn = FirebaseAuth.instance.currentUser != null;
              bool isComplete = isFormComplete();

              return CustomAppBar(
                buttonText: isLoggedIn ? 'Save' : 'Continue',
                buttonIcon: isLoggedIn ? Icons.save : Icons.arrow_forward,
                isEnabled: isComplete,

                onPressed: () async {
                  if (isLoggedIn) {
                    setState(() => _isLoading = true);
                    
                    try {
                      // Get local photo data (base64 strings or file paths)
                      final localPhotos = await inputState.fetchInputFromLocal('photos') ?? [];
                      
                      if (localPhotos.isNotEmpty) {
                        final userId = FirebaseAuth.instance.currentUser!.uid;
                        
                        // Upload to Storage and get URLs
                        final photoUrls = await inputState.uploadPhotosToStorage(localPhotos, userId);
                        
                        // Save URLs to Firestore
                        await inputState.saveInputToRemoteThenLocal({'photos': photoUrls});
                      }
                      
                      if (context.mounted) {
                        Navigator.pushNamed(context, AppRoutes.settings);
                      }
                    } catch (e) {
                      print('❌ Failed to upload photos: $e');
                      // Show error to user
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save photos. Please try again.')),
                        );
                      }
                    } finally {
                      setState(() => _isLoading = false);
                    }
                  } else {
                    await inputState.savePhotosLocally();
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
    );
  }
}