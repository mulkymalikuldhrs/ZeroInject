import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/dashboard.dart';
import 'screens/config_builder.dart';
import 'screens/ssh_manager.dart';
import 'screens/sni_scanner.dart';
import 'screens/offline_configs.dart';
import 'services/local_storage.dart';
import 'services/connection_tester.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request permissions
  await _requestPermissions();
  
  // Initialize local storage
  await LocalStorage.instance.init();
  
  runApp(const ZeroInjectorApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.internet,
    Permission.accessNetworkState,
    Permission.notification,
  ].request();
}

class ZeroInjectorApp extends StatelessWidget {
  const ZeroInjectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ConnectionTester()),
      ],
      child: MaterialApp(
        title: 'ZeroInjector',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const DashboardScreen(),
    const ConfigBuilderScreen(),
    const SshManagerScreen(),
    const SniScannerScreen(),
    const OfflineConfigsScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.build),
      label: 'Config Builder',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.computer),
      label: 'SSH Manager',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.network_check),
      label: 'SNI Scanner',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.offline_bolt),
      label: 'Offline Configs',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroInjector'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: _navItems,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ZeroInjector'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.0'),
            SizedBox(height: 8),
            Text('Auto Injector Bypass Internet Android'),
            Text('No Root Required'),
            SizedBox(height: 8),
            Text('Features:'),
            Text('• Auto SNI Scanner'),
            Text('• Auto SSH Fetcher'),
            Text('• Auto Payload Generator'),
            Text('• Offline Mode Support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}