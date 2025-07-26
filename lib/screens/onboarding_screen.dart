import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:safe_reporting/services/auth_service.dart';
import 'package:safe_reporting/services/localization_service.dart';
import 'package:safe_reporting/screens/home_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Anonymous Reporting',
      description: 'Report security concerns, corruption, harassment, or mental health issues completely anonymously.',
      image: 'assets/images/onboarding_anonymous.png',
      color: Colors.blue.shade50,
    ),
    OnboardingPage(
      title: 'Secure Communication',
      description: 'All your reports and communications are encrypted and secure.',
      image: 'assets/images/onboarding_secure.png',
      color: Colors.green.shade50,
    ),
    OnboardingPage(
      title: 'Two-Way Communication',
      description: 'Receive updates and communicate with responders while maintaining your anonymity.',
      image: 'assets/images/onboarding_communication.png',
      color: Colors.purple.shade50,
    ),
    OnboardingPage(
      title: 'Multiple Languages',
      description: 'Use the app in your preferred language.',
      image: 'assets/images/onboarding_language.png',
      color: Colors.orange.shade50,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onGetStarted() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      await authService.signInAnonymously();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      print('Error during anonymous sign-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: WormEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: Theme.of(context).primaryColor,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _currentPage == _pages.length - 1
                        ? _onGetStarted
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          },
                    child: Text(
                      _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.color,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            page.image,
            height: 250,
          ),
          const SizedBox(height: 32),
          Text(
            page.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
