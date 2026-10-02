import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'admin_dashboard.dart';
import 'teacher_dashboard.dart';
import 'parent_dashboard.dart';
import 'student_dashboard.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../services/sim_service.dart';
import 'otp_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (_, _, _) => const RoleSelectionPage(),
          transitionsBuilder: (_, animation, _, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SizedBox.expand(
          child: Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  @override
  void initState() {
    super.initState();
    // Show disclaimer after the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDisclaimerDialog();
    });
  }

  void _showDisclaimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2C3E6B), Color(0xFF3B5998)],
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('Disclaimer / மறுப்பு அறிவிப்பு'.tr(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(Icons.close, color: Colors.white70, size: 22),
                    ),
                  ],
                ),
              ),
              // Body
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tamil Section
                      Text('தமிழ்:'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E6B)),
                      ),
                      SizedBox(height: 8),
                      Text('இந்த செயலி மக்களுக்காக, மக்களால் உருவாக்கப்பட்ட ஒரு பொதுப் பயன்பாட்டு செயலி ஆகும். இந்த செயலியில் வழங்கப்படும் தகவல்கள் பல்வேறு பொது ஆதாரங்கள், பயனர் பகிர்வுகள் மற்றும் பிற கிடைக்கக்கூடிய தகவல் மூலங்களிலிருந்து பெறப்படலாம்.\n\n'
                        'இந்த செயலியில் இடம்பெறும் தகவல்கள் துல்லியமானவை, முழுமையானவை அல்லது எப்போதும் புதுப்பிக்கப்பட்டவை என்று நாங்கள் உத்தரவாதம் அளிக்கவில்லை.\n\n'
                        'எனவே, இந்த செயலியில் உள்ள தகவல்களை அடிப்படையாகக் கொண்டு எடுக்கப்படும் எந்தவொரு முடிவு, நடவடிக்கை, பரிவர்த்தனை அல்லது அதன் விளைவுகளுக்கும் இந்த செயலியை உருவாக்கியவர்கள், நிர்வாகிகள் அல்லது பங்களிப்பாளர்கள் பொறுப்பேற்க மாட்டார்கள்.\n\n'
                        'முக்கியமான தகவல்களுக்கு, சம்பந்தப்பட்ட அதிகாரப்பூர்வ அரசு/நிறுவன ஆதாரங்களில் தகவல்களை சரிபார்த்த பின்னரே பயன்படுத்துமாறு கேட்டுக்கொள்கிறோம்.',
                        style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.grey.shade800),
                      ),
                      SizedBox(height: 20),
                      Divider(),
                      SizedBox(height: 12),
                      // English Section
                      Text('English:'.tr(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C3E6B)),
                      ),
                      SizedBox(height: 8),
                      Text('This app is a public-interest application created by the public, for the public. The information provided through this app may be collected from various public sources, user contributions, and other available information sources.\n\n'
                        'We do not guarantee that the information provided in this app is accurate, complete, current, or error-free. The app may contain incorrect, incomplete, outdated, or misleading information.\n\n'
                        'Therefore, the developers, administrators, and contributors of this app shall not be held responsible or liable for any decision, action, transaction, loss, damage, or consequence arising from the use of or reliance on the information provided through this app.\n\n'
                        'For important or official matters, users are strongly advised to verify the information with the relevant official government or authorized sources before taking any action.',
                        style: TextStyle(fontSize: 13.5, height: 1.5, color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer with Close button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B5998),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                    child: Text('Close'.tr(), style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final roles = [
      (
        'administrator_head_master'.tr(),
        Icons.person,
        const Color(0xFFE8F5E9), // Light green background
        const Color(0xFF009688), // Dark green circle
        'Admin',
      ),
      (
        'Teacher'.tr(),
        Icons.person,
        const Color(0xFFF3E5F5), // Light purple background
        const Color(0xFF673AB7), // Dark purple circle
        'Teacher',
      ),
      (
        'Student'.tr(),
        Icons.person,
        const Color(0xFFE3F2FD), // Light blue background
        const Color(0xFF2196F3), // Dark blue circle
        'Student',
      ),
      (
        'Parent'.tr(),
        Icons.person,
        const Color(0xFFFCE4EC), // Light pink background
        const Color(0xFFE91E63), // Dark pink circle
        'Parent',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF), // Light bluish background like image
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              if (context.locale.languageCode == 'en') {
                context.setLocale(const Locale('ta'));
              } else {
                context.setLocale(const Locale('en'));
              }
            },
            icon: Icon(Icons.translate, color: Color(0xFF1E293B)),
            tooltip: 'Switch Language'.tr(),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Simplified decorative background (since we don't have the exact image)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 150,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFF8FBFF).withValues(alpha: 0.0),
                      const Color(0xFFE0F2FE).withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
            
            // Main content
            Column(
              children: [
                SizedBox(height: 20),
                Image.asset('assets/images/logo.png', height: 120),
                SizedBox(height: 16),
                Text(
                  'Select Your Role'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choose how you want to continue'.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFF64748B),
                  ),
                ),
                SizedBox(height: 40),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: roles.length,
                      itemBuilder: (context, index) {
                        final role = roles[index];
                        return Material(
                          color: role.$3,
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginPage(
                                    role: role.$5, // pass the identifier like 'Admin'
                                    color: role.$4,
                                    icon: role.$2,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: role.$4,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      role.$2,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  Expanded(
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          role.$1,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  final String role;
  final Color color;
  final IconData icon;

  const LoginPage({
    super.key,
    required this.role,
    required this.color,
    required this.icon,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      UserModel? user = await _authService.signIn(
        _userController.text,
        _passwordController.text,
      );

      if (user != null) {
        if (!mounted) return;
        
        // Verify role matches selected portal (optional, but good for UX)
        if (user.role.toLowerCase() != widget.role.toLowerCase()) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Warning: Logging in as ${user.role} instead of ${widget.role}.')),
          );
        }

        Widget destination;
        switch (user.role.toLowerCase()) {
          case 'admin':
            destination = const AdminDashboard();
            break;
          case 'teacher':
            destination = const TeacherDashboard();
            break;
          case 'student':
            destination = const StudentDashboard();
            break;
          default:
            destination = const ParentDashboard();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => destination),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}'),
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final enteredNumber = _userController.text.trim();
      final normalizedEntered = SimService.normalizeNumber(enteredNumber);

      print("--- DIAGNOSTIC LOGGING ---");
      print("Firebase App: \${Firebase.app().name}");
      print("Firebase Project ID: \${Firebase.app().options.projectId}");
      print("Attempting to verify mobile number: \$normalizedEntered");

      // Verify the number in Firestore first via our derived authentication
      print("Querying users collection via Auth mapping for role \${widget.role}...");
      UserModel? user = await _authService.verifyUserByPhone(normalizedEntered, widget.role);

      if (user == null) {
        print("Student record not found or login failed.");
        throw Exception("This mobile number is not registered. Please contact your school administrator.");
      }
      print("Student record found! Account active status: \${user.status}");

      if (user.role.toLowerCase() != widget.role.toLowerCase()) {
         throw Exception("Role mismatch. You do not have ${widget.role} privileges.");
      }

      if (!mounted) return;

      // Navigate to OTP Screen (which will now handle generating and sending the initial SMS)

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpScreen(
            mobileNumber: normalizedEntered,
            user: user,
            selectedRole: widget.role,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login failed: ${e.toString().replaceAll('Exception: ', '')}'),
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
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back_ios_new, size: 20),
                  color: AppTheme.textDark,
                ),
              ),
            ),
            SizedBox(height: 40),
            Center(
              child: Hero(
                tag: widget.role,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    size: 56,
                    color: widget.color,
                  ),
                ),
              ),
            ),
            SizedBox(height: 32),
            Text(
              '${widget.role} Login',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 8),
            Text('Sign in to access your E-School account'.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 48),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.role == 'Admin' ? 'Admin ID (Email)' : 'Mobile Number',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _userController,
                    keyboardType: widget.role == 'Admin' ? TextInputType.emailAddress : TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: widget.role == 'Admin' ? 'Enter Admin ID' : 'Enter your mobile number',
                      prefixIcon: Icon(widget.role == 'Admin' ? Icons.person_outline : Icons.phone_android, color: widget.color),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty
                            ? (widget.role == 'Admin' ? 'Please enter Admin ID' : 'Please enter your mobile number')
                            : null,
                  ),
                  SizedBox(height: 24),
                  if (widget.role == 'Admin') ...[
                    Text('Password'.tr(),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password'.tr(),
                        prefixIcon: Icon(Icons.lock_outline, color: widget.color),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Minimum 6 characters required';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 8),
                  ],
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isLoading ? null : (widget.role == 'Admin' ? _signIn : _sendOtp),
                      child: _isLoading 
                          ? SizedBox(
                              height: 24, 
                              width: 24, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : Text(
                              widget.role == 'Admin' ? 'Sign In' : 'Send OTP',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Text(
              'E-School • ${widget.role} Portal',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}