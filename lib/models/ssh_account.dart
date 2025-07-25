class SshAccount {
  final int? id;
  final String user;
  final String host;
  final int port;
  final String password;
  final DateTime expired;
  final bool isActive;
  final DateTime createdAt;

  SshAccount({
    this.id,
    required this.user,
    required this.host,
    required this.port,
    required this.password,
    required this.expired,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user': user,
      'host': host,
      'port': port,
      'password': password,
      'expired': expired.millisecondsSinceEpoch,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SshAccount.fromMap(Map<String, dynamic> map) {
    return SshAccount(
      id: map['id'],
      user: map['user'],
      host: map['host'],
      port: map['port'],
      password: map['password'],
      expired: DateTime.fromMillisecondsSinceEpoch(map['expired']),
      isActive: map['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  factory SshAccount.fromJson(Map<String, dynamic> json) {
    return SshAccount(
      user: json['user'] ?? '',
      host: json['host'] ?? '',
      port: json['port'] ?? 22,
      password: json['password'] ?? '',
      expired: DateTime.tryParse(json['expired'] ?? '') ?? DateTime.now().add(const Duration(days: 1)),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expired);

  String get displayName => '$user@$host:$port';

  @override
  String toString() {
    return 'SshAccount{user: $user, host: $host, port: $port, expired: $expired}';
  }
}