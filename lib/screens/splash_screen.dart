// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds then navigate; routing logic will redirect if unauthenticated
    Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        context.go('/');
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: SvgPicture.asset(
          'assets/logo.svg',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}
