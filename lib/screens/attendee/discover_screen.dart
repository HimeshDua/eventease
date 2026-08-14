import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/event.dart';
import '../../repositories/event_repository.dart';
import '../../widgets/common.dart';
import 'event_details_screen.dart';

/// Event discovery and filtering (SRS 1.6.3, 1.6.4).
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  final _locationController = TextEditingController();
  String _query = '';
  String? _category;
  DateTime? _selectedDate;
  String? _location;
  bool _onlyAvailable = false;

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Filter by event date',
    );
    if (picked == null) return;
    setState(() => _selectedDate = picked);
  }

  void _clearFilters() {
    _searchController.clear();
    _locationController.clear();
    setState(() {
      _query = '';
      _category = null;
      _selectedDate = null;
      _location = null;
      _onlyAvailable = false;
    });
  }

  bool get _hasActiveFilters =>
      _query.trim().isNotEmpty ||
      (_category?.isNotEmpty ?? false) ||
      _selectedDate != null ||
      (_location?.trim().isNotEmpty ?? false) ||
      _onlyAvailable;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<EventRepository>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SearchBar(
            controller: _searchController,
            hintText: 'Search events',
            leading: const Icon(Icons.search),
            trailing: [
              if (_query.trim().isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  icon: const Icon(Icons.close),
                ),
            ],
            onSubmitted: (value) => setState(() => _query = value),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (final category in EventCategories.all)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(category),
                    selected: _category == category,
                    onSelected: (selected) => setState(() {
                      _category = selected ? category : null;
                    }),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.place_outlined),
                    isDense: true,
                  ),
                  onSubmitted: (value) =>
                      setState(() => _location = value.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Filter by date',
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              const SizedBox(width: 8),
              FilterChip(
                avatar: const Icon(Icons.event_seat_outlined),
                label: const Text('Available'),
                selected: _onlyAvailable,
                onSelected: (value) => setState(() => _onlyAvailable = value),
              ),
            ],
          ),
        ),
        if (_hasActiveFilters)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton.icon(
                onPressed: _clearFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ),
          ),
        Expanded(
          child: StreamBuilder<List<Event>>(
            stream: repo.approvedUpcoming(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const ErrorView(
                  'We could not load events. Please try again.',
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              final events = snapshot.data ?? const <Event>[];
              if (events.isEmpty) {
                return const EmptyView(
                  'No upcoming events yet. Check back soon.',
                  icon: Icons.event_busy_outlined,
                );
              }
              final matches = EventRepository.filter(
                events,
                query: _query,
                category: _category,
                date: _selectedDate,
                location: _location,
                onlyAvailable: _onlyAvailable,
              );
              if (matches.isEmpty) {
                return const EmptyView(
                  'No events match your filters. Try clearing or changing them.',
                  icon: Icons.search_off_outlined,
                );
              }
              final sorted = [...matches]
                ..sort((a, b) => a.startTime.compareTo(b.startTime));
              return ListView.builder(
                padding: const EdgeInsets.only(top: 4, bottom: 16),
                itemCount: sorted.length,
                itemBuilder: (context, index) {
                  final event = sorted[index];
                  return EventCard(
                    event: event,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailsScreen(eventId: event.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
