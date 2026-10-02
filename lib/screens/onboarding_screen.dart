import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onGetStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F1FC), // Light blue background matching the image
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildPage(
                    title: 'Learn\nAnywhere\nAnytime',
                    subtitle: 'Access your classes,\nmaterials and resources\nfrom anywhere.',
                    illustration: _buildIllustration1(),
                  ),
                  _buildPage(
                    title: 'Track\nYour\nProgress',
                    subtitle: 'Stay updated with your\nattendance, marks, and\nassignments seamlessly.',
                    illustration: _buildIllustration2(),
                  ),
                  _buildPage(
                    title: 'Connect\nWith\nTeachers',
                    subtitle: 'Direct communication\nbetween parents, students,\nand school staff.',
                    illustration: _buildIllustration3(),
                  ),
                ],
              ),
            ),
            
            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ElevatedButton(
                onPressed: _currentPage == 2 
                    ? _onGetStarted 
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300), 
                          curve: Curves.easeInOut,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D6EFD), // Blue button
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentPage == 2 ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Pagination Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 10 : 8,
                  height: _currentPage == index ? 10 : 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index 
                        ? const Color(0xFF0D6EFD) 
                        : const Color(0xFF0D6EFD).withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required String title, required String subtitle, required Widget illustration}) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0A192F), // Dark navy blue
              height: 1.1,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 20),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 18,
              color: const Color(0xFF475569),
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Center(child: illustration),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildIllustration1() {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Main white circle
        Container(
          width: 250,
          height: 250,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.laptop_mac_rounded,
              size: 140,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ),
        // Floating graduation cap icon
        Positioned(
          top: 10,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0D6EFD),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration2() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A8A), // Dark blue rounded rectangle
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Icon(
          Icons.bar_chart_rounded, // or insert a custom layout of 3 bars
          size: 120,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildIllustration3() {
    return Icon(
      Icons.forum_rounded, // Chat bubble icon
      size: 220,
      color: Color(0xFF1E3A8A), // Dark blue
    );
  }
}
