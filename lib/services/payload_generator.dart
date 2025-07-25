import 'dart:convert';
import 'dart:math';
import '../models/payload_config.dart';
import '../models/ssh_account.dart';
import '../models/sni_entry.dart';

class PayloadGenerator {
  static const List<String> userAgents = [
    'Mozilla/5.0 (Android 13; Mobile; rv:109.0) Gecko/111.0 Firefox/111.0',
    'Mozilla/5.0 (Linux; Android 13; SM-G991B) AppleWebKit/537.36',
    'Mozilla/5.0 (Linux; Android 12; Pixel 6) AppleWebKit/537.36',
    'Mozilla/5.0 (Android 11; Mobile; rv:68.0) Gecko/68.0 Firefox/88.0',
  ];

  static const List<Map<String, String>> payloadTemplates = [
    {
      'name': 'CONNECT Method',
      'template': '''CONNECT [SNI]:443 HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
X-Forward-Host: [SNI]
Connection: Keep-Alive
User-Agent: [USER_AGENT]
Proxy-Connection: Keep-Alive

'''
    },
    {
      'name': 'GET Method with SNI',
      'template': '''GET / HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
X-Forward-Host: [SNI]
User-Agent: [USER_AGENT]
Connection: Keep-Alive

'''
    },
    {
      'name': 'POST Method',
      'template': '''POST / HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
Content-Length: 0
User-Agent: [USER_AGENT]
Connection: Keep-Alive

'''
    },
    {
      'name': 'WebSocket Upgrade',
      'template': '''GET / HTTP/1.1
Host: [SNI]
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: [RANDOM_KEY]
Sec-WebSocket-Version: 13
User-Agent: [USER_AGENT]

'''
    },
    {
      'name': 'HTTP Proxy',
      'template': '''CONNECT [SSH_HOST]:[SSH_PORT] HTTP/1.1
Host: [SNI]
X-Online-Host: [SNI]
Proxy-Connection: Keep-Alive
User-Agent: [USER_AGENT]

'''
    }
  ];

  static List<PayloadConfig> generatePayloads(
    List<SNIEntry> workingSNIs,
    List<SSHAccount> sshAccounts,
  ) {
    List<PayloadConfig> configs = [];
    
    for (SNIEntry sni in workingSNIs) {
      for (SSHAccount ssh in sshAccounts) {
        for (Map<String, String> template in payloadTemplates) {
          String payload = _buildPayload(template['template']!, sni, ssh);
          
          configs.add(PayloadConfig(
            name: '${template['name']} - ${sni.hostname}',
            payload: payload,
            sniHost: sni.hostname,
            sshHost: ssh.host,
            sshPort: ssh.port,
          ));
        }
      }
    }
    
    return configs;
  }

  static String _buildPayload(String template, SNIEntry sni, SSHAccount ssh) {
    String payload = template;
    
    // Replace placeholders
    payload = payload.replaceAll('[SNI]', sni.hostname);
    payload = payload.replaceAll('[SSH_HOST]', ssh.host);
    payload = payload.replaceAll('[SSH_PORT]', ssh.port.toString());
    payload = payload.replaceAll('[USER_AGENT]', _getRandomUserAgent());
    payload = payload.replaceAll('[RANDOM_KEY]', _generateRandomKey());
    
    return payload;
  }

  static String _getRandomUserAgent() {
    return userAgents[Random().nextInt(userAgents.length)];
  }

  static String _generateRandomKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  static PayloadConfig createCustomPayload({
    required String name,
    required String sniHost,
    required String sshHost,
    required int sshPort,
    String? customTemplate,
  }) {
    String template = customTemplate ?? payloadTemplates[0]['template']!;
    
    SNIEntry sni = SNIEntry(hostname: sniHost, isWorking: true);
    SSHAccount ssh = SSHAccount(
      username: 'custom',
      host: sshHost,
      port: sshPort,
      password: 'custom',
      expiredDate: DateTime.now().add(const Duration(days: 30)),
      source: 'custom',
    );
    
    String payload = _buildPayload(template, sni, ssh);
    
    return PayloadConfig(
      name: name,
      payload: payload,
      sniHost: sniHost,
      sshHost: sshHost,
      sshPort: sshPort,
    );
  }

  static String generateStunnelConfig({
    required String sshHost,
    required int sshPort,
    required String sniHost,
    int localPort = 4443,
  }) {
    return '''
[stunnel]
cert = /system/etc/security/cacerts/
key = /system/etc/security/cacerts/
client = yes
debug = 4

[ssh-tunnel]
accept = 127.0.0.1:$localPort
connect = $sshHost:$sshPort
cert = /system/etc/security/cacerts/
verifyChain = no
checkHost = $sniHost
sni = $sniHost
''';
  }
}