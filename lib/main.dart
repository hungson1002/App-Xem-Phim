import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'Views/movie_detail_screen.dart';

import 'Views/bookmark_screen.dart';
import 'Views/forgot_password_screen.dart';
import 'Views/home_screen.dart';
import 'Views/login_screen.dart';
import 'Views/profile_screen.dart';
import 'Views/register_screen.dart';
import 'Views/search_screen.dart';
import 'theme_provider.dart';
import 'utils.dart';

// Global RouteObserver for tracking route changes
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Check initial link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Listen to link stream
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');

    String? slug;

    // Case 1: Custom Scheme (appxemphim://movie/<slug>)
    if (uri.scheme == 'appxemphim' &&
        uri.host == 'movie' &&
        uri.pathSegments.isNotEmpty) {
      slug = uri.pathSegments.first;
    }
    // Case 2: Web Domain (https://watchalong428.vercel.app/movie/<slug>)
    else if ((uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host == 'watchalong428.vercel.app' &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments[0] == 'movie' &&
        uri.pathSegments.length > 1) {
      slug = uri.pathSegments[1];
    }

    if (slug != null) {
      // Navigate using global navigator key
      Utils.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MovieDetailScreen(movieId: slug!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: Utils.navigatorKey,
          navigatorObservers: [routeObserver],
          title: 'WatchAlong',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          darkTheme: ThemeProvider.darkTheme,
          theme: ThemeProvider.lightTheme,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('vi', ''), // Vietnamese
            Locale('en', ''), // English
          ],
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
