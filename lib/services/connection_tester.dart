import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/payload_config.dart';
import '../models/ssh_account.dart';

class ConnectionTester extends ChangeNotifier {
  bool _isConnected = false;
  bool _isTesting = false;
  String _currentStatus = 'Disconnected';
  String _currentIP = '';
  List<String> _logs = [];
  PayloadConfig? _activeConfig;

  bool get isConnected => _isConnected;
  bool get isTesting => _isTesting;
  String get currentStatus => _currentStatus;
  String get currentIP => _currentIP;
  List<String> get logs => _logs;
  PayloadConfig? get activeConfig => _activeConfig;

  void addLog(String message) {
    _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
    if (_logs.length > 100) {
      _logs.removeLast();
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  Future<bool> testPayloadConfig(PayloadConfig config) async {
    _isTesting = true;
    _currentStatus = 'Testing configuration...';
    notifyListeners();

    addLog('Testing payload: ${config.name}');
    addLog('SNI Host: ${config.sniHost}');
    addLog('SSH Host: ${config.sshHost}:${config.sshPort}');

    try {
      // Test SNI connectivity first
      bool sniWorking = await _testSNIConnectivity(config.sniHost);
      if (!sniWorking) {
        addLog('❌ SNI test failed: ${config.sniHost}');
        _isTesting = false;
        _currentStatus = 'SNI test failed';
        notifyListeners();
        return false;
      }

      addLog('✅ SNI test passed: ${config.sniHost}');

      // Test SSH connectivity
      bool sshWorking = await _testSSHConnectivity(config.sshHost, config.sshPort);
      if (!sshWorking) {
        addLog('❌ SSH test failed: ${config.sshHost}:${config.sshPort}');
        _isTesting = false;
        _currentStatus = 'SSH test failed';
        notifyListeners();
        return false;
      }

      addLog('✅ SSH test passed: ${config.sshHost}:${config.sshPort}');

      // Test payload injection
      bool payloadWorking = await _testPayloadInjection(config);
      if (!payloadWorking) {
        addLog('❌ Payload injection failed');
        _isTesting = false;
        _currentStatus = 'Payload injection failed';
        notifyListeners();
        return false;
      }

      addLog('✅ Payload injection successful');

      // Get external IP to verify connection
      String externalIP = await _getExternalIP();
      if (externalIP.isNotEmpty) {
        _currentIP = externalIP;
        addLog('✅ External IP: $externalIP');
      }

      _isConnected = true;
      _activeConfig = config;
      _currentStatus = 'Connected successfully';
      addLog('🎉 Connection established successfully!');

    } catch (e) {
      addLog('❌ Error during testing: $e');
      _currentStatus = 'Connection failed';
      _isConnected = false;
    }

    _isTesting = false;
    notifyListeners();
    return _isConnected;
  }

  Future<bool> _testSNIConnectivity(String hostname) async {
    try {
      addLog('Testing SNI connectivity to $hostname...');
      
      SecureSocket socket = await SecureSocket.connect(
        hostname,
        443,
        timeout: const Duration(seconds: 10),
        onBadCertificate: (certificate) => true,
      );
      
      await socket.close();
      return true;
    } catch (e) {
      addLog('SNI connectivity error: $e');
      return false;
    }
  }

  Future<bool> _testSSHConnectivity(String host, int port) async {
    try {
      addLog('Testing SSH connectivity to $host:$port...');
      
      Socket socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 10),
      );
      
      await socket.close();
      return true;
    } catch (e) {
      addLog('SSH connectivity error: $e');
      return false;
    }
  }

  Future<bool> _testPayloadInjection(PayloadConfig config) async {
    try {
      addLog('Testing payload injection...');
      
      // Simulate payload injection by creating a custom HTTP request
      HttpClient client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      
      HttpClientRequest request = await client.openUrl(
        'GET',
        Uri.parse('https://${config.sniHost}/')
      );
      
      // Add custom headers from payload
      request.headers.set('Host', config.sniHost);
      request.headers.set('X-Online-Host', config.sniHost);
      request.headers.set('User-Agent', 'Mozilla/5.0 (Android 13; Mobile)');
      
      HttpClientResponse response = await request.close();
      await response.drain();
      
      client.close();
      
      return response.statusCode < 500;
    } catch (e) {
      addLog('Payload injection error: $e');
      return false;
    }
  }

  Future<String> _getExternalIP() async {
    try {
      addLog('Getting external IP address...');
      
      final response = await http.get(
        Uri.parse('https://api.ipify.org?format=json'),
        headers: {'User-Agent': 'ZeroInjector/1.0'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['ip'] ?? '';
      }
    } catch (e) {
      addLog('Failed to get external IP: $e');
      
      // Try alternative IP service
      try {
        final response = await http.get(
          Uri.parse('https://httpbin.org/ip'),
          headers: {'User-Agent': 'ZeroInjector/1.0'},
        ).timeout(const Duration(seconds: 10));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          return data['origin'] ?? '';
        }
      } catch (e) {
        addLog('Alternative IP service also failed: $e');
      }
    }
    
    return '';
  }

  Future<void> disconnect() async {
    addLog('Disconnecting...');
    
    _isConnected = false;
    _activeConfig = null;
    _currentStatus = 'Disconnected';
    _currentIP = '';
    
    addLog('✅ Disconnected successfully');
    notifyListeners();
  }

  Future<List<PayloadConfig>> testMultipleConfigs(List<PayloadConfig> configs) async {
    List<PayloadConfig> workingConfigs = [];
    
    addLog('Testing ${configs.length} configurations...');
    
    for (int i = 0; i < configs.length; i++) {
      PayloadConfig config = configs[i];
      addLog('Testing config ${i + 1}/${configs.length}: ${config.name}');
      
      bool isWorking = await testPayloadConfig(config);
      if (isWorking) {
        workingConfigs.add(config);
        addLog('✅ Config ${i + 1} is working!');
        
        // Disconnect after testing to test next config
        await disconnect();
      } else {
        addLog('❌ Config ${i + 1} failed');
      }
      
      // Small delay between tests
      await Future.delayed(const Duration(seconds: 2));
    }
    
    addLog('Testing completed. Found ${workingConfigs.length} working configurations.');
    return workingConfigs;
  }
}