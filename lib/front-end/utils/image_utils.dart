import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';

class ImageUtils {
  static Future<String?> convertImageToBase64(File imageFile) async {
    try {
      if (!imageFile.existsSync()) {
        print('⚠ Image file does not exist: ${imageFile.path}');
        return null;
      }

      // Read original image
      final originalBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(originalBytes);
      if (image == null) {
        print('❌ Failed to decode image');
        return null;
      }

      const maxBase64Size = 1000000; // 1MB
      int quality = 80;
      String? base64String;

      // Try compressing until base64 size is < 1MB
      while (quality >= 10) {
        // Compress image
        final compressedBytes = img.encodeJpg(image, quality: quality);
        base64String = base64Encode(compressedBytes);
        final base64Size = base64String.length;

        print('📏 Base64 size at quality $quality: $base64Size bytes');
        if (base64Size <= maxBase64Size) {
          print('✅ Compressed image to base64 (length: $base64Size)');
          return base64String;
        }

        quality -= 10;
        print('🔄 Reducing quality to $quality for compression');
      }

      print('❌ Could not compress image below 1MB');
      return null;
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