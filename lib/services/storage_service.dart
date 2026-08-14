import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Owns Firebase Storage image uploads and deletion.
class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
    : _storage = storage ?? FirebaseStorage.instance;

  /// Uploads an image selected with ImagePicker and returns its download URL.
  Future<String> uploadImage(XFile file, String path) async {
    try {
      final bytes = await file.readAsBytes();
      final reference = _storage.ref().child(path);
      await reference.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await reference.getDownloadURL();
    } on FirebaseException catch (error) {
      throw Exception(_friendlyError(error));
    } catch (_) {
      throw Exception('We could not update the image. Please try again.');
    }
  }

  /// Deletes an object referenced by a Firebase Storage download URL.
  /// A missing object is already in the desired state.
  Future<void> deleteByUrl(String url) async {
    if (url.isEmpty) return;

    try {
      await _storage.refFromURL(url).delete();
    } on FirebaseException catch (error) {
      if (error.code == 'object-not-found') return;
      throw Exception(_friendlyError(error));
    } catch (_) {
      throw Exception('We could not remove the image. Please try again.');
    }
  }

  String _friendlyError(FirebaseException error) {
    switch (error.code) {
      case 'unauthorized':
        return 'You do not have permission to manage this image.';
      case 'canceled':
        return 'The image upload was cancelled.';
      case 'object-not-found':
        return 'The image could not be found.';
      default:
        return 'We could not update the image. Please try again.';
    }
  }
}
