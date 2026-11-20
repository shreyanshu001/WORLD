import 'package:image_picker/image_picker.dart';
import 'package:worlds/core/errors/app_failure.dart';
import 'package:worlds/core/media/image_picker_service.dart';
import 'package:worlds/core/media/picked_image.dart';

/// [ImagePickerService] backed by Android's system photo picker, which
/// needs no storage or media permission. The picker resizes and re-encodes
/// the photo before the app sees it.
class SystemImagePickerService implements ImagePickerService {
  SystemImagePickerService([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  /// Longest side after resizing: sharp on phones, small to upload.
  static const maxDimension = 2048.0;
  static const quality = 85;

  final ImagePicker _picker;

  @override
  Future<PickedImage?> pickPhoto() async {
    final XFile? file;
    try {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: quality,
        requestFullMetadata: false,
      );
    } on Object {
      throw const AppFailure.imageNotSupported();
    }
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final format = ImageFormat.detect(bytes);
    if (format == null || bytes.length > PickedImage.maxBytes) {
      throw const AppFailure.imageNotSupported();
    }
    return PickedImage(bytes: bytes, format: format);
  }
}
