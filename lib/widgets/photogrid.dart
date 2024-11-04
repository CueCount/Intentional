import 'package:flutter/material.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';


class PhotoGrid extends StatelessWidget {
  final List<String> photoUrls;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(int index) onRemovePhoto;
  final VoidCallback onAddPhoto;
  final BuildContext context;
  final bool isLoading;

  const PhotoGrid({
    Key? key,
    required this.photoUrls,
    required this.onReorder,
    required this.onRemovePhoto,
    required this.onAddPhoto,
    required this.context, 
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ReorderableGridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: photoUrls.length + 1,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        if (index == photoUrls.length) {
          return _buildAddPhotoTile();
        }
        if (index >= photoUrls.length) {
          print('Attempted to access invalid index $index');
        }
        return _buildPhotoTile(index);
      },
    );
  }

  Widget _buildAddPhotoTile() {
    return Container(
      key: const Key('add_photo'),
      child: InkWell(
        onTap: onAddPhoto,
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate, size: 40),
            SizedBox(height: 8),
            Text('Add Photo'),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoTile(int index) {
    return Container(
      key: Key('photo_$index'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: Colors.grey[100],
              child: FutureBuilder(
                future: precacheImage(NetworkImage(photoUrls[index]), context),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    print('Precache error: ${snapshot.error}');
                  }
                  return Image.network(
                    photoUrls[index],
                    fit: BoxFit.cover,
                    // Force image reload by adding timestamp
                    headers: {
                      'Cache-Control': 'no-cache',
                      'Pragma': 'no-cache',
                      'Expires': '0',
                    },
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: () => onRemovePhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.drag_handle,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}