import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerDialog extends StatelessWidget {
  final ImagePicker _picker = ImagePicker();

  // Function to open camera
  Future<void> _openCamera(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // Handle the selected image file
      print("Camera image path: ${image.path}");
    }
    Navigator.pop(context);
  }

  // Function to open gallery
  Future<void> _openGallery(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // Handle the selected image file
      print("Gallery image path: ${image.path}");
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.camera),
          title: const Text('Camera', textAlign: TextAlign.start),
          onTap: () {
            _openCamera(context);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.photo),
          title: const Text('Photo', textAlign: TextAlign.start),
          onTap: () {
            _openGallery(context);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.cancel),
          title: const Text('Cancel', textAlign: TextAlign.start),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
