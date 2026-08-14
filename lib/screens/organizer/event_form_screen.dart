import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../models/event.dart';
import '../../repositories/event_repository.dart';
import '../../services/auth_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/common.dart';
import '../../widgets/location_picker.dart';

/// Create or edit an event (SRS 1.6.11). New events start as pending.
class EventFormScreen extends StatefulWidget {
  final String? eventId;
  const EventFormScreen({super.key, this.eventId});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  final _rules = TextEditingController();
  final _contactInfo = TextEditingController();

  String _category = EventCategories.all.first;
  DateTime? _startTime;
  DateTime? _endTime;
  double _latitude = 0;
  double _longitude = 0;
  String? _imageUrl;
  XFile? _pendingImage;
  bool _busy = false;
  bool _loaded = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _capacity.dispose();
    _rules.dispose();
    _contactInfo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final events = context.read<EventRepository>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.eventId == null ? 'Create Event' : 'Edit Event'),
      ),
      body: StreamBuilder<Event>(
        stream: widget.eventId == null
            ? Stream<Event>.value(_placeholderEvent())
            : events.watch(widget.eventId!),
        builder: (context, snapshot) {
          if (widget.eventId != null) {
            if (snapshot.hasError) {
              return const ErrorView('Could not load this event.');
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingView();
            }
          }
          final event = snapshot.data;
          if (event != null && !_loaded) {
            _title.text = event.title;
            _description.text = event.description;
            _location.text = event.location;
            _capacity.text = event.maxParticipants.toString();
            _rules.text = event.rules;
            _contactInfo.text = event.contactInfo;
            _category = event.category;
            _startTime = event.startTime;
            _endTime = event.endTime;
            _latitude = event.latitude;
            _longitude = event.longitude;
            _imageUrl = event.imageUrl;
            _loaded = true;
          }
          if (event != null && event.hasStarted) {
            return const EmptyView(
              'This event has already started and cannot be edited.',
              icon: Icons.lock_outline,
            );
          }
          return _buildForm(event);
        },
      ),
    );
  }

  Event _placeholderEvent({String id = ''}) => Event(
    id: id,
    organizerId: context.read<AuthService>().currentUser?.id ?? '',
    title: '',
    description: '',
    category: EventCategories.all.first,
    location: '',
    rules: '',
    contactInfo: '',
    startTime: DateTime.now().add(const Duration(days: 1)),
    endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
    maxParticipants: 0,
    status: EventStatus.pending,
  );

  Widget _buildForm(Event? event) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Event title *'),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Title is required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _description,
            decoration: const InputDecoration(
              labelText: 'Description *',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Description is required'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category *'),
            items: [
              for (final category in EventCategories.all)
                DropdownMenuItem(value: category, child: Text(category)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateTimeField(
                  label: 'Start time *',
                  value: _startTime,
                  onTap: () => _pickStartTime(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DateTimeField(
                  label: 'End time *',
                  value: _endTime,
                  onTap: () => _pickEndTime(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _capacity,
            decoration: const InputDecoration(labelText: 'Max participants *'),
            keyboardType: TextInputType.number,
            validator: (v) {
              final value = int.tryParse(v ?? '');
              if (value == null || value <= 0) {
                return 'Enter a positive number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _location,
            decoration: const InputDecoration(
              labelText: 'Location / address *',
              helperText: 'Enter the readable venue address',
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Location is required' : null,
          ),
          const SizedBox(height: 16),
          LocationPicker(
            latitude: _latitude,
            longitude: _longitude,
            onLatitudeChanged: (value) => _latitude = value,
            onLongitudeChanged: (value) => _longitude = value,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rules,
            decoration: const InputDecoration(
              labelText: 'Rules',
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactInfo,
            decoration: const InputDecoration(labelText: 'Contact info'),
          ),
          const SizedBox(height: 16),
          _CoverImagePicker(
            imageUrl: _imageUrl,
            pendingImage: _pendingImage,
            onPick: (file) => setState(() => _pendingImage = file),
            onRemove: () => setState(() {
              _pendingImage = null;
              _imageUrl = null;
            }),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.eventId == null ? 'Create event' : 'Save changes',
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickStartTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Event start date',
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      helpText: 'Event start time',
    );
    if (time == null) return;
    setState(() {
      _startTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEndTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: _startTime ?? now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Event end date',
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _endTime ?? now.add(const Duration(hours: 2)),
      ),
      helpText: 'Event end time',
    );
    if (time == null) return;
    setState(() {
      _endTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null || _endTime == null) {
      showSnack(context, 'Please choose start and end times.', error: true);
      return;
    }
    if (!_endTime!.isAfter(_startTime!)) {
      showSnack(context, 'End time must be after start time.', error: true);
      return;
    }
    if (_latitude == 0 && _longitude == 0) {
      showSnack(
        context,
        'Please set the venue location on the map.',
        error: true,
      );
      return;
    }

    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      showSnack(context, 'Please sign in to create events.', error: true);
      return;
    }

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final events = context.read<EventRepository>();
      final storage = context.read<StorageService>();

      final eventId = widget.eventId ?? events.newId();

      // Upload cover image first so the event doc references the final URL.
      if (_pendingImage != null) {
        _imageUrl = await storage.uploadImage(
          _pendingImage!,
          'events/${user.id}/$eventId/cover.jpg',
        );
      }

      final event = Event(
        id: eventId,
        organizerId: user.id,
        title: _title.text.trim(),
        description: _description.text.trim(),
        category: _category,
        location: _location.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        rules: _rules.text.trim(),
        contactInfo: _contactInfo.text.trim(),
        startTime: _startTime!,
        endTime: _endTime!,
        maxParticipants: int.parse(_capacity.text.trim()),
        status: EventStatus.pending,
        imageUrl: _imageUrl,
      );

      if (widget.eventId == null) {
        await events.create(eventId, event);
      } else {
        await events.updateOwned(eventId, {
          'title': event.title,
          'description': event.description,
          'category': event.category,
          'location': event.location,
          'latitude': event.latitude,
          'longitude': event.longitude,
          'rules': event.rules,
          'contactInfo': event.contactInfo,
          'startTime': event.startTime,
          'endTime': event.endTime,
          'maxParticipants': event.maxParticipants,
          if (_imageUrl != null) 'imageUrl': _imageUrl,
        });
      }

      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Event saved. It will be reviewed by an administrator.',
          ),
        ),
      );
      navigator.pop();
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('$error'),
          backgroundColor: Theme.of(context).colorScheme.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _DateTimeField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _DateTimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          value == null ? 'Pick' : formatEventDate(value!),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _CoverImagePicker extends StatelessWidget {
  final String? imageUrl;
  final XFile? pendingImage;
  final ValueChanged<XFile> onPick;
  final VoidCallback onRemove;

  const _CoverImagePicker({
    required this.imageUrl,
    required this.pendingImage,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cover image', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        if (pendingImage == null && (imageUrl == null || imageUrl!.isEmpty))
          OutlinedButton.icon(
            onPressed: () => _pick(context),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Choose image'),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.image_outlined, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Image selected')),
                  TextButton(
                    onPressed: () => _pick(context),
                    child: const Text('Replace'),
                  ),
                  IconButton(
                    tooltip: 'Remove image',
                    onPressed: onRemove,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (file != null) onPick(file);
  }
}
