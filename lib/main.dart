import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Views/bookmark_screen.dart';
import 'Views/forgot_password_screen.dart';
import 'Views/home_screen.dart';
import 'Views/login_screen.dart';
import 'Views/profile_screen.dart';
import 'Views/register_screen.dart';
import 'Views/search_screen.dart';
import 'providers/watch_room_provider.dart';
import 'theme_provider.dart';
import 'utils.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => WatchRoomProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// Global RouteObserver để detect khi route thay đổi
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: Utils.navigatorKey,
          navigatorObservers: [routeObserver],
          title: 'App Xem Phim',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          darkTheme: ThemeProvider.darkTheme,
          theme: ThemeProvider.lightTheme,
          initialRoute: '/',
          routes: {
            '/': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/search': (context) => const SearchScreen(),
            '/bookmark': (context) => const BookmarkScreen(),
            '/forgotPassword': (context) => const ForgotPasswordScreen(),
          },
        );
      },
    );
  }
}
