import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants.dart';
import '../models/gallery_item.dart';
import '../services/storage_service.dart';

/// Firestore records for gallery images. Media bytes are handled by StorageService.
class GalleryRepository {
  final FirebaseFirestore _db;
  final StorageService _storageService;

  GalleryRepository({
    FirebaseFirestore? firestore,
    StorageService? storageService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storageService = storageService ?? StorageService();

  Stream<List<GalleryItem>> byEvent(String eventId) => _db
      .collection(Col.gallery)
      .where('eventId', isEqualTo: eventId)
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(GalleryItem.fromDoc).toList());

  Future<void> upload(GalleryItem item) =>
      _db.collection(Col.gallery).doc(item.id).set(item.toMap());

  Future<void> delete(GalleryItem item) async {
    await _storageService.deleteByUrl(item.imageUrl);
    await _db.collection(Col.gallery).doc(item.id).delete();
  }
}
