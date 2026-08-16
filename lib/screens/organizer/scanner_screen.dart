import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../repositories/registration_repository.dart';
import '../../widgets/common.dart';

/// QR check-in scanner with guarded states (SRS 1.6.10).
class ScannerScreen extends StatefulWidget {
  final String eventId;
  const ScannerScreen({super.key, required this.eventId});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _scanner = MobileScannerController();
  bool _scanLocked = false;
  String? _scanResult;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_scanLocked) return;
    _scanLocked = true;
    final code = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;
    if (code == null) {
      _scanLocked = false;
      _showResult(
        'Could not read the QR code. Please try again.',
        isError: true,
      );
      return;
    }
    try {
      final registration = await context
          .read<RegistrationRepository>()
          .checkInByQr(code, widget.eventId);
      _showResult(
        'Check-in successful for registration ${registration.id}.',
        isError: false,
      );
    // check-in failed (invalid QR, wrong event, already checked in, cancelled pass, network error)
    } catch (error) {
      _showResult(friendlyError(error), isError: true);
    }
  }

  void _showResult(String message, {required bool isError}) {
    if (!mounted) return;
    setState(() {
      _scanResult = message;
    });
  }

  void _reset() {
    setState(() {
      _scanResult = null;
      _scanLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR pass')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: MobileScanner(controller: _scanner, onDetect: _onDetect),
          ),
          const SizedBox(height: 8),
          const Text('Point the camera at the attendee QR pass.'),
          const SizedBox(height: 16),
          if (_scanResult != null)
            Card(
              color: isErrorResult
                  ? colorScheme.errorContainer
                  : colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      isErrorResult
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                    ),
                    const SizedBox(height: 8),
                    Text(_scanResult!, textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: _reset,
                      child: const Text('Scan next'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool get isErrorResult =>
      _scanResult?.startsWith('Check-in successful') != true;
}
