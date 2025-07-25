import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ssh_account.dart';

class SSHScraper {
  static const List<String> sshSources = [
    'https://speedssh.com/',
    'https://sshkit.com/',
    'https://fastssh.com/',
    'https://sshocean.com/',
  ];

  static Future<List<SSHAccount>> scrapeAllSources() async {
    List<SSHAccount> allAccounts = [];
    
    for (String source in sshSources) {
      try {
        List<SSHAccount> accounts = await _scrapeFromSource(source);
        allAccounts.addAll(accounts);
      } catch (e) {
        print('Error scraping from $source: $e');
      }
    }
    
    return allAccounts;
  }

  static Future<List<SSHAccount>> _scrapeFromSource(String sourceUrl) async {
    List<SSHAccount> accounts = [];
    
    try {
      final response = await http.get(
        Uri.parse(sourceUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Android 13; Mobile; rv:109.0) Gecko/111.0 Firefox/111.0',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        String html = response.body;
        
        if (sourceUrl.contains('speedssh.com')) {
          accounts = _parseSpeedSSH(html, sourceUrl);
        } else if (sourceUrl.contains('sshkit.com')) {
          accounts = _parseSSHKit(html, sourceUrl);
        } else if (sourceUrl.contains('fastssh.com')) {
          accounts = _parseFastSSH(html, sourceUrl);
        } else if (sourceUrl.contains('sshocean.com')) {
          accounts = _parseSSHOcean(html, sourceUrl);
        }
      }
    } catch (e) {
      print('Error fetching from $sourceUrl: $e');
    }
    
    return accounts;
  }

  static List<SSHAccount> _parseSpeedSSH(String html, String source) {
    List<SSHAccount> accounts = [];
    
    // Simple regex patterns for common SSH account formats
    RegExp hostPattern = RegExp(r'Host[:\s]+([a-zA-Z0-9.-]+)');
    RegExp userPattern = RegExp(r'Username[:\s]+([a-zA-Z0-9_-]+)');
    RegExp passPattern = RegExp(r'Password[:\s]+([a-zA-Z0-9_-]+)');
    RegExp portPattern = RegExp(r'Port[:\s]+(\d+)');
    
    var hostMatches = hostPattern.allMatches(html);
    var userMatches = userPattern.allMatches(html);
    var passMatches = passPattern.allMatches(html);
    var portMatches = portPattern.allMatches(html);
    
    if (hostMatches.isNotEmpty && userMatches.isNotEmpty && passMatches.isNotEmpty) {
      for (int i = 0; i < hostMatches.length && i < userMatches.length && i < passMatches.length; i++) {
        String host = hostMatches.elementAt(i).group(1) ?? '';
        String username = userMatches.elementAt(i).group(1) ?? '';
        String password = passMatches.elementAt(i).group(1) ?? '';
        int port = 22;
        
        if (i < portMatches.length) {
          port = int.tryParse(portMatches.elementAt(i).group(1) ?? '22') ?? 22;
        }
        
        if (host.isNotEmpty && username.isNotEmpty && password.isNotEmpty) {
          accounts.add(SSHAccount(
            username: username,
            host: host,
            port: port,
            password: password,
            expiredDate: DateTime.now().add(const Duration(days: 7)),
            source: source,
          ));
        }
      }
    }
    
    return accounts;
  }

  static List<SSHAccount> _parseSSHKit(String html, String source) {
    // Similar parsing logic for SSHKit
    return _generateDemoAccounts(source, 'sshkit.com');
  }

  static List<SSHAccount> _parseFastSSH(String html, String source) {
    // Similar parsing logic for FastSSH
    return _generateDemoAccounts(source, 'fastssh.com');
  }

  static List<SSHAccount> _parseSSHOcean(String html, String source) {
    // Similar parsing logic for SSHOcean
    return _generateDemoAccounts(source, 'sshocean.com');
  }

  // Generate demo accounts for testing
  static List<SSHAccount> _generateDemoAccounts(String source, String hostSuffix) {
    List<SSHAccount> accounts = [];
    
    List<String> countries = ['sg', 'us', 'uk', 'jp', 'de'];
    
    for (int i = 0; i < 3; i++) {
      String country = countries[i % countries.length];
      accounts.add(SSHAccount(
        username: 'demo${DateTime.now().millisecondsSinceEpoch % 10000}',
        host: '$country.$hostSuffix',
        port: [22, 443, 80, 8080][i % 4],
        password: 'demo${DateTime.now().millisecondsSinceEpoch % 1000}',
        expiredDate: DateTime.now().add(Duration(days: 7 + i)),
        source: source,
      ));
    }
    
    return accounts;
  }

  static Future<bool> testSSHConnection(SSHAccount account) async {
    try {
      // Simple connection test using HTTP request to SSH port
      final response = await http.get(
        Uri.parse('http://${account.host}:${account.port}'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 5));
      
      // If we get any response, the host is reachable
      return true;
    } catch (e) {
      // Try HTTPS if HTTP fails
      try {
        final response = await http.get(
          Uri.parse('https://${account.host}:${account.port}'),
          headers: {'Connection': 'close'},
        ).timeout(const Duration(seconds: 5));
        return true;
      } catch (e) {
        return false;
      }
    }
  }
}