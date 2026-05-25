import 'package:flutter/material.dart';
import '../services/local_storage.dart';
import '../models/payload_config.dart';

class OfflineConfigsScreen extends StatefulWidget {
  const OfflineConfigsScreen({super.key});

  @override
  State<OfflineConfigsScreen> createState() => _OfflineConfigsScreenState();
}

class _OfflineConfigsScreenState extends State<OfflineConfigsScreen> {
  List<PayloadConfig> _configs = [];

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    final configs = await LocalStorage.instance.getPayloadConfigs();
    setState(() {
      _configs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Configs'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadConfigs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _configs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.offline_bolt, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No offline configurations saved',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create and save configurations from the Config Builder to access them offline.',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _configs.length,
              itemBuilder: (context, index) {
                final config = _configs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: config.isWorking ? Colors.green : Colors.grey,
                      child: Icon(
                        config.isWorking ? Icons.check : Icons.help_outline,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(config.name),
                    subtitle: Text('${config.sniHost} → ${config.sshHost}:${config.sshPort}'),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) async {
                        if (value == 'delete' && config.id != null) {
                          await LocalStorage.instance.deletePayloadConfig(config.id!);
                          _loadConfigs();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
