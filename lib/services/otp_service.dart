import 'dart:math';

class OtpService {
  static final Map<String, _OtpData> _otps = {};
  
  static String generateOtp(String mobileNumber) {
    if (_otps.containsKey(mobileNumber)) {
      final existing = _otps[mobileNumber]!;
      // Cooldown of 60 seconds
      if (DateTime.now().difference(existing.createdAt).inSeconds < 60) {
        throw Exception("Please wait before requesting a new OTP.");
      }
    }

    final random = Random.secure();
    final otp = (random.nextInt(900000) + 100000).toString(); // 6 digits
    
    _otps[mobileNumber] = _OtpData(
      otp: otp,
      createdAt: DateTime.now(),
      attempts: 0,
    );
    
    return otp;
  }

  static void verifyOtp(String mobileNumber, String enteredOtp) {
    if (!_otps.containsKey(mobileNumber)) {
      throw Exception("No active OTP found. Please request a new one.");
    }
    
    final otpData = _otps[mobileNumber]!;
    
    // Expiry: 5 minutes
    if (DateTime.now().difference(otpData.createdAt).inMinutes > 5) {
      _otps.remove(mobileNumber);
      throw Exception("OTP has expired.");
    }
    
    // Attempts: Max 5
    if (otpData.attempts >= 5) {
      _otps.remove(mobileNumber);
      throw Exception("Too many failed attempts. Please request a new OTP.");
    }
    
    if (otpData.otp != enteredOtp) {
      otpData.attempts++;
      throw Exception("Incorrect OTP.");
    }
    
    // Success, invalidate OTP
    _otps.remove(mobileNumber);
  }
}

class _OtpData {
  final String otp;
  final DateTime createdAt;
  int attempts;

  _OtpData({required this.otp, required this.createdAt, required this.attempts});
}
