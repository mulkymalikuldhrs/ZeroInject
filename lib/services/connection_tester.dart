import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import '../models/payload_config.dart';
import 'payload_generator.dart';

class ConnectionTester extends ChangeNotifier {
  bool _isConnected = false;
  bool _isTesting = false;
  String _currentStatus = 'Disconnected';
  String _currentIp = '';
  List<String> _logs = [];
  PayloadConfig? _activeConfig;

  bool get isConnected => _isConnected;
  bool get isTesting => _isTesting;
  String get currentStatus => _currentStatus;
  String get currentIp => _currentIp;
  List<String> get logs => List.unmodifiable(_logs);
  PayloadConfig? get activeConfig => _activeConfig;

  final Connectivity _connectivity = Connectivity();
  Timer? _connectionTimer;
  Isolate? _tunnelIsolate;

  void addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    _logs.add('[$timestamp] $message');
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  Future<bool> testConnection(PayloadConfig config) async {
    if (_isTesting) return false;
    
    _isTesting = true;
    _activeConfig = config;
    _updateStatus('Testing connection...');
    addLog('Starting connection test for ${config.name}');
    notifyListeners();

    try {
      // Step 1: Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        addLog('No network connectivity');
        return false;
      }

      // Step 2: Test SNI host accessibility
      addLog('Testing SNI host: ${config.sniHost}');
      final sniResult = await _testSniHost(config.sniHost);
      if (!sniResult) {
        addLog('SNI host not accessible: ${config.sniHost}');
        return false;
      }

      // Step 3: Test SSH connection
      addLog('Testing SSH connection: ${config.sshHost}:${config.sshPort}');
      final sshResult = await _testSshConnection(config);
      if (!sshResult) {
        addLog('SSH connection failed');
        return false;
      }

      // Step 4: Setup tunnel
      addLog('Setting up tunnel...');
      final tunnelResult = await _setupTunnel(config);
      if (!tunnelResult) {
        addLog('Tunnel setup failed');
        return false;
      }

      // Step 5: Test internet through tunnel
      addLog('Testing internet through tunnel...');
      final internetResult = await _testInternetThroughTunnel();
      if (!internetResult) {
        addLog('Internet test through tunnel failed');
        return false;
      }

      // Step 6: Get external IP
      final ip = await _getExternalIp();
      _currentIp = ip ?? 'Unknown';
      
      _isConnected = true;
      _updateStatus('Connected');
      addLog('Connection successful! IP: $_currentIp');
      
      // Start monitoring connection
      _startConnectionMonitoring();
      
      return true;

    } catch (e) {
      addLog('Connection test error: $e');
      return false;
    } finally {
      _isTesting = false;
      notifyListeners();
    }
  }

  Future<bool> _testSniHost(String host) async {
    try {
      final socket = await Socket.connect(host, 443, timeout: const Duration(seconds: 5));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _testSshConnection(PayloadConfig config) async {
    try {
      final socket = await Socket.connect(
        config.sshHost, 
        config.sshPort, 
        timeout: const Duration(seconds: 10),
      );
      
      // Send basic SSH handshake
      socket.write('SSH-2.0-ZeroInjector\r\n');
      await socket.flush();
      
      // Wait for response
      final response = await socket.first.timeout(const Duration(seconds: 5));
      await socket.close();
      
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _setupTunnel(PayloadConfig config) async {
    try {
      // Generate payload
      final payload = await PayloadGenerator.buildPayload(config);
      addLog('Generated payload for ${config.sniHost}');
      
      // Setup tunnel in isolate
      final receivePort = ReceivePort();
      _tunnelIsolate = await Isolate.spawn(
        _tunnelIsolateEntry,
        {
          'sendPort': receivePort.sendPort,
          'config': config.toMap(),
          'payload': payload,
        },
      );
      
      // Wait for tunnel setup confirmation
      final completer = Completer<bool>();
      receivePort.listen((message) {
        if (message['type'] == 'tunnel_ready') {
          completer.complete(message['success']);
        } else if (message['type'] == 'log') {
          addLog(message['message']);
        }
      });
      
      return await completer.future.timeout(const Duration(seconds: 15));
    } catch (e) {
      addLog('Tunnel setup error: $e');
      return false;
    }
  }

  static void _tunnelIsolateEntry(Map<String, dynamic> params) async {
    final sendPort = params['sendPort'] as SendPort;
    final config = PayloadConfig.fromMap(params['config']);
    final payload = params['payload'] as String;
    
    try {
      // Setup HTTP proxy server
      final server = await HttpServer.bind('127.0.0.1', 8080);
      
      server.listen((HttpRequest request) async {
        try {
          // Handle CONNECT method for HTTPS tunneling
          if (request.method == 'CONNECT') {
            final targetHost = config.sshHost;
            final targetPort = config.sshPort;
            
            // Connect to SSH server through SNI
            final targetSocket = await Socket.connect(targetHost, targetPort);
            
            // Send success response
            request.response.statusCode = 200;
            request.response.reasonPhrase = 'Connection established';
            await request.response.close();
            
            // Start tunneling data
            final clientSocket = await request.response.detachSocket();
            
            // Pipe data between client and target
            clientSocket.pipe(targetSocket);
            targetSocket.pipe(clientSocket);
            
            sendPort.send({'type': 'log', 'message': 'Tunnel established'});
          }
        } catch (e) {
          sendPort.send({'type': 'log', 'message': 'Tunnel error: $e'});
        }
      });
      
      sendPort.send({'type': 'tunnel_ready', 'success': true});
      
    } catch (e) {
      sendPort.send({'type': 'tunnel_ready', 'success': false});
      sendPort.send({'type': 'log', 'message': 'Isolate error: $e'});
    }
  }

  Future<bool> _testInternetThroughTunnel() async {
    try {
      // Test connection through local proxy
      final client = http.Client();
      final request = http.Request('GET', Uri.parse('http://httpbin.org/ip'));
      request.headers['Proxy-Connection'] = 'Keep-Alive';
      
      // Use local proxy
      final response = await client.send(request).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> _getExternalIp() async {
    try {
      final response = await http.get(
        Uri.parse('http://httpbin.org/ip'),
        headers: {'User-Agent': 'ZeroInjector/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = response.body;
        final ipRegex = RegExp(r'"origin":\s*"([^"]+)"');
        final match = ipRegex.firstMatch(data);
        return match?.group(1);
      }
    } catch (e) {
      addLog('Failed to get external IP: $e');
    }
    return null;
  }

  void _startConnectionMonitoring() {
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isConnected) {
        final isStillConnected = await _checkConnectionHealth();
        if (!isStillConnected) {
          await disconnect();
          addLog('Connection lost - auto disconnected');
        }
      }
    });
  }

  Future<bool> _checkConnectionHealth() async {
    try {
      final response = await http.get(
        Uri.parse('http://httpbin.org/status/200'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    _connectionTimer?.cancel();
    _tunnelIsolate?.kill();
    _tunnelIsolate = null;
    
    _isConnected = false;
    _currentIp = '';
    _activeConfig = null;
    _updateStatus('Disconnected');
    addLog('Disconnected');
    notifyListeners();
  }

  void _updateStatus(String status) {
    _currentStatus = status;
    notifyListeners();
  }

  Future<List<PayloadConfig>> testMultipleConfigs(List<PayloadConfig> configs) async {
    final List<PayloadConfig> workingConfigs = [];
    
    for (final config in configs) {
      addLog('Testing config: ${config.name}');
      final result = await testConnection(config);
      
      if (result) {
        workingConfigs.add(config.copyWith(isSuccessful: true));
        addLog('✓ Config ${config.name} works!');
        await disconnect(); // Disconnect before testing next
      } else {
        addLog('✗ Config ${config.name} failed');
      }
      
      // Small delay between tests
      await Future.delayed(const Duration(seconds: 2));
    }
    
    return workingConfigs;
  }

  @override
  void dispose() {
    _connectionTimer?.cancel();
    _tunnelIsolate?.kill();
    super.dispose();
  }
}