class PayloadConfig {
  final int? id;
  final String name;
  final String template;
  final String sniHost;
  final String sshHost;
  final int sshPort;
  final String sshUser;
  final String sshPassword;
  final bool isSuccessful;
  final DateTime lastUsed;
  final DateTime createdAt;

  PayloadConfig({
    this.id,
    required this.name,
    required this.template,
    required this.sniHost,
    required this.sshHost,
    required this.sshPort,
    required this.sshUser,
    required this.sshPassword,
    this.isSuccessful = false,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) : lastUsed = lastUsed ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'template': template,
      'sniHost': sniHost,
      'sshHost': sshHost,
      'sshPort': sshPort,
      'sshUser': sshUser,
      'sshPassword': sshPassword,
      'isSuccessful': isSuccessful ? 1 : 0,
      'lastUsed': lastUsed.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory PayloadConfig.fromMap(Map<String, dynamic> map) {
    return PayloadConfig(
      id: map['id'],
      name: map['name'],
      template: map['template'],
      sniHost: map['sniHost'],
      sshHost: map['sshHost'],
      sshPort: map['sshPort'],
      sshUser: map['sshUser'],
      sshPassword: map['sshPassword'],
      isSuccessful: map['isSuccessful'] == 1,
      lastUsed: DateTime.fromMillisecondsSinceEpoch(map['lastUsed']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  String generatePayload() {
    return template
        .replaceAll('[SNI]', sniHost)
        .replaceAll('[HOST]', sshHost)
        .replaceAll('[PORT]', sshPort.toString())
        .replaceAll('[USER]', sshUser);
  }

  PayloadConfig copyWith({
    int? id,
    String? name,
    String? template,
    String? sniHost,
    String? sshHost,
    int? sshPort,
    String? sshUser,
    String? sshPassword,
    bool? isSuccessful,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) {
    return PayloadConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      template: template ?? this.template,
      sniHost: sniHost ?? this.sniHost,
      sshHost: sshHost ?? this.sshHost,
      sshPort: sshPort ?? this.sshPort,
      sshUser: sshUser ?? this.sshUser,
      sshPassword: sshPassword ?? this.sshPassword,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'PayloadConfig{name: $name, sniHost: $sniHost, sshHost: $sshHost}';
  }
}