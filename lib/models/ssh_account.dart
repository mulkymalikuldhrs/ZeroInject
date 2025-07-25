class SSHAccount {
  final int? id;
  final String username;
  final String host;
  final int port;
  final String password;
  final DateTime expiredDate;
  final String source;
  final bool isActive;
  final DateTime createdAt;

  SSHAccount({
    this.id,
    required this.username,
    required this.host,
    required this.port,
    required this.password,
    required this.expiredDate,
    required this.source,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'host': host,
      'port': port,
      'password': password,
      'expired_date': expiredDate.toIso8601String(),
      'source': source,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SSHAccount.fromMap(Map<String, dynamic> map) {
    return SSHAccount(
      id: map['id'],
      username: map['username'],
      host: map['host'],
      port: map['port'],
      password: map['password'],
      expiredDate: DateTime.parse(map['expired_date']),
      source: map['source'],
      isActive: map['is_active'] == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiredDate);

  @override
  String toString() {
    return '$username@$host:$port (${source})';
  }
}