package com.example.flutter_application_1

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.eschool/sim"
    private val PERMISSION_REQUEST_CODE = 101
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getSimNumbers") {
                if (hasPermissions()) {
                    val numbers = getSimNumbers()
                    result.success(numbers)
                } else {
                    pendingResult = result
                    requestPermissions()
                }
            } else if (call.method == "sendSms") {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")
                if (phoneNumber != null && message != null) {
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.SEND_SMS) == PackageManager.PERMISSION_GRANTED) {
                        try {
                            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                                applicationContext.getSystemService(SmsManager::class.java)
                            } else {
                                @Suppress("DEPRECATION")
                                SmsManager.getDefault()
                            }
                            smsManager.sendTextMessage(phoneNumber, null, message, null, null)
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("SMS_FAILED", "Failed to send SMS: ${e.message}", null)
                        }
                    } else {
                        pendingResult = result
                        ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.SEND_SMS), 102)
                    }
                } else {
                    result.error("INVALID_ARGS", "Phone number or message is missing.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun hasPermissions(): Boolean {
        val phoneState = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED
        val phoneNumbers = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_NUMBERS) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
        return phoneState && phoneNumbers
    }

    private fun requestPermissions() {
        val permissions = mutableListOf(Manifest.permission.READ_PHONE_STATE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            permissions.add(Manifest.permission.READ_PHONE_NUMBERS)
        }
        ActivityCompat.requestPermissions(this, permissions.toTypedArray(), PERMISSION_REQUEST_CODE)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
                pendingResult?.success(getSimNumbers())
            } else {
                pendingResult?.error("PERMISSION_DENIED", "Required permissions were denied.", null)
            }
            pendingResult = null
        } else if (requestCode == 102) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingResult?.error("PERMISSION_GRANTED_RETRY", "Permission granted. Please try sending again.", null)
            } else {
                pendingResult?.error("PERMISSION_DENIED", "SMS sending permission was denied.", null)
            }
            pendingResult = null
        }
    }

    private fun getSimNumbers(): List<String> {
        val numbers = mutableListOf<String>()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                val subscriptionManager = getSystemService(Context.TELEPHONY_SUBSCRIPTION_SERVICE) as SubscriptionManager
                val activeSubscriptionInfoList = subscriptionManager.activeSubscriptionInfoList
                if (activeSubscriptionInfoList != null) {
                    for (subscriptionInfo in activeSubscriptionInfoList) {
                        var number: String? = null
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                            val sm = getSystemService(SubscriptionManager::class.java)
                            number = sm.getPhoneNumber(subscriptionInfo.subscriptionId)
                        } else {
                            @Suppress("DEPRECATION")
                            number = subscriptionInfo.number
                        }
                        if (!number.isNullOrEmpty()) {
                            numbers.add(number)
                        }
                    }
                }
            }

            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            @Suppress("DEPRECATION")
            val number = telephonyManager.line1Number
            if (!number.isNullOrEmpty() && !numbers.contains(number)) {
                numbers.add(number)
            }
        } catch (e: SecurityException) {
            // Ignored
        } catch (e: Exception) {
            // Ignored
        }
        return numbers
    }
}
