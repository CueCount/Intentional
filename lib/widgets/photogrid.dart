import 'package:flutter/material.dart';
import '../providers/inputState.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class PhotoGrid extends StatelessWidget {
  final List<InputPhoto> photoInputs;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(int index) onRemovePhoto;
  final VoidCallback onAddPhoto;
  final Function(int index)? onEditPhoto; // New optional parameter for editing
  final BuildContext context;
  final bool isLoading;
  final int maxPhotos;

  const PhotoGrid({
    Key? key,
    required this.photoInputs,
    required this.onReorder,
    required this.onRemovePhoto,
    required this.onAddPhoto,
    this.onEditPhoto, // Optional edit handler
    required this.context, 
    this.isLoading = false,
    this.maxPhotos = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final itemCount = photoInputs.length < maxPhotos 
        ? photoInputs.length + 1 
        : photoInputs.length;

    return ReorderableGridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75, // Adjusted for better proportions
      ),
      itemCount: itemCount,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        if (index == photoInputs.length && photoInputs.length < maxPhotos) {
          return _buildAddPhotoTile();
        }
        if (index >= photoInputs.length) {
          print('Attempted to access invalid index $index');
          return const SizedBox.shrink(key: ValueKey('empty-invalid'));
        }
        return _buildPhotoTile(index);
      },
    );
  }

  /* = = = = = = = = =
  Add Photo Tile Widget
  = = = = = = = = = */

  Widget _buildAddPhotoTile() {
    return Container(
      key: const Key('add_photo'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 2,
          style: BorderStyle.solid,
        ),
        color: Colors.grey.shade100,
      ),
      child: InkWell(
        onTap: onAddPhoto,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate, 
              size: 48,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'Add Photo',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${photoInputs.length}/$maxPhotos',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* = = = = = = = = =
  Photo Tile Widget
  = = = = = = = = = */

  Widget _buildPhotoTile(int index) {
    final photo = photoInputs[index];
    ImageProvider? imageProvider;

    if (kIsWeb && photo.croppedBytes != null) {
      imageProvider = MemoryImage(photo.croppedBytes!);
    } else if (!kIsWeb && photo.localPath != null && File(photo.localPath!).existsSync()) {
      imageProvider = FileImage(File(photo.localPath!));
    }

    if (imageProvider == null) {
      return const SizedBox.shrink(key: ValueKey('empty-tile'));
    }

    return Container(
      key: Key('photo_$index'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade200,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image(
              image: imageProvider,
              fit: BoxFit.cover,
            ),
          ),
 
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                if (onEditPhoto != null) ...[
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => onEditPhoto!(index),
                      icon: const Icon(Icons.edit, size: 18),
                      color: Colors.black87,
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => onRemovePhoto(index),
                    icon: const Icon(Icons.close, size: 18),
                    color: Colors.red,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
          ),
          
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
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