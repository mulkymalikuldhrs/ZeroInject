class SNIEntry {
  final int? id;
  final String hostname;
  final int port;
  final bool isWorking;
  final int responseTime;
  final String? errorMessage;
  final DateTime lastTested;
  final String category;

  SNIEntry({
    this.id,
    required this.hostname,
    this.port = 443,
    required this.isWorking,
    this.responseTime = 0,
    this.errorMessage,
    DateTime? lastTested,
    this.category = 'general',
  }) : lastTested = lastTested ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hostname': hostname,
      'port': port,
      'is_working': isWorking ? 1 : 0,
      'response_time': responseTime,
      'error_message': errorMessage,
      'last_tested': lastTested.toIso8601String(),
      'category': category,
    };
  }

  factory SNIEntry.fromMap(Map<String, dynamic> map) {
    return SNIEntry(
      id: map['id'],
      hostname: map['hostname'],
      port: map['port'],
      isWorking: map['is_working'] == 1,
      responseTime: map['response_time'],
      errorMessage: map['error_message'],
      lastTested: DateTime.parse(map['last_tested']),
      category: map['category'],
    );
  }

  @override
  String toString() {
    return '$hostname:$port (${isWorking ? 'Working' : 'Failed'})';
  }
}