/// App-wide constants: roles, statuses, categories, collection names.
class Roles {
  static const attendee = 'attendee';
  static const organizer = 'organizer';
  static const admin = 'admin';
}

class EventStatus {
  static const pending = 'pending'; // awaiting admin approval
  static const approved = 'approved';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';
  static const completed = 'completed';
}

class RegistrationStatus {
  static const registered = 'registered';
  static const cancelled = 'cancelled';
  static const attended = 'attended';
}

class EventCategories {
  static const all = [
    'Technology',
    'Education',
    'Sports',
    'Music',
    'Business',
    'Workshop',
    'Conference',
    'Community',
  ];
}

/// Firestore collection names — always use these, never raw strings.
class Col {
  static const users = 'users';
  static const events = 'events';
  static const registrations = 'registrations';
  static const attendance = 'attendance';
  static const feedback = 'feedback';
  static const favorites = 'favorites';
  static const notifications = 'notifications';
  static const gallery = 'gallery';
  static const contactMessages = 'contactMessages';
}
