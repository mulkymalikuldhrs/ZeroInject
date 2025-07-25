import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payload_config.dart';
import '../services/local_storage.dart';
import '../services/connection_tester.dart';

class OfflineConfigsScreen extends StatefulWidget {
  const OfflineConfigsScreen({super.key});

  @override
  State<OfflineConfigsScreen> createState() => _OfflineConfigsScreenState();
}

class _OfflineConfigsScreenState extends State<OfflineConfigsScreen> {
  List<PayloadConfig> _workingConfigs = [];
  List<PayloadConfig> _allConfigs = [];
  bool _isLoading = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadConfigs();
  }

  Future<void> _loadConfigs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final allConfigs = await LocalStorage.instance.getPayloadConfigs();
      final workingConfigs = allConfigs.where((c) => c.isSuccessful).toList();
      
      setState(() {
        _allConfigs = allConfigs;
        _workingConfigs = workingConfigs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading configurations: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testAllConfigs() async {
    if (_allConfigs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No configurations to test')),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    final connectionTester = Provider.of<ConnectionTester>(context, listen: false);
    
    try {
      final workingConfigs = await connectionTester.testMultipleConfigs(_allConfigs);
      
      // Update database with successful configs
      for (final config in workingConfigs) {
        await LocalStorage.instance.updatePayloadConfig(config);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${workingConfigs.length} working configurations')),
      );
      
      _loadConfigs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error testing configurations: $e')),
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Offline Configurations',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Working',
                        _workingConfigs.length.toString(),
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Total',
                        _allConfigs.length.toString(),
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Success Rate',
                        _allConfigs.isEmpty 
                            ? '0%' 
                            : '${((_workingConfigs.length / _allConfigs.length) * 100).toInt()}%',
                        Colors.orange,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testAllConfigs,
                    icon: _isTesting 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.speed),
                    label: Text(_isTesting ? 'Testing...' : 'Test All Configurations'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tabs for working vs all configs
          DefaultTabController(
            length: 2,
            child: Expanded(
              child: Card(
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Working Configs'),
                        Tab(text: 'All Configs'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildConfigList(_workingConfigs, isWorkingTab: true),
                          _buildConfigList(_allConfigs, isWorkingTab: false),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildConfigList(List<PayloadConfig> configs, {required bool isWorkingTab}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (configs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWorkingTab ? Icons.check_circle_outline : Icons.settings,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isWorkingTab 
                  ? 'No working configurations found'
                  : 'No configurations available',
            ),
            const SizedBox(height: 8),
            Text(
              isWorkingTab
                  ? 'Test configurations to find working ones'
                  : 'Create configurations in Config Builder',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: configs.length,
      itemBuilder: (context, index) {
        final config = configs[index];
        return _buildConfigTile(config);
      },
    );
  }

  Widget _buildConfigTile(PayloadConfig config) {
    final lastUsed = DateTime.now().difference(config.lastUsed);
    final lastUsedText = lastUsed.inMinutes < 1 
        ? 'Just now'
        : lastUsed.inHours < 1
            ? '${lastUsed.inMinutes}m ago'
            : lastUsed.inDays < 1
                ? '${lastUsed.inHours}h ago'
                : '${lastUsed.inDays}d ago';

    return Consumer<ConnectionTester>(
      builder: (context, connectionTester, child) {
        final isActive = connectionTester.activeConfig?.id == config.id;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: config.isSuccessful 
                ? (isActive ? Colors.blue : Colors.green)
                : Colors.grey,
            child: Icon(
              config.isSuccessful 
                  ? (isActive ? Icons.wifi : Icons.check)
                  : Icons.help_outline,
              color: Colors.white,
            ),
          ),
          title: Text(
            config.name,
            style: TextStyle(
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${config.sniHost} → ${config.sshHost}:${config.sshPort}'),
              Text(
                'Last used: $lastUsedText',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (isActive)
                const Text(
                  'Currently active',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'test',
                child: Text('Test Connection'),
              ),
              const PopupMenuItem(
                value: 'connect',
                child: Text('Connect'),
              ),
              const PopupMenuItem(
                value: 'details',
                child: Text('View Details'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export Config'),
              ),
            ],
            onSelected: (value) => _handleConfigAction(value, config),
          ),
          onTap: () => _showConfigDetails(config),
        );
      },
    );
  }

  void _handleConfigAction(String action, PayloadConfig config) async {
    final connectionTester = Provider.of<ConnectionTester>(context, listen: false);
    
    switch (action) {
      case 'test':
        _testSingleConfig(config);
        break;
      case 'connect':
        await connectionTester.testConnection(config);
        break;
      case 'details':
        _showConfigDetails(config);
        break;
      case 'export':
        _exportConfig(config);
        break;
    }
  }

  Future<void> _testSingleConfig(PayloadConfig config) async {
    final connectionTester = Provider.of<ConnectionTester>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing configuration...'),
          ],
        ),
      ),
    );

    try {
      final success = await connectionTester.testConnection(config);
      
      if (success) {
        // Update config as successful
        final updatedConfig = config.copyWith(
          isSuccessful: true,
          lastUsed: DateTime.now(),
        );
        await LocalStorage.instance.updatePayloadConfig(updatedConfig);
        _loadConfigs();
      }
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Configuration works!'
                : 'Configuration failed',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error testing configuration: $e')),
      );
    }
  }

  void _showConfigDetails(PayloadConfig config) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(config.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SNI Host: ${config.sniHost}'),
              Text('SSH Host: ${config.sshHost}'),
              Text('SSH Port: ${config.sshPort}'),
              Text('SSH User: ${config.sshUser}'),
              Text('Status: ${config.isSuccessful ? 'Working' : 'Untested'}'),
              Text('Last Used: ${config.lastUsed.toString().substring(0, 19)}'),
              Text('Created: ${config.createdAt.toString().substring(0, 19)}'),
              const SizedBox(height: 16),
              const Text('Payload Template:'),
              Container(
                width: double.maxFinite,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  config.template,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportConfig(PayloadConfig config) {
    final configText = '''
Configuration: ${config.name}
SNI Host: ${config.sniHost}
SSH Host: ${config.sshHost}
SSH Port: ${config.sshPort}
SSH User: ${config.sshUser}
SSH Password: ${config.sshPassword}
Status: ${config.isSuccessful ? 'Working' : 'Untested'}

Payload Template:
${config.template}
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Configuration'),
        content: SingleChildScrollView(
          child: SelectableText(
            configText,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}