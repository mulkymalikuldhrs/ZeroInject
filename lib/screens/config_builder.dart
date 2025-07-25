import 'package:flutter/material.dart';
import '../services/payload_generator.dart';
import '../services/local_storage.dart';
import '../models/payload_config.dart';
import '../models/ssh_account.dart';
import '../models/sni_entry.dart';

class ConfigBuilderScreen extends StatefulWidget {
  const ConfigBuilderScreen({super.key});

  @override
  State<ConfigBuilderScreen> createState() => _ConfigBuilderScreenState();
}

class _ConfigBuilderScreenState extends State<ConfigBuilderScreen> {
  final _nameController = TextEditingController();
  final _sniController = TextEditingController();
  final _sshHostController = TextEditingController();
  final _sshPortController = TextEditingController(text: '443');
  final _customPayloadController = TextEditingController();
  
  List<PayloadConfig> _savedConfigs = [];
  bool _useCustomPayload = false;
  String _selectedTemplate = 'CONNECT Method';

  @override
  void initState() {
    super.initState();
    _loadSavedConfigs();
  }

  Future<void> _loadSavedConfigs() async {
    final configs = await LocalStorage.instance.getPayloadConfigs();
    setState(() {
      _savedConfigs = configs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Config Builder'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Create New Config Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create New Configuration',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Configuration Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: _sniController,
                      decoration: const InputDecoration(
                        labelText: 'SNI Host (e.g., zero.facebook.com)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _sshHostController,
                            decoration: const InputDecoration(
                              labelText: 'SSH Host',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.cloud),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _sshPortController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Port',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Use Custom Payload'),
                      value: _useCustomPayload,
                      onChanged: (value) {
                        setState(() {
                          _useCustomPayload = value;
                        });
                      },
                    ),
                    
                    if (_useCustomPayload) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customPayloadController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Custom Payload',
                          border: OutlineInputBorder(),
                          hintText: 'CONNECT [SNI]:443 HTTP/1.1\nHost: [SNI]\n...',
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _selectedTemplate,
                        decoration: const InputDecoration(
                          labelText: 'Payload Template',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'CONNECT Method', child: Text('CONNECT Method')),
                          DropdownMenuItem(value: 'GET Method with SNI', child: Text('GET Method with SNI')),
                          DropdownMenuItem(value: 'POST Method', child: Text('POST Method')),
                          DropdownMenuItem(value: 'WebSocket Upgrade', child: Text('WebSocket Upgrade')),
                          DropdownMenuItem(value: 'HTTP Proxy', child: Text('HTTP Proxy')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTemplate = value!;
                          });
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _saveConfiguration,
                            icon: const Icon(Icons.save),
                            label: const Text('Save Configuration'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _generateFromScanResults,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Auto Generate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Saved Configurations
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
                          'Saved Configurations',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _loadSavedConfigs,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_savedConfigs.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No configurations saved yet',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _savedConfigs.length,
                        itemBuilder: (context, index) {
                          final config = _savedConfigs[index];
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
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'test',
                                    child: Row(
                                      children: [
                                        Icon(Icons.play_arrow),
                                        SizedBox(width: 8),
                                        Text('Test'),
                                      ],
                                    ),
                                  ),
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
                                onSelected: (value) => _handleConfigAction(value, config),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveConfiguration() async {
    if (_nameController.text.isEmpty || 
        _sniController.text.isEmpty || 
        _sshHostController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final config = PayloadGenerator.createCustomPayload(
      name: _nameController.text,
      sniHost: _sniController.text,
      sshHost: _sshHostController.text,
      sshPort: int.tryParse(_sshPortController.text) ?? 443,
      customTemplate: _useCustomPayload ? _customPayloadController.text : null,
    );

    await LocalStorage.instance.insertPayloadConfig(config);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration saved successfully')),
    );
    
    _clearForm();
    _loadSavedConfigs();
  }

  Future<void> _generateFromScanResults() async {
    // Get working SNIs and SSH accounts
    final workingSNIs = await LocalStorage.instance.getWorkingSNIs();
    final activeSSHs = await LocalStorage.instance.getActiveSSHAccounts();
    
    if (workingSNIs.isEmpty || activeSSHs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please scan for SNIs and SSH accounts first'),
        ),
      );
      return;
    }

    // Generate configurations
    final configs = PayloadGenerator.generatePayloads(workingSNIs, activeSSHs);
    
    // Save all configurations
    for (final config in configs) {
      await LocalStorage.instance.insertPayloadConfig(config);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Generated ${configs.length} configurations')),
    );
    
    _loadSavedConfigs();
  }

  void _handleConfigAction(String action, PayloadConfig config) async {
    switch (action) {
      case 'edit':
        _editConfiguration(config);
        break;
      case 'test':
        _testConfiguration(config);
        break;
      case 'delete':
        _deleteConfiguration(config);
        break;
    }
  }

  void _editConfiguration(PayloadConfig config) {
    setState(() {
      _nameController.text = config.name;
      _sniController.text = config.sniHost;
      _sshHostController.text = config.sshHost;
      _sshPortController.text = config.sshPort.toString();
    });
  }

  void _testConfiguration(PayloadConfig config) {
    // Navigate to dashboard and test this configuration
    Navigator.of(context).pushNamed('/dashboard', arguments: config);
  }

  void _deleteConfiguration(PayloadConfig config) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Configuration'),
        content: Text('Are you sure you want to delete "${config.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalStorage.instance.deletePayloadConfig(config.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration deleted')),
      );
      _loadSavedConfigs();
    }
  }

  void _clearForm() {
    _nameController.clear();
    _sniController.clear();
    _sshHostController.clear();
    _sshPortController.text = '443';
    _customPayloadController.clear();
    setState(() {
      _useCustomPayload = false;
      _selectedTemplate = 'CONNECT Method';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sniController.dispose();
    _sshHostController.dispose();
    _sshPortController.dispose();
    _customPayloadController.dispose();
    super.dispose();
  }
}