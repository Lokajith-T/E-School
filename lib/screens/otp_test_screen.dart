
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpTestScreen extends StatefulWidget {
  const OtpTestScreen({super.key});

  @override
  State<OtpTestScreen> createState() => _OtpTestScreenState();
}

class _OtpTestScreenState extends State<OtpTestScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final auth = FirebaseAuth.instance;

  String? verificationId;
  String message = '';
  bool loading = false;

  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty || !phone.startsWith('+')) {
      setState(() => message =
          'Enter your number with country code, e.g. +919876543210');
      return;
    }

    setState(() {
      loading = true;
      message = 'Sending OTP...';
    });

    try {
      await auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),

        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(credential);
            if (!mounted) return;
            setState(() {
              message = 'Phone verified and login successful!';
              loading = false;
            });
          } on FirebaseAuthException catch (e) {
            if (!mounted) return;
            setState(() {
              message = 'Login failed: ${e.message}';
              loading = false;
            });
          }
        },

        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          setState(() {
            message = 'Error: ${e.message}';
            loading = false;
          });
        },

        codeSent: (String id, int? resendToken) {
          if (!mounted) return;
          setState(() {
            verificationId = id;
            message = 'OTP sent! Enter the code below.';
            loading = false;
          });
        },

        codeAutoRetrievalTimeout: (String id) {
          verificationId = id;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = 'Error: $e';
        loading = false;
      });
    }
  }

  Future<void> verifyOtp() async {
    final id = verificationId;
    final otp = otpController.text.trim();

    if (id == null || otp.length != 6) {
      setState(() => message = 'Enter the 6-digit OTP first.');
      return;
    }

    setState(() {
      loading = true;
      message = 'Verifying OTP...';
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: otp,
      );

      final result = await auth.signInWithCredential(credential);

      if (!mounted) return;
      setState(() {
        message = 'Login successful!\nUID: ${result.user?.uid}';
        loading = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        message = 'Verification failed: ${e.message}';
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase OTP Test'.tr())),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile number'.tr(),
                hintText: '+919876543210'.tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : sendOtp,
                child: Text('Send OTP'.tr()),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Enter 6-digit OTP'.tr(),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    loading || verificationId == null ? null : verifyOtp,
                child: Text('Verify & Login'.tr()),
              ),
            ),
            SizedBox(height: 20),
            if (loading) const CircularProgressIndicator(),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}