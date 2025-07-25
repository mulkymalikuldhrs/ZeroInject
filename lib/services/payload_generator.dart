import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_user_agent/flutter_user_agent.dart';
import '../models/payload_config.dart';
import '../models/ssh_account.dart';
import '../models/sni_entry.dart';

class PayloadGenerator {
  static const List<String> _payloadTemplates = [
    // HTTP CONNECT Method
    '''CONNECT [SNI] HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
X-Forward-Host: [SNI]
Connection: Keep-Alive
User-Agent: [USER_AGENT]
Proxy-Connection: Keep-Alive

''',

    // HTTP GET Method
    '''GET / HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
X-Forward-Host: [SNI]
Connection: upgrade
Upgrade: websocket
User-Agent: [USER_AGENT]

''',

    // WebSocket Upgrade
    '''GET / HTTP/1.1
Host: [SNI]
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: [WEBSOCKET_KEY]
Sec-WebSocket-Version: 13
X-Online-Host: [SNI]
User-Agent: [USER_AGENT]

''',

    // HTTP Proxy Method
    '''CONNECT [HOST]:[PORT] HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
Proxy-Connection: Keep-Alive
User-Agent: [USER_AGENT]

''',

    // Custom Inject Method
    '''[METHOD] [SNI] HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
X-Forward-Host: [SNI]
X-Real-IP: [SNI]
Connection: Keep-Alive
User-Agent: [USER_AGENT]

''',
  ];

  static Future<String> generateUserAgent() async {
    try {
      return await FlutterUserAgent.getPropertyAsync('userAgent') ?? _getDefaultUserAgent();
    } catch (e) {
      return _getDefaultUserAgent();
    }
  }

  static String _getDefaultUserAgent() {
    return 'Mozilla/5.0 (Linux; Android 10; SM-G975F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36';
  }

  static String _generateWebSocketKey() {
    final bytes = List<int>.generate(16, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    return base64Encode(bytes);
  }

  static Future<List<PayloadConfig>> generateAllCombinations(
    List<SniEntry> sniHosts,
    List<SshAccount> sshAccounts,
  ) async {
    final List<PayloadConfig> configs = [];
    final userAgent = await generateUserAgent();
    
    for (int templateIndex = 0; templateIndex < _payloadTemplates.length; templateIndex++) {
      final template = _payloadTemplates[templateIndex];
      
      for (final sni in sniHosts.where((s) => s.isActive)) {
        for (final ssh in sshAccounts.where((s) => !s.isExpired)) {
          final config = PayloadConfig(
            name: 'Auto-${sni.host.split('.').first}-${ssh.host.split('.').first}-T$templateIndex',
            template: template,
            sniHost: sni.host,
            sshHost: ssh.host,
            sshPort: ssh.port,
            sshUser: ssh.user,
            sshPassword: ssh.password,
          );
          
          configs.add(config);
        }
      }
    }
    
    return configs;
  }

  static Future<String> buildPayload(PayloadConfig config) async {
    final userAgent = await generateUserAgent();
    final websocketKey = _generateWebSocketKey();
    
    String payload = config.template
        .replaceAll('[SNI]', config.sniHost)
        .replaceAll('[HOST]', config.sshHost)
        .replaceAll('[PORT]', config.sshPort.toString())
        .replaceAll('[USER]', config.sshUser)
        .replaceAll('[USER_AGENT]', userAgent)
        .replaceAll('[WEBSOCKET_KEY]', websocketKey)
        .replaceAll('[METHOD]', 'CONNECT');
    
    return payload;
  }

  static Future<PayloadConfig> createCustomPayload({
    required String name,
    required String customTemplate,
    required String sniHost,
    required SshAccount sshAccount,
  }) async {
    return PayloadConfig(
      name: name,
      template: customTemplate,
      sniHost: sniHost,
      sshHost: sshAccount.host,
      sshPort: sshAccount.port,
      sshUser: sshAccount.user,
      sshPassword: sshAccount.password,
    );
  }

  static List<String> getTemplateNames() {
    return [
      'HTTP CONNECT',
      'HTTP GET',
      'WebSocket Upgrade',
      'HTTP Proxy',
      'Custom Inject',
    ];
  }

  static String getTemplate(int index) {
    if (index >= 0 && index < _payloadTemplates.length) {
      return _payloadTemplates[index];
    }
    return _payloadTemplates[0];
  }

  static Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      return {
        'model': androidInfo.model,
        'brand': androidInfo.brand,
        'version': androidInfo.version.release,
        'sdk': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
      };
    } catch (e) {
      return {
        'model': 'Unknown',
        'brand': 'Android',
        'version': '10',
        'sdk': 29,
        'manufacturer': 'Unknown',
      };
    }
  }

  static Future<String> generateStunnelConfig(PayloadConfig config) async {
    final stunnelTemplate = '''
[ssh-tunnel]
accept = 127.0.0.1:8080
connect = ${config.sshHost}:${config.sshPort}
cert = /data/data/com.zeroinjector/stunnel.pem
key = /data/data/com.zeroinjector/stunnel.key

[http-tunnel]
accept = 127.0.0.1:8888
connect = ${config.sniHost}:443
protocol = connect
protocolHost = ${config.sniHost}
''';
    
    return stunnelTemplate;
  }

  static Future<List<PayloadConfig>> loadSavedTemplates() async {
    try {
      final jsonString = await rootBundle.loadString('assets/payload_templates.json');
      final jsonData = json.decode(jsonString);
      
      final List<PayloadConfig> configs = [];
      for (final template in jsonData['templates']) {
        // Convert template to PayloadConfig format
        // This would need actual SSH and SNI data to be complete
      }
      
      return configs;
    } catch (e) {
      print('Error loading payload templates: $e');
      return [];
    }
  }
}