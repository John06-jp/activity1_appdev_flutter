import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/activities/activity_one_screen.dart';
import 'screens/activities/activity_two_screen.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const PortfolioMasterApp(),
    ),
  );
}

class PortfolioMasterApp extends StatelessWidget {
  const PortfolioMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final seedColor = appProvider.accentColor.primary;

        return MaterialApp(
          title: 'Flutter Portfolio & State Management',
          debugShowCheckedModeBanner: false,
          themeMode: appProvider.themeMode,

          // Premium Light Theme
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: Color(0xFFF8FAFC),
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF64748B).withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),

          // Premium Dark Theme (Deep Navy / Charcoal)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
              scrolledUnderElevation: 2,
              backgroundColor: Color(0xFF0B0F19),
              surfaceTintColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF1F5F9),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 3,
              shadowColor: Colors.black.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            chipTheme: ChipThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            ),
          ),

          // Navigation Routes
          initialRoute: '/',
          routes: {
            '/': (context) => const HomeScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/activity-1': (context) => const ActivityOneScreen(),
            '/activity-2': (context) => const ActivityTwoScreen(),
          },
        );
      },
    );
  }
}
