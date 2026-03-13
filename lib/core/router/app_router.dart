import 'package:go_router/go_router.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/quiz/quiz_feed_screen.dart';
import '../../features/payment/payment_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/quiz',
      builder: (context, state) => const QuizFeedScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) => const PaymentScreen(),
    ),
  ],
);
