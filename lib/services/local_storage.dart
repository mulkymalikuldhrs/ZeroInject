import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ssh_account.dart';
import '../models/sni_entry.dart';
import '../models/payload_config.dart';

class LocalStorage {
  static final LocalStorage _instance = LocalStorage._internal();
  static LocalStorage get instance => _instance;
  LocalStorage._internal();

  Database? _database;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'injector.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // SSH Accounts table
    await db.execute('''
      CREATE TABLE ssh_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user TEXT NOT NULL,
        host TEXT NOT NULL,
        port INTEGER NOT NULL,
        password TEXT NOT NULL,
        expired INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL
      )
    ''');

    // SNI Entries table
    await db.execute('''
      CREATE TABLE sni_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        host TEXT NOT NULL UNIQUE,
        port INTEGER NOT NULL DEFAULT 443,
        isActive INTEGER NOT NULL DEFAULT 0,
        responseTime INTEGER NOT NULL DEFAULT 0,
        lastChecked INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Payload Configs table
    await db.execute('''
      CREATE TABLE payload_configs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        template TEXT NOT NULL,
        sniHost TEXT NOT NULL,
        sshHost TEXT NOT NULL,
        sshPort INTEGER NOT NULL,
        sshUser TEXT NOT NULL,
        sshPassword TEXT NOT NULL,
        isSuccessful INTEGER NOT NULL DEFAULT 0,
        lastUsed INTEGER NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Insert default SNI hosts
    final defaultSnis = [
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
    ];

    for (final sni in defaultSnis) {
      await db.insert('sni_entries', {
        'host': sni,
        'port': 443,
        'isActive': 0,
        'responseTime': 0,
        'lastChecked': DateTime.now().millisecondsSinceEpoch,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
  }

  // SSH Accounts methods
  Future<List<SshAccount>> getSshAccounts() async {
    final db = _database!;
    final maps = await db.query('ssh_accounts', orderBy: 'createdAt DESC');
    return maps.map((map) => SshAccount.fromMap(map)).toList();
  }

  Future<int> insertSshAccount(SshAccount account) async {
    final db = _database!;
    return await db.insert('ssh_accounts', account.toMap());
  }

  Future<void> updateSshAccount(SshAccount account) async {
    final db = _database!;
    await db.update(
      'ssh_accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<void> deleteSshAccount(int id) async {
    final db = _database!;
    await db.delete('ssh_accounts', where: 'id = ?', whereArgs: [id]);
  }

  // SNI Entries methods
  Future<List<SniEntry>> getSniEntries() async {
    final db = _database!;
    final maps = await db.query('sni_entries', orderBy: 'isActive DESC, responseTime ASC');
    return maps.map((map) => SniEntry.fromMap(map)).toList();
  }

  Future<int> insertSniEntry(SniEntry entry) async {
    final db = _database!;
    return await db.insert('sni_entries', entry.toMap());
  }

  Future<void> updateSniEntry(SniEntry entry) async {
    final db = _database!;
    await db.update(
      'sni_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<void> deleteSniEntry(int id) async {
    final db = _database!;
    await db.delete('sni_entries', where: 'id = ?', whereArgs: [id]);
  }

  // Payload Configs methods
  Future<List<PayloadConfig>> getPayloadConfigs() async {
    final db = _database!;
    final maps = await db.query('payload_configs', orderBy: 'isSuccessful DESC, lastUsed DESC');
    return maps.map((map) => PayloadConfig.fromMap(map)).toList();
  }

  Future<int> insertPayloadConfig(PayloadConfig config) async {
    final db = _database!;
    return await db.insert('payload_configs', config.toMap());
  }

  Future<void> updatePayloadConfig(PayloadConfig config) async {
    final db = _database!;
    await db.update(
      'payload_configs',
      config.toMap(),
      where: 'id = ?',
      whereArgs: [config.id],
    );
  }

  Future<void> deletePayloadConfig(int id) async {
    final db = _database!;
    await db.delete('payload_configs', where: 'id = ?', whereArgs: [id]);
  }

  // SharedPreferences methods
  Future<void> setActiveConfig(int configId) async {
    await _prefs!.setInt('active_config_id', configId);
  }

  int? getActiveConfigId() {
    return _prefs!.getInt('active_config_id');
  }

  Future<void> setLastConnectionStatus(bool isConnected) async {
    await _prefs!.setBool('last_connection_status', isConnected);
  }

  bool getLastConnectionStatus() {
    return _prefs!.getBool('last_connection_status') ?? false;
  }

  Future<void> setAutoMode(bool enabled) async {
    await _prefs!.setBool('auto_mode', enabled);
  }

  bool getAutoMode() {
    return _prefs!.getBool('auto_mode') ?? false;
  }
}