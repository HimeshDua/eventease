import 'package:firebase_auth/firebase_auth.dart';

/// Shared, user-facing fallback shown when an error cannot be translated into a
/// friendlier message.
///
/// This constant is the last-resort return value of [friendlyError] and is also
/// used as the fallback for Firebase exceptions whose [FirebaseException.message]
/// is null. Defining it once guarantees every caller surfaces identical wording.
const String friendlyErrorFallback = 'Something went wrong. Please try again.';

/// Translates a thrown error into a short, user-facing message suitable for
/// display in a `SnackBar`, dialog, or any other non-technical UI.
///
/// Centralizing the translation keeps error wording consistent across the app and
/// ensures users never see raw stack traces or internal exception names
/// (SRS 1.6.1 â€” friendly error messaging). Screens and repositories should call
/// `friendlyError(e)` inside a `catch` block instead of surfacing `e` directly:
///
/// ```dart
/// try {
///   await repository.doThing();
/// } catch (e) {
///   showSnack(context, friendlyError(e));
/// }
/// ```
///
/// The type checks are deliberately ordered so that more specific subtypes are
/// matched before their supertypes:
///
/// 1. [FirebaseAuthException] â€” authentication failures. Checked *before*
///    [FirebaseException] because `FirebaseAuthException extends FirebaseException`;
///    matching it second would swallow auth-specific codes such as
///    `wrong-password` and `email-already-in-use`. Common situations: invalid
///    credentials on login, an already-in-use email at registration, weak
///    passwords, `user-disabled` accounts, and `too-many-requests` after
///    repeated failed sign-in attempts.
/// 2. [FirebaseException] â€” Firestore reads/writes, Firebase Storage uploads and
///    deletes, and other service failures. Common situations:
///    `permission-denied` (a security rule or role guard rejecting the user),
///    `unavailable` during backend maintenance, `deadline-exceeded` under poor
///    connectivity, and `resource-exhausted` for quota hits.
/// 3. [StateError] â€” repository business-rule violations. Repositories throw these
///    with a message already written to be human-readable (e.g. `'Event not found.'`,
///    `'This event is full.'`), so the message is returned as-is.
/// 4. [Exception] â€” plain `Exception('readable message')` objects thrown by
///    services and repositories (including the existing `StorageService` wrapper
///    pattern). The `Exception: ` prefix produced by [Object.toString] is stripped
///    so only the authored message is shown.
/// 5. Anything else â€” returns [friendlyErrorFallback].
String friendlyError(Object e) {
  // Auth errors must be tested first: FirebaseAuthException extends
  // FirebaseException, so a generic Firebase check would otherwise swallow them.
  if (e is FirebaseAuthException) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'A network connection is required. Please try again.';
      case 'requires-recent-login':
        return 'Please sign in again before changing your password.';
      case 'user-disabled':
        return 'Your account is unavailable. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? friendlyErrorFallback;
    }
  }

  // Firestore / Storage / Functions errors.
  if (e is FirebaseException) {
    switch (e.code) {
      case 'permission-denied':
        return 'You do not have permission to do that.';
      case 'unavailable':
        return 'The service is temporarily unavailable. Please try again.';
      case 'deadline-exceeded':
        return 'The request timed out. Please try again.';
      case 'resource-exhausted':
        return 'Too many requests. Please try again in a moment.';
      case 'cancelled':
        return 'The operation was cancelled.';
      case 'unauthenticated':
        return 'Please sign in to continue.';
      case 'not-found':
        return 'The requested item could not be found.';
      default:
        return e.message ?? friendlyErrorFallback;
    }
  }

  // Repository business-rule violations (message is already human-readable).
  if (e is StateError) {
    return e.message;
  }

  // Wrapped service/repo errors: strip the 'Exception: ' prefix from toString().
  if (e is Exception) {
    final message = e.toString().replaceFirst('Exception: ', '');
    return message.isEmpty ? friendlyErrorFallback : message;
  }

  // Unknown error type â€” last resort.
  return friendlyErrorFallback;
}