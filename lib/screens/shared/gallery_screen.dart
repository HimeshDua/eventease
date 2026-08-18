import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gallery_item.dart';
import '../../repositories/gallery_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';

/// Full gallery grid for a completed event (SRS 1.6.18).
class GalleryScreen extends StatefulWidget {
  final String eventId;
  const GalleryScreen({super.key, required this.eventId});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    final gallery = context.read<GalleryRepository>();
    final user = context.read<AuthService>().currentUser;
    final canDelete = user != null && user.role == 'admin';
    return Scaffold(
      appBar: AppBar(title: const Text('Event gallery')),
      body: StreamBuilder<List<GalleryItem>>(
        stream: gallery.byEvent(widget.eventId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const ErrorView('Could not load the gallery.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final items = snapshot.data ?? const <GalleryItem>[];
          if (items.isEmpty) {
            return const EmptyView(
              'No gallery photos yet.',
              icon: Icons.photo_outlined,
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isOwner = user != null && user.id == item.uploadedBy;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => _openFullScreen(context, item),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (c, u) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (c, u, e) => Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      if (item.caption != null && item.caption!.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            color: Colors.black54,
                            child: Text(
                              item.caption!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      if (canDelete || isOwner)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            onPressed: () => _deleteGalleryItem(context, item),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteGalleryItem(
    BuildContext context,
    GalleryItem item,
  ) async {
    final gallery = context.read<GalleryRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await confirm(
      context,
      'Delete photo?',
      'This will permanently remove this photo from the gallery.',
    );
    if (!confirmed) return;
    try {
      await gallery.delete(item);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Photo deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AuthService.friendlyError(error)),
          backgroundColor: colorScheme.errorContainer,
        ),
      );
    }
  }

  void _openFullScreen(BuildContext context, GalleryItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(item.caption ?? 'Photo'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                fit: BoxFit.contain,
                errorWidget: (c, u, e) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
