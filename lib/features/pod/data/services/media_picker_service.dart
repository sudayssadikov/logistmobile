import 'package:image_picker/image_picker.dart';

class MediaPickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> takePhoto() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<XFile>> pickMultiplePhotos() async {
    try {
      return await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1200,
        imageQuality: 85,
      );
    } catch (_) {
      return [];
    }
  }
}
