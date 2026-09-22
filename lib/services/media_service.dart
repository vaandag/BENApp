import 'dart:io';

import 'package:image_picker/image_picker.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (picked == null) {
      return null;
    }

    return File(picked.path);
  }

  Future<File?> pickPhotoFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (picked == null) {
      return null;
    }

    return File(picked.path);
  }

  Future<File?> recordVideo() async {
    final XFile? picked = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(
        minutes: 5,
      ),
    );

    if (picked == null) {
      return null;
    }

    return File(picked.path);
  }

  Future<File?> pickVideoFromGallery() async {
    final XFile? picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(
        minutes: 5,
      ),
    );

    if (picked == null) {
      return null;
    }

    return File(picked.path);
  }
}