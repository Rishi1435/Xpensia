import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xpensia/data/theme_provider.dart';
import 'package:xpensia/services/biometric_service.dart';

class BiometricWrapper extends StatefulWidget {
  final Widget child;
  const BiometricWrapper({super.key, required this.child});

  @override
  State<BiometricWrapper> createState() => _BiometricWrapperState();
}

class _BiometricWrapperState extends State<BiometricWrapper> {
  bool _isAuthenticated = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final themeProvider = context.read<ThemeProvider>();

    // If biometric is NOT enabled, we are "authenticated" by default
    if (!themeProvider.isBiometricEnabled) {
      if (mounted) {
        setState(() {
          _isAuthenticated = true;
          _isChecking = false;
        });
      }
      return;
    }

    // Otherwise, try to authenticate
    await _triggerAuth();
  }

  Future<void> _triggerAuth() async {
    final bioService = BiometricService();
    final canCheck = await bioService.isAvailable;

    if (!canCheck) {
      // Hardware not available, fallback to unlocked (or password, but for now unlocked)
      if (mounted) {
        setState(() {
          _isAuthenticated =
              true; // Fail open if no hardware, or fail close? Fail open is safer for MVP.
          _isChecking = false;
        });
      }
      return;
    }

    final success = await bioService.authenticate();
    if (mounted) {
      setState(() {
        _isAuthenticated = success;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Show nothing or a loading spinner while checking preference/hardware
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      return widget.child;
    }

    // Locked UI
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 20),
            const Text(
              "App Locked",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("Please authenticate to continue"),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _triggerAuth,
              icon: const Icon(Icons.fingerprint),
              label: const Text("Unlock"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
