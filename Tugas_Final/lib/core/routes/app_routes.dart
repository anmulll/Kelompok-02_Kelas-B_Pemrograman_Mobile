import 'package:flutter/material.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/courts/screens/court_detail_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/payment/screens/payment_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String courtDetail = '/court-detail';
  static const String booking = '/booking';
  static const String payment = '/payment';
  static const String admin = '/admin';

  static Map<String, WidgetBuilder> get routes => {
    home: (_) => const HomeShellScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    courtDetail: (_) => const CourtDetailScreen(),
    booking: (_) => const BookingScreen(),
    payment: (_) => const PaymentScreen(),
    admin: (_) => const AdminDashboardScreen(),
  };
}
