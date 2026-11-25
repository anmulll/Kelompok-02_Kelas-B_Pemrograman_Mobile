import 'package:flutter/material.dart';

import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/booking/screens/booking_screen.dart';
import '../../features/courts/screens/court_detail_screen.dart';
import '../../features/courts/screens/slot_selection_screen.dart';
import '../../features/explore/screens/explore_screen.dart';
import '../../features/explore/screens/map_view_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String home = '/';
  static const String splash = '/splash';
  static const String exploreMap = '/explore-map';
  static const String login = '/login';
  static const String register = '/register';
  static const String courtDetail = '/court-detail';
  static const String slotSelection = '/slot-selection';
  static const String booking = '/booking';
  static const String payment = '/payment';
  static const String admin = '/admin';
  static const String editProfile = '/edit-profile';

  static Map<String, WidgetBuilder> get routes => {
    splash: (_) => const SplashScreen(),
    home: (_) => const HomeShellScreen(),
    exploreMap: (_) => const MapViewScreen(),
    login: (_) => const LoginScreen(),
    register: (_) => const RegisterScreen(),
    courtDetail: (_) => const CourtDetailScreen(),
    slotSelection: (_) => const SlotSelectionScreen(),
    booking: (_) => const BookingScreen(),
    payment: (_) => const PaymentScreen(),
    admin: (_) => const AdminDashboardScreen(),
    editProfile: (_) => const EditProfileScreen(),
  };
}
