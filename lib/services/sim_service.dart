import 'package:flutter/services.dart';

class SimService {
  static const MethodChannel _channel = MethodChannel('com.example.eschool/sim');

  /// Retrieves the phone numbers from the active SIM(s) on the device.
  /// Requests necessary permissions if not already granted.
  Future<List<String>> getSimPhoneNumbers() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getSimNumbers');
      if (result != null) {
        return result.cast<String>().map((e) => normalizeNumber(e)).toList();
      }
      return [];
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        throw Exception('SIM verification requires phone permissions. Please grant them in settings.');
      }
      throw Exception('Unable to read SIM numbers: ${e.message}');
    } catch (e) {
      throw Exception('Failed to communicate with device SIM: $e');
    }
  }

  static Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final bool? result = await _channel.invokeMethod('sendSms', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        throw Exception("SMS permission denied. Cannot send OTP.");
      } else if (e.code == 'PERMISSION_GRANTED_RETRY') {
        throw Exception("SMS permission just granted. Please tap Verify again.");
      }
      throw Exception("Failed to send SMS: ${e.message}");
    } catch (e) {
      throw Exception("Unexpected error sending SMS: $e");
    }
  }

  /// Normalizes a phone number for exact matching
  static String normalizeNumber(String input) {
    String normalized = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (normalized.startsWith('0') && normalized.length > 1) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }
}
