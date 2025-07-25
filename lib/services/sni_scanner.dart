import 'dart:io';
import 'dart:async';
import '../models/sni_entry.dart';

class SNIScanner {
  static const List<String> commonSNIs = [
    // Social Media Zero-rated
    'zero.facebook.com',
    'm.facebook.com',
    'graph.facebook.com',
    'api.whatsapp.com',
    'web.whatsapp.com',
    'static.whatsapp.net',
    'mmg.whatsapp.net',
    'media.whatsapp.net',
    'www.instagram.com',
    'api.instagram.com',
    'scontent.cdninstagram.com',
    'twitter.com',
    'api.twitter.com',
    'abs.twimg.com',
    'pbs.twimg.com',
    
    // CDN and Cloud Services
    'cloudflare.com',
    'www.cloudflare.com',
    'cdnjs.cloudflare.com',
    'ajax.cloudflare.com',
    'fonts.googleapis.com',
    'ajax.googleapis.com',
    'www.googleapis.com',
    'storage.googleapis.com',
    
    // Popular websites that might be zero-rated
    'www.google.com',
    'google.com',
    'www.youtube.com',
    'youtube.com',
    'www.wikipedia.org',
    'wikipedia.org',
    
    // Telecom specific
    'www.telkomsel.com',
    'telkomsel.com',
    'www.indosat.com',
    'indosat.com',
    'www.xl.co.id',
    'xl.co.id',
    'www.smartfren.com',
    'smartfren.com',
  ];

  static Future<List<SNIEntry>> scanAllSNIs() async {
    List<SNIEntry> results = [];
    
    for (String hostname in commonSNIs) {
      SNIEntry result = await testSNI(hostname);
      results.add(result);
    }
    
    return results;
  }

  static Future<SNIEntry> testSNI(String hostname, {int port = 443}) async {
    Stopwatch stopwatch = Stopwatch()..start();
    
    try {
      // Test TLS handshake
      SecureSocket socket = await SecureSocket.connect(
        hostname,
        port,
        timeout: const Duration(seconds: 10),
        onBadCertificate: (certificate) => true, // Accept any certificate for testing
      );
      
      stopwatch.stop();
      await socket.close();
      
      return SNIEntry(
        hostname: hostname,
        port: port,
        isWorking: true,
        responseTime: stopwatch.elapsedMilliseconds,
        category: _categorizeSNI(hostname),
      );
      
    } catch (e) {
      stopwatch.stop();
      
      return SNIEntry(
        hostname: hostname,
        port: port,
        isWorking: false,
        responseTime: stopwatch.elapsedMilliseconds,
        errorMessage: e.toString(),
        category: _categorizeSNI(hostname),
      );
    }
  }

  static String _categorizeSNI(String hostname) {
    if (hostname.contains('facebook') || hostname.contains('whatsapp') || 
        hostname.contains('instagram') || hostname.contains('twitter')) {
      return 'social';
    } else if (hostname.contains('google') || hostname.contains('cloudflare')) {
      return 'cdn';
    } else if (hostname.contains('telkomsel') || hostname.contains('indosat') || 
               hostname.contains('xl.co.id') || hostname.contains('smartfren')) {
      return 'telecom';
    } else {
      return 'general';
    }
  }

  static Future<bool> testHTTPSConnection(String hostname, {int port = 443}) async {
    try {
      HttpClient client = HttpClient();
      client.badCertificateCallback = (cert, host, port) => true;
      
      HttpClientRequest request = await client.getUrl(
        Uri.parse('https://$hostname:$port/')
      );
      request.headers.set('User-Agent', 'Mozilla/5.0 (Android 13; Mobile; rv:109.0)');
      
      HttpClientResponse response = await request.close();
      await response.drain();
      
      return response.statusCode < 500;
    } catch (e) {
      return false;
    }
  }
}