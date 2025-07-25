import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connection_tester.dart';
import '../services/local_storage.dart';
import '../models/payload_config.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  PayloadConfig? _selectedConfig;
  bool _autoMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final autoMode = LocalStorage.instance.getAutoMode();
    final activeConfigId = LocalStorage.instance.getActiveConfigId();
    
    setState(() {
      _autoMode = autoMode;
    });

    if (activeConfigId != null) {
      final configs = await LocalStorage.instance.getPayloadConfigs();
      final config = configs.where((c) => c.id == activeConfigId).firstOrNull;
      if (config != null) {
        setState(() {
          _selectedConfig = config;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectionTester>(
      builder: (context, connectionTester, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        connectionTester.isConnected 
                            ? Icons.wifi 
                            : Icons.wifi_off,
                        size: 48,
                        color: connectionTester.isConnected 
                            ? Colors.green 
                            : Colors.red,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        connectionTester.currentStatus,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (connectionTester.currentIp.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'IP: ${connectionTester.currentIp}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Control Panel
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Control Panel',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      
                      // Config Selection
                      DropdownButtonFormField<PayloadConfig>(
                        value: _selectedConfig,
                        decoration: const InputDecoration(
                          labelText: 'Select Configuration',
                          border: OutlineInputBorder(),
                        ),
                        items: [],
                        onChanged: (config) {
                          setState(() {
                            _selectedConfig = config;
                          });
                          if (config != null) {
                            LocalStorage.instance.setActiveConfig(config.id!);
                          }
                        },
                        hint: const Text('Choose a configuration'),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Auto Mode Toggle
                      SwitchListTile(
                        title: const Text('Auto Mode'),
                        subtitle: const Text('Automatically try all configurations'),
                        value: _autoMode,
                        onChanged: (value) {
                          setState(() {
                            _autoMode = value;
                          });
                          LocalStorage.instance.setAutoMode(value);
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Connect/Disconnect Button
                      ElevatedButton.icon(
                        onPressed: connectionTester.isTesting 
                            ? null 
                            : () => _handleConnectionToggle(connectionTester),
                        icon: Icon(
                          connectionTester.isConnected 
                              ? Icons.stop 
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          connectionTester.isTesting
                              ? 'Testing...'
                              : connectionTester.isConnected
                                  ? 'Disconnect'
                                  : 'Connect',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: connectionTester.isConnected 
                              ? Colors.red 
                              : Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Logs Section
              Expanded(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Connection Logs',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              onPressed: connectionTester.clearLogs,
                              icon: const Icon(Icons.clear),
                              tooltip: 'Clear logs',
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(16.0),
                          padding: const EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: connectionTester.logs.length,
                            itemBuilder: (context, index) {
                              final log = connectionTester.logs[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  log,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleConnectionToggle(ConnectionTester connectionTester) async {
    if (connectionTester.isConnected) {
      await connectionTester.disconnect();
    } else {
      if (_selectedConfig == null && !_autoMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a configuration or enable auto mode'),
          ),
        );
        return;
      }

      if (_autoMode) {
        await _startAutoMode(connectionTester);
      } else if (_selectedConfig != null) {
        await connectionTester.testConnection(_selectedConfig!);
      }
    }
  }

  Future<void> _startAutoMode(ConnectionTester connectionTester) async {
    final configs = await LocalStorage.instance.getPayloadConfigs();
    final workingConfigs = configs.where((c) => c.isSuccessful).toList();
    
    if (workingConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No working configurations found. Please scan for configs first.'),
        ),
      );
      return;
    }

    // Try working configs first
    for (final config in workingConfigs) {
      final success = await connectionTester.testConnection(config);
      if (success) {
        setState(() {
          _selectedConfig = config;
        });
        return;
      }
    }

    // If no working config succeeded, try all configs
    final allConfigs = await LocalStorage.instance.getPayloadConfigs();
    for (final config in allConfigs) {
      if (workingConfigs.contains(config)) continue; // Skip already tested
      
      final success = await connectionTester.testConnection(config);
      if (success) {
        setState(() {
          _selectedConfig = config;
        });
        // Mark as successful
        final updatedConfig = config.copyWith(isSuccessful: true);
        await LocalStorage.instance.updatePayloadConfig(updatedConfig);
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No working configuration found'),
      ),
    );
  }
}