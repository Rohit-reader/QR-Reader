import 'package:flutter/material.dart';
import 'package:qr_reader/pages/qr_code.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QRLizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        // ✅ FIXED: Material 3 safe theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
        ),

        hintColor: Colors.grey[600],
        scaffoldBackgroundColor: Colors.grey[200],

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 4,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 5,
          ),
        ),
      ),
      routes: {
        '/': (context) => const WelcomePage(),
        '/scan_qr': (context) => const ScanCodePage(),
      },
      initialRoute: '/',
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QRLizer'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/scan_qr');
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan QR Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
