import 'package:flutter/material.dart';

import '../../core/validators/auth_validators.dart';

/// A password TextFormField with a show/hide eye icon. Used by Login,
/// Register (password + confirm), and the change-password dialog so the
/// obscure-toggle behavior and styling are consistent everywhere.
class PasswordFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final FocusNode? focusNode;
  final Iterable<String>? autofillHints;
  final VoidCallback? onFieldSubmitted;

  const PasswordFormField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.enabled = true,
    this.focusNode,
    this.autofillHints = const [AutofillHints.password],
    this.onFieldSubmitted,
  });

  @override
  State<PasswordFormField> createState() => _PasswordFormFieldState();
}

class _PasswordFormFieldState extends State<PasswordFormField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      enabled: widget.enabled,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onFieldSubmitted: widget.onFieldSubmitted == null
          ? null
          : (_) => widget.onFieldSubmitted!(),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(
            _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          ),
          tooltip: _obscure ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
    );
  }
}

/// Visual-only password strength meter driven by [AuthValidators.strength].
/// The actual policy is enforced by the field's validator; this is UX
/// feedback so the user isn't surprised by a rejected password.
///
/// Colors are fixed red/orange/green (a conventional strength-meter palette)
/// but use `.shade400` tones, which read clearly against both light and dark
/// Material Theme Builder surfaces; only the label text uses the theme's
/// `bodySmall` style so typography stays consistent with the rest of the app.
class PasswordStrengthBar extends StatelessWidget {
  final String password;
  const PasswordStrengthBar({super.key, required this.password});

  static const _colors = [
    Colors.red,
    Colors.red,
    Colors.orange,
    Colors.lightGreen,
    Colors.green,
  ];

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();
    final score = AuthValidators.strength(password);
    const labels = ['Weak', 'Weak', 'Fair', 'Good', 'Strong'];
    final color = _colors[score].shade400;
    final trackColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 4,
                minHeight: 6,
                backgroundColor: trackColor,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            labels[score],
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
