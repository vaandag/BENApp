import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class MediaService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> takePhoto() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 78,
    );

    if (picked == null) {
      return null;
    }

    return _persistPickedFile(picked);
  }

  Future<File?> pickPhotoFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 78,
    );

    if (picked == null) {
      return null;
    }

    return _persistPickedFile(picked);
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

    return _persistPickedFile(picked);
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

    return _persistPickedFile(picked);
  }

  Future<File> _persistPickedFile(XFile picked) async {
    final source = File(picked.path);
    if (!await source.exists()) {
      throw const FileSystemException('Seçilen medya dosyası bulunamadı.');
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory('${documents.path}/ben_media');
    await directory.create(recursive: true);

    final extension = picked.path.contains('.')
        ? picked.path.split('.').last.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')
        : '';
    final suffix = extension.isEmpty ? '' : '.$extension';
    final destination = File(
      '${directory.path}/media_${DateTime.now().microsecondsSinceEpoch}$suffix',
    );
    return source.copy(destination.path);
  }
}