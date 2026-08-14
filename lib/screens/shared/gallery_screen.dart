import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/gallery_item.dart';
import '../../repositories/gallery_repository.dart';
import '../../widgets/common.dart';

/// Full gallery grid for a completed event (SRS 1.6.18).
class GalleryScreen extends StatelessWidget {
  final String eventId;
  const GalleryScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final gallery = context.read<GalleryRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Event gallery')),
      body: StreamBuilder<List<GalleryItem>>(
        stream: gallery.byEvent(eventId),
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
