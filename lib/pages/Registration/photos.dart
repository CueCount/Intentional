import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/photogrid.dart';
import '/router/router.dart';
import '../../functions/functions_photo.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PhotoUploadPage extends StatefulWidget {
  const PhotoUploadPage({Key? key}) : super(key: key);
  @override
  State<PhotoUploadPage> createState() => _PhotoUploadPageState();
}

class _PhotoUploadPageState extends State<PhotoUploadPage> {
  List<String> _photoUrls = [];
  bool _isLoading = false;
  late PhotoUploadHelper _photoHelper;

  @override
  void initState() {
    super.initState();
    _photoHelper = PhotoUploadHelper(
      context: context,
      onLoadingChanged: (isLoading) {
        setState(() => _isLoading = isLoading);
      },
      onPhotosUpdated: (photos) {
        setState(() {
          _photoUrls = List<String>.from(photos);
        });
      },
      photoUrls: _photoUrls,
    );
    _photoHelper.fetchExistingPhotos();
  }

  @override
  Widget build(BuildContext context) {
    print('Building with photoUrls: $_photoUrls');
    return Scaffold(
      endDrawer: CustomDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Photos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
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
                  onAddPhoto: () => _photoHelper.pickAndUploadImage(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        route: AppRoutes.prompts,
        inputValues: {'photos': _photoUrls},
      ),
    );
  }
}