import 'package:worlds/core/media/picked_image.dart';

/// Lets the user choose a photo from the device. Implementations wrap one
/// picker SDK, so no SDK type appears outside `lib/core/media`.
abstract interface class ImagePickerService {
  /// One photo, resized for upload, or null if the user cancelled.
  ///
  /// Throws `AppFailure.imageNotSupported` for anything that is not a JPEG,
  /// PNG or WebP image under [PickedImage.maxBytes].
  Future<PickedImage?> pickPhoto();
}
