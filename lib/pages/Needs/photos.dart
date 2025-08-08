import 'package:flutter/material.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../widgets/photogrid.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../data/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../functions/onboardingService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../functions/userActionsService.dart';

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({Key? key}) : super(key: key);
  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  bool _isLoading = false;

  Map<String, dynamic> getSelectedAttributes() {
    final inputState = Provider.of<InputState>(context, listen: false);
    return {
      "Photos": inputState.photoInputs.map((p) => p.toJson()).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final inputState = Provider.of<InputState>(context); // ✅ Access InputState
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
                style: AppTextStyles.headingLarge.copyWith(color: ColorPalette.peach,),
                ),
              const SizedBox(height: 20),
              Expanded(
                child: Container (
                  padding: const EdgeInsets.all(16),
                  child: PhotoGrid(
                    photoInputs: photos,
                    isLoading: _isLoading,
                    context: context, 
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (oldIndex < photos.length && newIndex <= photos.length) {
                          final item = photos.removeAt(oldIndex);
                          photos.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
                          inputState.photoInputs = [...photos]; // ✅ Update InputState
                        }
                      });
                    },
                    onRemovePhoto: (index) {
                      setState(() {
                        photos.removeAt(index);
                        inputState.photoInputs = [...photos]; // ✅ Update InputState
                      });
                    },
                    onAddPhoto: () => UserActions().sendPhotoToCrop(context),
                  ),
                ),
              ),
            ],
          ),
        ),

        bottomNavigationBar: () {
          return FutureBuilder<bool>(
            future: () async {
              final prefs = await SharedPreferences.getInstance();
              String tempUserId = prefs.getString('current_temp_id') ?? '';
              Map<String, bool> status = await UserActions.readStatus(tempUserId, ['infoIncomplete']);
              return status['infoIncomplete'] ?? true;
            }(),
            builder: (context, snapshot) {
              bool infoIncomplete = snapshot.data ?? true;
              
              return CustomAppBar(
                buttonText: infoIncomplete ? 'Continue' : 'Save',
                buttonIcon: infoIncomplete ? Icons.arrow_forward : Icons.save,
                onPressed: () async {
                  final inputData = getSelectedAttributes();
                  
                  if (infoIncomplete) {
                    await AirTrafficController().saveAccountDataToFirebase(context);
                    if (context.mounted) {
                      Navigator.pushNamed(context, AppRoutes.subscription, arguments: inputData);
                    }
                  } else {
                    await UserActions().savePhotosToFirebase(context);
                    if (context.mounted) {
                      Navigator.pushNamed(context, AppRoutes.settings, arguments: inputData);
                    }
                  }
                },
              );
            },
          );
        }(),
      );
    }
}