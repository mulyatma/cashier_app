import 'package:cashier_app/pages/history_page.dart';
import 'package:cashier_app/pages/payment_page.dart';
import 'package:cashier_app/pages/transaction_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'pages/login_page.dart';
import 'pages/splash_screen.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';
import 'pages/add_menu_page.dart';
import 'pages/all_menu_page.dart';
import 'pages/transaction_page.dart';
import 'pages/report_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Kasir',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const HomePage(),
        '/register': (context) => const RegisterPage(),
        '/add-menu': (context) => const AddMenuPage(),
        '/menus': (context) => const AllMenuPage(),
        '/transactions': (context) => const TransactionPage(),
        '/history': (context) => const HistoryPage(),
        '/payment': (context) => const PaymentPage(),
        '/transaction-detail': (context) => const TransactionDetailPage(),
        '/reports': (context) => const ReportPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
