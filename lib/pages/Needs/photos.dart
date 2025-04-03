import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/photogrid.dart';
import 'package:provider/provider.dart';
import '/router/router.dart';
import '../../data/inputState.dart';
import '../../functions/photo_service.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../functions/airTrafficControler_service.dart';

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({Key? key}) : super(key: key);
  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  List<String> _photoUrls = [];
  bool _isLoading = false;
  late PhotoService _photoHelper;
  final _controller = AirTrafficController();

  @override
  void initState() {
    super.initState();
    _photoHelper = PhotoService(
      context: context,
      onLoadingChanged: (isLoading) {
        setState(() => _isLoading = isLoading);
      },
      onPhotosUpdated: (photos) {
        setState(() {
          _photoUrls = List<String>.from(photos);
          final inputState = Provider.of<InputState>(context, listen: false);
          inputState.photoInputs = photos.map((url) => InputPhoto(
            base64Data: '', 
            localUrl: null,
            firestoreUrl: url,
            filename: url.split('/').last,
          )).toList();
        });
      },
      photoUrls: _photoUrls,
    );
    _fetchPhotosForUpload();
  }

  Future<void> _fetchPhotosForUpload() async {
    try {
      final photos = await PhotoService.fetchExistingPhotos(selection: "all");
      _photoHelper.onPhotosUpdated(photos);
    } catch (e) {
      print("Error fetching photos: $e");
    }
  }

  Map<String, dynamic> getSelectedAttributes() {
    final inputState = Provider.of<InputState>(context, listen: false);
    return {
      "Photos": inputState.photoInputs.map((p) => p.toJson()).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    print('Building with photoUrls: $_photoUrls');
    return Scaffold(
      body: Container (
        padding: const EdgeInsets.all(20), // 20px padding on all sides
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
      child: SafeArea(

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const CustomStatusBar(
                messagesCount: 2,
                likesCount: 5,
              ),
            
              const SizedBox(height: 20),
              
              Text(
                'Photos',
                style: AppTextStyles.headingMedium.copyWith(
                  color: ColorPalette.white,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: PhotoGrid(
                  photoUrls: _photoUrls,
                  isLoading: _isLoading,
                  
                  context: context, 
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < _photoUrls.length && newIndex <= _photoUrls.length) {
                        final item = _photoUrls.removeAt(oldIndex);
                        _photoUrls.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
                      }
                    });
                  },
                  onRemovePhoto: (index) => _photoHelper.removePhoto(index),
                  onAddPhoto: () => _controller.uploadPhoto(context),
                ),
              ),
            ],
          ),
        ),
      ),
      /*bottomNavigationBar: CustomAppBar(
        route: AppRoutes.basicInfo,
        inputValues: {'photos': _photoUrls},
      ),*/
      bottomNavigationBar: CustomAppBar(
        onPressed: () async {
          final inputData = getSelectedAttributes();
          await AirTrafficController().addedNeed(context, inputData);
          if (context.mounted) {
            Navigator.pushNamed(context, AppRoutes.basicInfo, arguments: inputData);
          }
        },
      ),
    );
  }
}