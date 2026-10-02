import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:smart_auth/smart_auth.dart';
import 'dart:async';
import '../services/otp_service.dart';
import '../services/sim_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'teacher_dashboard.dart';
import 'student_dashboard.dart';
import 'parent_dashboard.dart';

class OtpScreen extends StatefulWidget {
  final String mobileNumber;
  final UserModel user;
  final String selectedRole;

  const OtpScreen({
    super.key,
    required this.mobileNumber,
    required this.user,
    required this.selectedRole,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  int _countdown = 60;
  Timer? _timer;
  final _smartAuth = SmartAuth.instance;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _sendInitialOtp();
  }

  void _sendInitialOtp() async {
    // Start listening BEFORE sending the SMS to prevent race conditions
    _startSmsRetriever();

    try {
      final String otp = OtpService.generateOtp(widget.mobileNumber);
      final res = await _smartAuth.getAppSignature();
      final appHash = res.data ?? '';

      await SimService.sendSms(
        widget.mobileNumber,
        "<#> Your E-School login code is: $otp\n$appHash"
      );
    } catch (e) {
      debugPrint('Error sending initial SMS: $e');
    }
  }

  void _startSmsRetriever() async {
    final res = await _smartAuth.getSmsWithRetrieverApi();
    if (res.data != null && res.data!.code != null) {
      final code = res.data!.code;
      if (mounted) {
        setState(() {
          _otpController.text = code!;
        });
        // Auto submit
        _verifyOtp();
      }
    } else {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("We couldn't automatically detect your OTP. Please enter it manually.".tr())),
        );
      }
    }
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _smartAuth.removeSmsRetrieverApiListener();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_countdown > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final String otp = OtpService.generateOtp(widget.mobileNumber);
      
      final res = await _smartAuth.getAppSignature();
      final appHash = res.data ?? '';
      
      await SimService.sendSms(
        widget.mobileNumber, 
        "<#> Your E-School login code is: $otp\n$appHash"
      );
      
      _startSmsRetriever(); // Restart listener for the new SMS
      _startCountdown();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent successfully.'.tr()), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      OtpService.verifyOtp(widget.mobileNumber, _otpController.text.trim());
      
      // OTP matched and Firestore is already validated before this screen!
      if (!mounted) return;

      if (widget.user.role.toLowerCase() != widget.selectedRole.toLowerCase()) {
         throw Exception("Role mismatch. You do not have ${widget.selectedRole} privileges.");
      }

      Widget destination;
      switch (widget.user.role.toLowerCase()) {
        case 'teacher':
          destination = const TeacherDashboard();
          break;
        case 'student':
          destination = const StudentDashboard();
          break;
        default:
          destination = const ParentDashboard();
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => destination),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mask number
    String masked = widget.mobileNumber;
    if (masked.length > 4) {
      masked = '******${masked.substring(masked.length - 4)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textDark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              SizedBox(height: 20),
              Icon(Icons.message_outlined, size: 64, color: AppTheme.primary),
              SizedBox(height: 24),
              Text('Enter Verification Code'.tr(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'We sent a 6-digit code to $masked via SMS.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 32),
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '000000'.tr(),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.length != 6 ? 'Enter 6-digit code' : null,
                ),
              ),
              SizedBox(height: 16),
              Text('Note: Please ensure you have allowed SMS permissions. If you have already granted permissions but still haven\'.tr()t received the OTP, please completely close and restart the app.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Verify & Login'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive code? ".tr(), style: TextStyle(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: _countdown == 0 && !_isLoading ? _resendOtp : null,
                    child: Text(
                      _countdown > 0 ? 'Resend in ${_countdown}s' : 'Resend SMS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _countdown == 0 ? AppTheme.primary : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
