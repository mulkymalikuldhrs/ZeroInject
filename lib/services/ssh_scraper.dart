import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ssh_account.dart';

class SshScraper {
  static const List<String> _sshSites = [
    'https://speedssh.com/api/free-ssh',
    'https://sshkit.com/api/free-accounts',
    'https://fastssh.com/api/accounts',
  ];

  static Future<List<SshAccount>> fetchFreeAccounts() async {
    final List<SshAccount> accounts = [];
    
    for (final site in _sshSites) {
      try {
        final siteAccounts = await _fetchFromSite(site);
        accounts.addAll(siteAccounts);
      } catch (e) {
        print('Error fetching from $site: $e');
      }
    }
    
    return accounts;
  }

  static Future<List<SshAccount>> _fetchFromSite(String url) async {
    final List<SshAccount> accounts = [];
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'ZeroInjector/1.0 (Android)',
          'Accept': 'application/json, text/html',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (url.contains('speedssh.com')) {
          accounts.addAll(_parseSpeedSSH(response.body));
        } else if (url.contains('sshkit.com')) {
          accounts.addAll(_parseSSHKit(response.body));
        } else if (url.contains('fastssh.com')) {
          accounts.addAll(_parseFastSSH(response.body));
        }
      }
    } catch (e) {
      print('Error parsing $url: $e');
    }
    
    return accounts;
  }

  static List<SshAccount> _parseSpeedSSH(String html) {
    final List<SshAccount> accounts = [];
    
    try {
      // Parse HTML untuk mencari pattern SSH account
      final RegExp hostRegex = RegExp(r'Host:\s*([^\s]+)');
      final RegExp userRegex = RegExp(r'Username:\s*([^\s]+)');
      final RegExp passRegex = RegExp(r'Password:\s*([^\s]+)');
      final RegExp portRegex = RegExp(r'Port:\s*(\d+)');
      final RegExp expiredRegex = RegExp(r'Expired:\s*([^\n]+)');

      final hostMatches = hostRegex.allMatches(html);
      final userMatches = userRegex.allMatches(html);
      final passMatches = passRegex.allMatches(html);
      final portMatches = portRegex.allMatches(html);
      final expiredMatches = expiredRegex.allMatches(html);

      final minLength = [
        hostMatches.length,
        userMatches.length,
        passMatches.length,
        portMatches.length,
        expiredMatches.length,
      ].reduce((a, b) => a < b ? a : b);

      final hostList = hostMatches.take(minLength).map((m) => m.group(1)!).toList();
      final userList = userMatches.take(minLength).map((m) => m.group(1)!).toList();
      final passList = passMatches.take(minLength).map((m) => m.group(1)!).toList();
      final portList = portMatches.take(minLength).map((m) => int.parse(m.group(1)!)).toList();
      final expiredList = expiredMatches.take(minLength).map((m) => m.group(1)!).toList();

      for (int i = 0; i < minLength; i++) {
        final expiredDate = _parseExpiredDate(expiredList[i]);
        if (expiredDate.isAfter(DateTime.now())) {
          accounts.add(SshAccount(
            user: userList[i],
            host: hostList[i],
            port: portList[i],
            password: passList[i],
            expired: expiredDate,
          ));
        }
      }
    } catch (e) {
      print('Error parsing SpeedSSH: $e');
    }
    
    return accounts;
  }

  static List<SshAccount> _parseSSHKit(String html) {
    final List<SshAccount> accounts = [];
    
    try {
      // Simulasi parsing untuk SSHKit
      final RegExp accountRegex = RegExp(
        r'<div class="account">.*?Host:\s*([^\s<]+).*?User:\s*([^\s<]+).*?Pass:\s*([^\s<]+).*?Port:\s*(\d+).*?Expired:\s*([^<]+).*?</div>',
        dotAll: true,
      );

      final matches = accountRegex.allMatches(html);
      
      for (final match in matches) {
        final host = match.group(1)!;
        final user = match.group(2)!;
        final password = match.group(3)!;
        final port = int.parse(match.group(4)!);
        final expiredStr = match.group(5)!;
        
        final expiredDate = _parseExpiredDate(expiredStr);
        if (expiredDate.isAfter(DateTime.now())) {
          accounts.add(SshAccount(
            user: user,
            host: host,
            port: port,
            password: password,
            expired: expiredDate,
          ));
        }
      }
    } catch (e) {
      print('Error parsing SSHKit: $e');
    }
    
    return accounts;
  }

  static List<SshAccount> _parseFastSSH(String html) {
    final List<SshAccount> accounts = [];
    
    try {
      // Simulasi parsing untuk FastSSH
      if (html.contains('application/json')) {
        final jsonData = json.decode(html);
        if (jsonData is Map && jsonData.containsKey('accounts')) {
          final accountsList = jsonData['accounts'] as List;
          
          for (final account in accountsList) {
            final expiredDate = DateTime.tryParse(account['expired']) ?? 
                               DateTime.now().add(const Duration(days: 1));
            
            if (expiredDate.isAfter(DateTime.now())) {
              accounts.add(SshAccount.fromJson(account));
            }
          }
        }
      }
    } catch (e) {
      print('Error parsing FastSSH: $e');
    }
    
    return accounts;
  }

  static DateTime _parseExpiredDate(String dateStr) {
    try {
      // Try different date formats
      final formats = [
        RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
        RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
        RegExp(r'(\d{2})-(\d{2})-(\d{4})'),
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateStr);
        if (match != null) {
          if (dateStr.contains('-') && match.group(1)!.length == 4) {
            // YYYY-MM-DD format
            return DateTime(
              int.parse(match.group(1)!),
              int.parse(match.group(2)!),
              int.parse(match.group(3)!),
            );
          } else {
            // DD/MM/YYYY or DD-MM-YYYY format
            return DateTime(
              int.parse(match.group(3)!),
              int.parse(match.group(2)!),
              int.parse(match.group(1)!),
            );
          }
        }
      }
    } catch (e) {
      print('Error parsing date: $dateStr, $e');
    }
    
    // Default to tomorrow if parsing fails
    return DateTime.now().add(const Duration(days: 1));
  }

  static Future<List<SshAccount>> getDefaultAccounts() async {
    // Fallback accounts jika scraping gagal
    return [
      SshAccount(
        user: 'demo',
        host: 'sg1.sshkit.org',
        port: 443,
        password: 'demo123',
        expired: DateTime.now().add(const Duration(days: 1)),
      ),
      SshAccount(
        user: 'trial',
        host: 'us.speedssh.com',
        port: 80,
        password: 'trial123',
        expired: DateTime.now().add(const Duration(days: 1)),
      ),
    ];
  }
}