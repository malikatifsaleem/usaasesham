
import 'dart:io';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:udaasesham/splashScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();


  Platform.isAndroid
  ? await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDxaKVprkidT3eXI2EW41qX41t9WShUjq0',
        appId: '1:564004326488:android:421dfa5d81933669cf0e2d',
        messagingSenderId: "564004326488",
        projectId: "shaam-e-udaas",
        storageBucket: "shaam-e-udaas.appspot.com",
      ))
  : await Firebase.initializeApp();
  await FirebaseAppCheck.instance.activate(
    // webRecaptchaSiteKey: 'recaptcha-v3-site-key',
    // Set androidProvider to `AndroidProvider.debug`
    androidProvider: AndroidProvider.debug,
  );
  await FirebaseAppCheck.instance
      .activate(
  androidProvider: AndroidProvider.playIntegrity,
  appleProvider: AppleProvider.appAttest,
  webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'شامِ  اُداس',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Define your theme here
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontFamily: "علوی نستعلیق",
          ),
        ),
      ),// Enable system-based theme switching
      home: SplashScreen(),
    );
  }
}
