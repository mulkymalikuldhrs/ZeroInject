import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/dashboard.dart';
import 'screens/config_builder.dart';
import 'screens/ssh_manager.dart';
import 'screens/sni_scanner.dart';
import 'screens/offline_configs.dart';
import 'services/local_storage.dart';
import 'services/connection_tester.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  
  // Request permissions
  await _requestPermissions();
  
  // Initialize database
  await LocalStorage.instance.initDatabase();
  
  runApp(const ZeroInjectorApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.internet,
    Permission.accessNetworkState,
    Permission.storage,
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
    const SSHManagerScreen(),
    const SNIScannerScreen(),
    const OfflineConfigsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.build),
            label: 'Config',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'SSH',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.scanner),
            label: 'SNI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.offline_bolt),
            label: 'Offline',
          ),
        ],
      ),
    );
  }
}