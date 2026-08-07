import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/models/role.dart';
import 'package:msw_eplant/services/auth_service.dart';
import 'package:msw_eplant/services/notification_service.dart';
import 'package:msw_eplant/pages/home_page.dart';
import 'package:msw_eplant/pages/plant_page.dart' as plant;
import 'package:msw_eplant/pages/logsheet/logsheet_page.dart';
import 'package:msw_eplant/pages/maintenance_page.dart';
import 'package:msw_eplant/pages/login_page.dart';
import 'package:msw_eplant/pages/settings_page.dart';
import 'package:msw_eplant/pages/okr_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MSW ePlant',
      theme: AppTheme.dark,
      initialRoute: '/splash',
      builder: (context, child) {
       final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(mq.textScaler.scale(1.0).clamp(0.8, 1.3)),
          ),
          child: child!,
        );
      },
      routes: {
        '/splash': (_) => const SplashPage(),
        '/login': (_) => const LoginPage(),
        '/home': (_) => const MainScaffold(),
      },
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 1));
    final valid = await AuthService.hasValidSession();
    if (!mounted) return;
    if (valid) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset('asset/logo_login.png', width: 64, height: 64, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            const Text('ePlant', style: TextStyle(fontSize: 14, color: AppColors.textSub)),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  UserRole _role = UserRole.operation;
  int _selectedIndex = 0;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await AuthService.getSavedRole();
    if (mounted) {
      setState(() {
        _role = role ?? UserRole.operation;
        _loaded = true;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<BottomNavigationBarItem> get _navItems {
    final home = const BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home),
      label: 'Home',
    );
    final operation = const BottomNavigationBarItem(
      icon: Icon(Icons.bolt_outlined),
      activeIcon: Icon(Icons.bolt),
      label: 'Operation',
    );
    final setting = const BottomNavigationBarItem(
      icon: Icon(Icons.settings_outlined),
      activeIcon: Icon(Icons.settings),
      label: 'Setting',
    );

    switch (_role) {
      case UserRole.operation:
        return [
          home,
          operation,
          const BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Logsheet',
          ),
          setting,
        ];
      case UserRole.maintenance:
        return [
          home,
          operation,
          const BottomNavigationBarItem(
            icon: Icon(Icons.build_outlined),
            activeIcon: Icon(Icons.build),
            label: 'Maintenance',
          ),
          setting,
        ];
      case UserRole.general:
        return [
          home,
          operation,
          const BottomNavigationBarItem(
            icon: Icon(Icons.track_changes_outlined),
            activeIcon: Icon(Icons.track_changes),
            label: 'OKR',
          ),
          setting,
        ];
    }
  }

  Widget get _currentPage {
    if (!_loaded) return const SizedBox();

    // Home is always index 0
    if (_selectedIndex == 0) return HomePage(role: _role, onSwitchRole: _switchRole);

    // Operation is always index 1
    if (_selectedIndex == 1) return const plant.PlantPage();

    // Index 2 depends on role
    if (_selectedIndex == 2) {
      switch (_role) {
        case UserRole.operation:
          return const LogsheetPage();
        case UserRole.maintenance:
          return const MaintenancePage();
        case UserRole.general:
          return const OkrPage();
      }
    }

    // Setting is index 3
    if (_selectedIndex == 3) {
      return SettingsPage(role: _role);
    }

    return const SizedBox();
  }

  Future<void> _switchRole() async {
    await AuthService.clearSession();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: _currentPage,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: BottomNavigationBar(
          items: _navItems,
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
          backgroundColor: Colors.black.withOpacity(0.65),
          selectedItemColor: AppColors.roleColor(_role.label),
          unselectedItemColor: AppColors.textDim,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  final String label;
  final String icon;
  const PlaceholderPage({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 14)),
            const SizedBox(height: 4),
            Text('Halaman sedang dikembangkan', style: const TextStyle(color: AppColors.textDim, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
