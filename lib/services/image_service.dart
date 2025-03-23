// lib/services/image_service.dart

import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ImageService {
  /// Pick an image from the device (gallery by default).
  static Future<File?> pickImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 600, // optional resize
    );
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  /// Upload a file to Firebase Storage, returning the download URL.
  /// [folderName] could be 'restaurantImages' or 'foodImages', etc.
  static Future<String?> uploadImage(File file, String folderName) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('$folderName/$fileName');

      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }
}
