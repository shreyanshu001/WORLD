import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worlds/core/media/image_picker_service.dart';
import 'package:worlds/core/media/system_image_picker_service.dart';

final imagePickerServiceProvider = Provider<ImagePickerService>(
  (ref) => SystemImagePickerService(),
);
