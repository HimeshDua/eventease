import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/screens/auth/auth_widgets.dart';

void main() {
  testWidgets(
    'PasswordFormField: busy toggles off/on/off while focused keeps field editable',
    (WidgetTester tester) async {
      final controller = TextEditingController(text: 'secret');
      final focusNode = FocusNode();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _Host(focusNode: focusNode, controller: controller),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(PasswordFormField));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(PasswordFormField));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      await tester.tap(find.text('Login'));
      await tester.pump(); // _login sets busy=true and UNFOCUSES the field
      // During the busy window the field is unfocused (never disabled-while-focused).
      expect(focusNode.hasFocus, isFalse,
          reason: 'password field must be unfocused while busy to avoid '
              'the disabled-while-focused sticky-keyboard state');
      await tester.pump(const Duration(milliseconds: 30)); // async resolves -> error
      await tester.pumpAndSettle(); // SnackBar + re-enable

      expect(find.text('Invalid credentials'), findsOneWidget);

      final tf = tester.widget<TextFormField>(find.descendant(
        of: find.byType(PasswordFormField),
        matching: find.byType(TextFormField),
      ));
      expect(tf.enabled, isTrue);

      final ed = find
          .descendant(
              of: find.byType(PasswordFormField),
              matching: find.byType(EditableText))
          .evaluate()
          .single
          .widget as EditableText;
      expect(ed.readOnly, isFalse);
      expect(ed.focusNode.canRequestFocus, isTrue);

      await tester.tap(find.byType(PasswordFormField));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus,
          isTrue, reason: 'field must be focusable after error');

      await tester.enterText(find.byType(PasswordFormField), 'corrected123');
      await tester.pumpAndSettle();
      expect(controller.text, 'corrected123');
    },
  );

  testWidgets(
    'PasswordFormField control: editable when not busy',
    (WidgetTester tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: _Host(
              busy: false,
              controller: controller,
              focusNode: FocusNode()),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(PasswordFormField), 'hello');
      await tester.pumpAndSettle();
      expect(controller.text, 'hello');
    },
  );
}

class _Host extends StatefulWidget {
  const _Host(
      {this.busy = false, required this.controller, required this.focusNode});
  final bool busy;
  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool _busy = widget.busy;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PasswordFormField(
            controller: widget.controller,
            enabled: !_busy,
            focusNode: widget.focusNode,
            validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
          ),
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
        ],
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      widget.focusNode.unfocus();
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      throw Exception('invalid-credential');
    } catch (e) {
      if (mounted) {
        messenger
            .showSnackBar(const SnackBar(content: Text('Invalid credentials')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
