import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../models/gallery_item.dart';
import '../../repositories/gallery_repository.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';

/// Upload a photo to the gallery of an owned completed event (SRS 1.6.18).
class GalleryUploadScreen extends StatefulWidget {
  final String eventId;
  const GalleryUploadScreen({super.key, required this.eventId});

  @override
  State<GalleryUploadScreen> createState() => _GalleryUploadScreenState();
}

class _GalleryUploadScreenState extends State<GalleryUploadScreen> {
  final _caption = TextEditingController();
  XFile? _image;
  bool _busy = false;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file != null) setState(() => _image = file);
  }

  Future<void> _upload() async {
    final user = context.read<AuthService>().currentUser;
    final image = _image;
    if (user == null) return;
    if (image == null) {
      showSnack(context, 'Please choose an image to upload.', error: true);
      return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      final storage = context.read<StorageService>();
      final gallery = context.read<GalleryRepository>();
      final mediaId = const Uuid().v4();
      final url = await storage.uploadImage(
        image,
        'gallery/${widget.eventId}/$mediaId.jpg',
      );
      await gallery.upload(
        GalleryItem(
          id: mediaId,
          eventId: widget.eventId,
          uploadedBy: user.id,
          imageUrl: url,
          caption: _caption.text.trim().isEmpty ? null : _caption.text.trim(),
        ),
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo uploaded to the gallery.')),
      );
      navigator.pop();
    // gallery upload failed (image upload failure, Firestore write denial, network error)
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add gallery photo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_image == null)
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Choose image'),
              )
            else
              Card(
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.file(
                        File(_image!.path),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Expanded(child: Text('Image selected')),
                          TextButton(
                            onPressed: _pickImage,
                            child: const Text('Replace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _caption,
              decoration: const InputDecoration(
                labelText: 'Caption (optional)',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _upload,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Upload photo'),
            ),
          ],
        ),
      ),
    );
  }
}
