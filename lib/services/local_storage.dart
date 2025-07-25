import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/ssh_account.dart';
import '../models/sni_entry.dart';
import '../models/payload_config.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  factory LocalStorage() => _instance;
  LocalStorage._internal();
  
  static LocalStorage get instance => _instance;
  
  Database? _database;

  Future<Database> get database async {
    _database ??= await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'injector.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // SSH Accounts table
        await db.execute('''
          CREATE TABLE ssh_accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL,
            host TEXT NOT NULL,
            port INTEGER NOT NULL,
            password TEXT NOT NULL,
            expired_date TEXT NOT NULL,
            source TEXT NOT NULL,
            is_active INTEGER DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');

        // SNI Entries table
        await db.execute('''
          CREATE TABLE sni_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            hostname TEXT NOT NULL UNIQUE,
            port INTEGER DEFAULT 443,
            is_working INTEGER DEFAULT 0,
            response_time INTEGER DEFAULT 0,
            error_message TEXT,
            last_tested TEXT NOT NULL,
            category TEXT DEFAULT 'general'
          )
        ''');

        // Payload Configs table
        await db.execute('''
          CREATE TABLE payload_configs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            payload TEXT NOT NULL,
            sni_host TEXT NOT NULL,
            ssh_host TEXT NOT NULL,
            ssh_port INTEGER NOT NULL,
            is_working INTEGER DEFAULT 0,
            last_used TEXT NOT NULL,
            success_count INTEGER DEFAULT 0
          )
        ''');

        // Insert default SNI entries
        await _insertDefaultSNIs(db);
      },
    );
  }

  Future<void> _insertDefaultSNIs(Database db) async {
    final defaultSNIs = [
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
    ];

    for (String sni in defaultSNIs) {
      await db.insert('sni_entries', {
        'hostname': sni,
        'port': 443,
        'is_working': 0,
        'response_time': 0,
        'last_tested': DateTime.now().toIso8601String(),
        'category': 'social',
      });
    }
  }

  // SSH Account operations
  Future<int> insertSSHAccount(SSHAccount account) async {
    final db = await database;
    return await db.insert('ssh_accounts', account.toMap());
  }

  Future<List<SSHAccount>> getSSHAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ssh_accounts',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SSHAccount.fromMap(maps[i]));
  }

  Future<List<SSHAccount>> getActiveSSHAccounts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'ssh_accounts',
      where: 'is_active = ? AND expired_date > ?',
      whereArgs: [1, DateTime.now().toIso8601String()],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => SSHAccount.fromMap(maps[i]));
  }

  Future<void> deleteSSHAccount(int id) async {
    final db = await database;
    await db.delete('ssh_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // SNI Entry operations
  Future<int> insertSNIEntry(SNIEntry entry) async {
    final db = await database;
    return await db.insert(
      'sni_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SNIEntry>> getSNIEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sni_entries',
      orderBy: 'is_working DESC, last_tested DESC',
    );
    return List.generate(maps.length, (i) => SNIEntry.fromMap(maps[i]));
  }

  Future<List<SNIEntry>> getWorkingSNIs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sni_entries',
      where: 'is_working = ?',
      whereArgs: [1],
      orderBy: 'response_time ASC',
    );
    return List.generate(maps.length, (i) => SNIEntry.fromMap(maps[i]));
  }

  Future<void> updateSNIEntry(SNIEntry entry) async {
    final db = await database;
    await db.update(
      'sni_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // Payload Config operations
  Future<int> insertPayloadConfig(PayloadConfig config) async {
    final db = await database;
    return await db.insert('payload_configs', config.toMap());
  }

  Future<List<PayloadConfig>> getPayloadConfigs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payload_configs',
      orderBy: 'success_count DESC, last_used DESC',
    );
    return List.generate(maps.length, (i) => PayloadConfig.fromMap(maps[i]));
  }

  Future<List<PayloadConfig>> getWorkingConfigs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'payload_configs',
      where: 'is_working = ?',
      whereArgs: [1],
      orderBy: 'success_count DESC',
    );
    return List.generate(maps.length, (i) => PayloadConfig.fromMap(maps[i]));
  }

  Future<void> updatePayloadConfig(PayloadConfig config) async {
    final db = await database;
    await db.update(
      'payload_configs',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  Future<void> deletePayloadConfig(int id) async {
    final db = await database;
    await db.delete('payload_configs', where: 'id = ?', whereArgs: [id]);
  }
}