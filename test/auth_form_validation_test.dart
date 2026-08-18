import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventease/core/validators/auth_validators.dart';

/// Builds a small auth-shaped form wired to [AuthValidators] so the form
/// validation contract can be exercised without any Firebase dependency.
Future<GlobalKey<FormState>> pumpAuthForm(
  WidgetTester tester, {
  String email = '',
  String password = '',
  String confirm = '',
}) async {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController(text: email);
  final passwordController = TextEditingController(text: password);
  final confirmController = TextEditingController(text: confirm);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: AuthValidators.email,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: AuthValidators.password,
              ),
              TextFormField(
                controller: confirmController,
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
                obscureText: true,
                validator: (v) =>
                    AuthValidators.confirmPassword(v, password),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return formKey;
}

void main() {
  testWidgets('empty form shows required validation errors',
      (WidgetTester tester) async {
    final formKey = await pumpAuthForm(tester);
    expect(formKey.currentState, isNotNull);
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  testWidgets('valid input passes all validators', (WidgetTester tester) async {
    final formKey = await pumpAuthForm(
      tester,
      email: 'user@eventease.demo',
      password: 'Abcdef1!',
      confirm: 'Abcdef1!',
    );
    expect(formKey.currentState!.validate(), isTrue);
  });

  testWidgets('mismatched passwords are rejected', (WidgetTester tester) async {
    final formKey = await pumpAuthForm(
      tester,
      email: 'user@eventease.demo',
      password: 'Abcdef1!',
      confirm: 'Different1!',
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('invalid email is rejected', (WidgetTester tester) async {
    final formKey = await pumpAuthForm(tester, email: 'not-an-email');
    expect(formKey.currentState!.validate(), isFalse);
  });

  testWidgets('weak password is rejected', (WidgetTester tester) async {
    final formKey = await pumpAuthForm(
      tester,
      email: 'user@eventease.demo',
      password: 'weak',
      confirm: 'weak',
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });
}
