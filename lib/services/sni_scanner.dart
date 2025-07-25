import 'dart:io';
import 'dart:async';
import '../models/sni_entry.dart';

class SniScanner {
  static const List<String> _defaultSniHosts = [
    'zero.facebook.com',
    'free.facebook.com',
    'graph.facebook.com',
    'api.whatsapp.com',
    'web.whatsapp.com',
    'static.xx.fbcdn.net',
    'scontent.xx.fbcdn.net',
    'edge-chat.facebook.com',
    'mqtt.c10r.facebook.com',
    'b-api.facebook.com',
    'connect.facebook.net',
    'www.facebook.com',
    'mobile.facebook.com',
    'touch.facebook.com',
    'upload.facebook.com',
    'video.xx.fbcdn.net',
    'external.xx.fbcdn.net',
    'lookaside.facebook.com',
    'api.instagram.com',
    'www.instagram.com',
    'cdninstagram.com',
  ];

  static Future<List<SniEntry>> scanAllHosts() async {
    final List<SniEntry> results = [];
    
    for (final host in _defaultSniHosts) {
      final entry = await scanSingleHost(host);
      results.add(entry);
    }
    
    return results;
  }

  static Future<SniEntry> scanSingleHost(String host, {int port = 443}) async {
    final stopwatch = Stopwatch()..start();
    bool isActive = false;
    
    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
        supportedProtocols: ['h2', 'http/1.1'],
      );
      
      // Test TLS handshake
      await socket.flush();
      isActive = true;
      await socket.close();
      
    } catch (e) {
      print('SNI scan failed for $host: $e');
      isActive = false;
    }
    
    stopwatch.stop();
    
    return SniEntry(
      host: host,
      port: port,
      isActive: isActive,
      responseTime: stopwatch.elapsedMilliseconds,
      lastChecked: DateTime.now(),
    );
  }

  static Future<bool> testSniConnection(String host, {int port = 443}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 3));
      await socket.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<SniEntry>> scanCustomHosts(List<String> hosts) async {
    final List<SniEntry> results = [];
    
    for (final host in hosts) {
      final entry = await scanSingleHost(host);
      results.add(entry);
    }
    
    return results;
  }

  static Future<SniEntry> testSniSpeed(String host, {int port = 443}) async {
    final List<int> times = [];
    bool isActive = false;
    
    // Test 3 times untuk akurasi
    for (int i = 0; i < 3; i++) {
      final stopwatch = Stopwatch()..start();
      
      try {
        final socket = await Socket.connect(
          host, 
          port, 
          timeout: const Duration(seconds: 2),
        );
        await socket.close();
        stopwatch.stop();
        times.add(stopwatch.elapsedMilliseconds);
        isActive = true;
      } catch (e) {
        stopwatch.stop();
        times.add(9999); // High latency for failed connections
      }
      
      // Small delay between tests
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    final avgTime = times.reduce((a, b) => a + b) ~/ times.length;
    
    return SniEntry(
      host: host,
      port: port,
      isActive: isActive,
      responseTime: avgTime,
      lastChecked: DateTime.now(),
    );
  }

  static List<String> getZeroRatedHosts() {
    return List.from(_defaultSniHosts);
  }

  static Future<List<SniEntry>> getWorkingSniHosts() async {
    final results = await scanAllHosts();
    return results.where((entry) => entry.isActive).toList();
  }
}