import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryItem {
  final String id;
  final String eventId;
  final String uploadedBy;
  final String imageUrl;
  final String? caption;
  final DateTime? uploadedAt;

  const GalleryItem({
    required this.id,
    required this.eventId,
    required this.uploadedBy,
    required this.imageUrl,
    this.caption,
    this.uploadedAt,
  });

  factory GalleryItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return GalleryItem(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'],
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'eventId': eventId,
        'uploadedBy': uploadedBy,
        'imageUrl': imageUrl,
        'caption': caption,
        'uploadedAt': uploadedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(uploadedAt!),
      };
}
