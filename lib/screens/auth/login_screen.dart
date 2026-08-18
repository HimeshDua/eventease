import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators/auth_validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  final _emailFocus = FocusNode();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _passwordFocus.unfocus();
      _emailFocus.unfocus();
    });
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await context.read<AuthService>().login(
        _email.text.trim().toLowerCase(),
        _password.text,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Login successful!')));
    // Auth failures such as invalid credentials, network issues, or too-many-requests.
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(friendlyError(e)),
            backgroundColor: colorScheme.errorContainer,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openForgotPasswordDialog() async {
    final auth = context.read<AuthService>();
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final emailCtrl = TextEditingController(text: _email.text.trim());
    final formKey = GlobalKey<FormState>();
    bool sending = false;
    bool sent = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Reset password'),
          content: sent
              ? const Text('Password reset email sent. Please check your inbox.')
              : Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Enter your email and we'll send you a reset link.",
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailCtrl,
                        enabled: !sending,
                        autofocus: true,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: AuthValidators.email,
                      ),
                    ],
                  ),
                ),
          actions: [
            if (!sent)
              TextButton(
                onPressed: sending ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (sent) {
                        Navigator.pop(dialogContext);
                        return;
                      }
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => sending = true);
                      try {
                        await auth.resetPassword(
                          emailCtrl.text.trim().toLowerCase(),
                        );
                        setDialogState(() {
                          sending = false;
                          sent = true;
                        });
                      // Reset errors include unknown email and network failures.
                      } catch (error) {
                        setDialogState(() => sending = false);
                        if (dialogContext.mounted) {
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(friendlyError(error)),
                              backgroundColor: colorScheme.errorContainer,
                            ),
                          );
                        }
                      }
                    },
              child: sending
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(sent ? 'Done' : 'Send reset link'),
            ),
          ],
        ),
      ),
    );
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_available,
                  size: 72,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'EventEase',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Text('Smart Event Discovery & Management'),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _email,
                  enabled: !_busy,
                  focusNode: _emailFocus,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  validator: AuthValidators.email,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 16),
                PasswordFormField(
                  controller: _password,
                  enabled: !_busy,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: _busy ? null : _login,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Password is required' : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _busy ? null : _openForgotPasswordDialog,
                    child: const Text('Forgot Password?'),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy ? null : _login,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        ),
                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
