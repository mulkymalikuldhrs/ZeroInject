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
  List<PayloadConfig> _workingConfigs = [];
  PayloadConfig? _selectedConfig;

  @override
  void initState() {
    super.initState();
    _loadWorkingConfigs();
  }

  Future<void> _loadWorkingConfigs() async {
    final configs = await LocalStorage.instance.getWorkingConfigs();
    setState(() {
      _workingConfigs = configs;
      if (configs.isNotEmpty) {
        _selectedConfig = configs.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroInjector Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ConnectionTester>(
        builder: (context, tester, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              tester.isConnected ? Icons.wifi : Icons.wifi_off,
                              color: tester.isConnected ? Colors.green : Colors.red,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tester.isConnected ? 'Connected' : 'Disconnected',
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      color: tester.isConnected ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    tester.currentStatus,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (tester.currentIP.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.public, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'External IP: ${tester.currentIP}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Connect Section
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Connect',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (_workingConfigs.isNotEmpty) ...[
                          DropdownButtonFormField<PayloadConfig>(
                            value: _selectedConfig,
                            decoration: const InputDecoration(
                              labelText: 'Select Configuration',
                              border: OutlineInputBorder(),
                            ),
                            items: _workingConfigs.map((config) {
                              return DropdownMenuItem(
                                value: config,
                                child: Text(
                                  config.name,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (config) {
                              setState(() {
                                _selectedConfig = config;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: tester.isTesting || _selectedConfig == null
                                    ? null
                                    : () async {
                                        if (tester.isConnected) {
                                          await tester.disconnect();
                                        } else {
                                          await tester.testPayloadConfig(_selectedConfig!);
                                        }
                                      },
                                icon: tester.isTesting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Icon(tester.isConnected ? Icons.stop : Icons.play_arrow),
                                label: Text(
                                  tester.isTesting
                                      ? 'Connecting...'
                                      : tester.isConnected
                                          ? 'Disconnect'
                                          : 'Connect',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tester.isConnected ? Colors.red : Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _loadWorkingConfigs,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ],
                        ),

                        if (_workingConfigs.isEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning, color: Colors.orange),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No working configurations found. Please create and test configurations first.',
                                    style: TextStyle(color: Colors.orange),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Connection Logs
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Connection Logs',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: tester.clearLogs,
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: tester.logs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No logs yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(8),
                                  itemCount: tester.logs.length,
                                  itemBuilder: (context, index) {
                                    final log = tester.logs[index];
                                    Color textColor = Colors.white;
                                    
                                    if (log.contains('✅')) {
                                      textColor = Colors.green;
                                    } else if (log.contains('❌')) {
                                      textColor = Colors.red;
                                    } else if (log.contains('🎉')) {
                                      textColor = Colors.yellow;
                                    }
                                    
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Text(
                                        log,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Statistics Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistics',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Working Configs',
                                _workingConfigs.length.toString(),
                                Icons.check_circle,
                                Colors.green,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Connection Status',
                                tester.isConnected ? 'Online' : 'Offline',
                                tester.isConnected ? Icons.wifi : Icons.wifi_off,
                                tester.isConnected ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}