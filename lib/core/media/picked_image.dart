import 'dart:typed_data';

/// Image formats World storage accepts (the bucket and the database check
/// the same three).
enum ImageFormat {
  jpeg('image/jpeg', 'jpg'),
  png('image/png', 'png'),
  webp('image/webp', 'webp');

  const ImageFormat(this.mimeType, this.extension);

  final String mimeType;
  final String extension;

  /// Detects the format from the file's first bytes, never from its name.
  static ImageFormat? detect(Uint8List bytes) {
    bool startsWith(List<int> signature, [int offset = 0]) {
      if (bytes.length < offset + signature.length) return false;
      for (var i = 0; i < signature.length; i++) {
        if (bytes[offset + i] != signature[i]) return false;
      }
      return true;
    }

    if (startsWith(const [0xFF, 0xD8, 0xFF])) return ImageFormat.jpeg;
    if (startsWith(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return ImageFormat.png;
    }
    // "RIFF" .... "WEBP"
    if (startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
        startsWith(const [0x57, 0x45, 0x42, 0x50], 8)) {
      return ImageFormat.webp;
    }
    return null;
  }
}

/// A photo the user chose, already resized and checked.
class PickedImage {
  const PickedImage({required this.bytes, required this.format});

  /// The storage limit, matching the bucket's `file_size_limit`.
  static const maxBytes = 5 * 1024 * 1024;

  final Uint8List bytes;
  final ImageFormat format;
}
