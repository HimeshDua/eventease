import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/validators/auth_validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _wantsOrganizer = false;
  bool _busy = false;
  String _passwordValue = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_busy) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _nameFocus.unfocus();
      _emailFocus.unfocus();
      _phoneFocus.unfocus();
      _passwordFocus.unfocus();
      _confirmFocus.unfocus();
    });
    final messenger = ScaffoldMessenger.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    try {
      await context.read<AuthService>().register(
        name: _name.text.trim(),
        email: _email.text.trim().toLowerCase(),
        phone: _phone.text.trim(),
        password: _password.text,
        wantsOrganizer: _wantsOrganizer,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Registration successful!')),
      );
      Navigator.pop(context);
      // Registration failures include email-already-in-use, weak password, and network issues.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                enabled: !_busy,
                focusNode: _nameFocus,
                decoration: const InputDecoration(labelText: 'Full Name'),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: AuthValidators.name,
                onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                enabled: !_busy,
                focusNode: _emailFocus,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: AuthValidators.email,
                onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone,
                enabled: !_busy,
                focusNode: _phoneFocus,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.telephoneNumber],
                validator: AuthValidators.phone,
                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 16),
              PasswordFormField(
                controller: _password,
                enabled: !_busy,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: AuthValidators.password,
                onChanged: (v) => setState(() => _passwordValue = v),
                onFieldSubmitted: () => _confirmFocus.requestFocus(),
              ),
              PasswordStrengthBar(password: _passwordValue),
              const SizedBox(height: 16),
              PasswordFormField(
                controller: _confirmPassword,
                label: 'Confirm password',
                enabled: !_busy,
                focusNode: _confirmFocus,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                validator: (v) =>
                    AuthValidators.confirmPassword(v, _password.text),
                onFieldSubmitted: _busy ? null : _register,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('I want to organize events'),
                subtitle: const Text('Requires administrator approval'),
                value: _wantsOrganizer,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _wantsOrganizer = v),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _busy ? null : _register,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
