import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class ImageUtils {
  static Future<String?> convertImageToBase64(File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
        print('⚠ Image file does not exist.');
        return null;
      }
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      print('✅ Converted image to base64 (length: ${base64String.length})');
      return base64String;
    } catch (e) {
      print('❌ Error converting image to base64: $e');
      return null;
    }
  }

  static Future<File?> pickImage(ImageSource source, {int quality = 80}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source, imageQuality: quality);
      if (pickedFile != null) {
        print('✅ Image picked: ${pickedFile.path}');
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image: $e');
      return null;
    }
  }
}