import 'package:flutter/material.dart';
import '../models/payload_config.dart';
import '../models/ssh_account.dart';
import '../models/sni_entry.dart';
import '../services/local_storage.dart';
import '../services/payload_generator.dart';

class ConfigBuilderScreen extends StatefulWidget {
  const ConfigBuilderScreen({super.key});

  @override
  State<ConfigBuilderScreen> createState() => _ConfigBuilderScreenState();
}

class _ConfigBuilderScreenState extends State<ConfigBuilderScreen> {
  final _nameController = TextEditingController();
  final _customTemplateController = TextEditingController();
  
  int _selectedTemplateIndex = 0;
  String? _selectedSniHost;
  SshAccount? _selectedSshAccount;
  
  List<SniEntry> _sniHosts = [];
  List<SshAccount> _sshAccounts = [];
  List<PayloadConfig> _savedConfigs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final sniHosts = await LocalStorage.instance.getSniEntries();
    final sshAccounts = await LocalStorage.instance.getSshAccounts();
    final savedConfigs = await LocalStorage.instance.getPayloadConfigs();
    
    setState(() {
      _sniHosts = sniHosts.where((s) => s.isActive).toList();
      _sshAccounts = sshAccounts.where((s) => !s.isExpired).toList();
      _savedConfigs = savedConfigs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Config Builder Form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create New Configuration',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Configuration Name
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Configuration Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Template Selection
                  DropdownButtonFormField<int>(
                    value: _selectedTemplateIndex,
                    decoration: const InputDecoration(
                      labelText: 'Payload Template',
                      border: OutlineInputBorder(),
                    ),
                    items: PayloadGenerator.getTemplateNames()
                        .asMap()
                        .entries
                        .map((entry) => DropdownMenuItem(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTemplateIndex = value ?? 0;
                        _customTemplateController.text = PayloadGenerator.getTemplate(value ?? 0);
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // SNI Host Selection
                  DropdownButtonFormField<String>(
                    value: _selectedSniHost,
                    decoration: const InputDecoration(
                      labelText: 'SNI Host',
                      border: OutlineInputBorder(),
                    ),
                    items: _sniHosts
                        .map((sni) => DropdownMenuItem(
                              value: sni.host,
                              child: Text('${sni.host} (${sni.responseTime}ms)'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSniHost = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // SSH Account Selection
                  DropdownButtonFormField<SshAccount>(
                    value: _selectedSshAccount,
                    decoration: const InputDecoration(
                      labelText: 'SSH Account',
                      border: OutlineInputBorder(),
                    ),
                    items: _sshAccounts
                        .map((ssh) => DropdownMenuItem(
                              value: ssh,
                              child: Text(ssh.displayName),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSshAccount = value;
                      });
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Custom Template Editor
                  TextField(
                    controller: _customTemplateController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Custom Payload Template',
                      border: OutlineInputBorder(),
                      helperText: 'Use [SNI], [HOST], [PORT], [USER] as placeholders',
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _canSaveConfig() ? _saveConfig : null,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Config'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _generateAllCombinations,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Auto Generate'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Saved Configurations List
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
                          'Saved Configurations (${_savedConfigs.length})',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _savedConfigs.length,
                      itemBuilder: (context, index) {
                        final config = _savedConfigs[index];
                        return ListTile(
                          leading: Icon(
                            config.isSuccessful ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: config.isSuccessful ? Colors.green : Colors.grey,
                          ),
                          title: Text(config.name),
                          subtitle: Text('${config.sniHost} → ${config.sshHost}:${config.sshPort}'),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit'),
                              ),
                              const PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Duplicate'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                            onSelected: (value) => _handleConfigAction(value, config),
                          ),
                          onTap: () => _previewConfig(config),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canSaveConfig() {
    return _nameController.text.isNotEmpty &&
           _selectedSniHost != null &&
           _selectedSshAccount != null &&
           _customTemplateController.text.isNotEmpty;
  }

  Future<void> _saveConfig() async {
    if (!_canSaveConfig()) return;
    
    final config = PayloadConfig(
      name: _nameController.text,
      template: _customTemplateController.text,
      sniHost: _selectedSniHost!,
      sshHost: _selectedSshAccount!.host,
      sshPort: _selectedSshAccount!.port,
      sshUser: _selectedSshAccount!.user,
      sshPassword: _selectedSshAccount!.password,
    );
    
    await LocalStorage.instance.insertPayloadConfig(config);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved successfully')),
    );
    
    _clearForm();
    _loadData();
  }

  Future<void> _generateAllCombinations() async {
    if (_sniHosts.isEmpty || _sshAccounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least one SNI host and SSH account')),
      );
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating configurations...'),
          ],
        ),
      ),
    );
    
    try {
      final configs = await PayloadGenerator.generateAllCombinations(_sniHosts, _sshAccounts);
      
      for (final config in configs) {
        await LocalStorage.instance.insertPayloadConfig(config);
      }
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${configs.length} configurations')),
      );
      
      _loadData();
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating configurations: $e')),
      );
    }
  }

  void _clearForm() {
    _nameController.clear();
    _customTemplateController.clear();
    setState(() {
      _selectedTemplateIndex = 0;
      _selectedSniHost = null;
      _selectedSshAccount = null;
    });
  }

  void _handleConfigAction(String action, PayloadConfig config) async {
    switch (action) {
      case 'edit':
        _editConfig(config);
        break;
      case 'duplicate':
        _duplicateConfig(config);
        break;
      case 'delete':
        _deleteConfig(config);
        break;
    }
  }

  void _editConfig(PayloadConfig config) {
    setState(() {
      _nameController.text = config.name;
      _customTemplateController.text = config.template;
      _selectedSniHost = config.sniHost;
      _selectedSshAccount = _sshAccounts.where((s) => s.host == config.sshHost).firstOrNull;
    });
  }

  Future<void> _duplicateConfig(PayloadConfig config) async {
    final newConfig = config.copyWith(
      id: null,
      name: '${config.name} (Copy)',
      createdAt: DateTime.now(),
    );
    
    await LocalStorage.instance.insertPayloadConfig(newConfig);
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration duplicated')),
    );
  }

  Future<void> _deleteConfig(PayloadConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await LocalStorage.instance.deletePayloadConfig(config.id!);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration deleted')),
      );
    }
  }

  void _previewConfig(PayloadConfig config) {
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
              Text('SSH: ${config.sshHost}:${config.sshPort}'),
              Text('User: ${config.sshUser}'),
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
                  style: const TextStyle(fontFamily: 'monospace'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _customTemplateController.dispose();
    super.dispose();
  }
}