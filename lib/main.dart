import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'providers/connectivity_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
      ],
      child: const LabTrackApp(),
    ),
  );
}

class LabTrackApp extends StatelessWidget {
  const LabTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'LabTrack',
          debugShowCheckedModeBanner: false,
          themeMode: appProvider.themeMode,

          // Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B6FE8),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF0F4FF),
            fontFamily: 'Roboto',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),

          // Dark Theme
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF3B6FE8),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            fontFamily: 'Roboto',
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),

          home: const SplashScreen(),
        );
      },
    );
  }
}
