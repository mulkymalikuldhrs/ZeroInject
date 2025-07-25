class PayloadConfig {
  final int? id;
  final String name;
  final String payload;
  final String sniHost;
  final String sshHost;
  final int sshPort;
  final bool isWorking;
  final DateTime lastUsed;
  final int successCount;

  PayloadConfig({
    this.id,
    required this.name,
    required this.payload,
    required this.sniHost,
    required this.sshHost,
    required this.sshPort,
    this.isWorking = false,
    DateTime? lastUsed,
    this.successCount = 0,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'payload': payload,
      'sni_host': sniHost,
      'ssh_host': sshHost,
      'ssh_port': sshPort,
      'is_working': isWorking ? 1 : 0,
      'last_used': lastUsed.toIso8601String(),
      'success_count': successCount,
    };
  }

  factory PayloadConfig.fromMap(Map<String, dynamic> map) {
    return PayloadConfig(
      id: map['id'],
      name: map['name'],
      payload: map['payload'],
      sniHost: map['sni_host'],
      sshHost: map['ssh_host'],
      sshPort: map['ssh_port'],
      isWorking: map['is_working'] == 1,
      lastUsed: DateTime.parse(map['last_used']),
      successCount: map['success_count'],
    );
  }

  @override
  String toString() {
    return '$name (${isWorking ? 'Working' : 'Untested'})';
  }
}