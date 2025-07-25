class SniEntry {
  final int? id;
  final String host;
  final int port;
  final bool isActive;
  final int responseTime;
  final DateTime lastChecked;
  final DateTime createdAt;

  SniEntry({
    this.id,
    required this.host,
    this.port = 443,
    this.isActive = false,
    this.responseTime = 0,
    DateTime? lastChecked,
    DateTime? createdAt,
  }) : lastChecked = lastChecked ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'host': host,
      'port': port,
      'isActive': isActive ? 1 : 0,
      'responseTime': responseTime,
      'lastChecked': lastChecked.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory SniEntry.fromMap(Map<String, dynamic> map) {
    return SniEntry(
      id: map['id'],
      host: map['host'],
      port: map['port'],
      isActive: map['isActive'] == 1,
      responseTime: map['responseTime'],
      lastChecked: DateTime.fromMillisecondsSinceEpoch(map['lastChecked']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  SniEntry copyWith({
    int? id,
    String? host,
    int? port,
    bool? isActive,
    int? responseTime,
    DateTime? lastChecked,
    DateTime? createdAt,
  }) {
    return SniEntry(
      id: id ?? this.id,
      host: host ?? this.host,
      port: port ?? this.port,
      isActive: isActive ?? this.isActive,
      responseTime: responseTime ?? this.responseTime,
      lastChecked: lastChecked ?? this.lastChecked,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get displayName => '$host:$port';

  @override
  String toString() {
    return 'SniEntry{host: $host, port: $port, isActive: $isActive, responseTime: ${responseTime}ms}';
  }
}