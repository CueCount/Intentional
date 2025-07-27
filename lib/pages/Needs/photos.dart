import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/photogrid.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../data/inputState.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../functions/airTrafficControler_service.dart';

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
              const CustomStatusBar(messagesCount: 2,likesCount: 5,),
              const SizedBox(height: 20),
              Text('Photos',style: AppTextStyles.headingLarge.copyWith(color: ColorPalette.peach,),),
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
                  onAddPhoto: () => AirTrafficController().uploadPhoto(context),
                ),
                ),
              ),
            ],
          ),
        
      ),

      bottomNavigationBar: CustomAppBar(
        onPressed: () async {
          final inputData = getSelectedAttributes();
          await AirTrafficController().saveAllInputs(context);
          if (context.mounted) {
            Navigator.pushNamed(context, AppRoutes.subscription, arguments: inputData);
          }
        },
      ),
    );
  }
}