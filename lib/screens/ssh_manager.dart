import 'package:flutter/material.dart';
import '../services/ssh_scraper.dart';
import '../services/local_storage.dart';
import '../models/ssh_account.dart';

class SSHManagerScreen extends StatefulWidget {
  const SSHManagerScreen({super.key});

  @override
  State<SSHManagerScreen> createState() => _SSHManagerScreenState();
}

class _SSHManagerScreenState extends State<SSHManagerScreen> {
  List<SSHAccount> _sshAccounts = [];
  bool _isScanning = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSSHAccounts();
  }

  Future<void> _loadSSHAccounts() async {
    final accounts = await LocalStorage.instance.getSSHAccounts();
    setState(() {
      _sshAccounts = accounts;
    });
  }

  Future<void> _scanForSSHAccounts() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final newAccounts = await SSHScraper.scrapeAllSources();
      
      // Save new accounts to database
      for (final account in newAccounts) {
        await LocalStorage.instance.insertSSHAccount(account);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Found ${newAccounts.length} SSH accounts')),
      );
      
      _loadSSHAccounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning SSH accounts: $e')),
      );
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _testSSHAccount(SSHAccount account) async {
    setState(() {
      _isTesting = true;
    });

    try {
      final isWorking = await SSHScraper.testSSHConnection(account);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isWorking 
              ? 'SSH account is working!' 
              : 'SSH account is not responding',
          ),
          backgroundColor: isWorking ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error testing SSH account: $e')),
      );
    }

    setState(() {
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SSH Manager'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSSHAccounts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scan Controls
          Container(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SSH Account Scanner',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Automatically scan and collect free SSH accounts from various sources.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _scanForSSHAccounts,
                            icon: _isScanning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: Text(_isScanning ? 'Scanning...' : 'Scan SSH Accounts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _addManualSSH,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Manual'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // SSH Accounts List
          Expanded(
            child: _sshAccounts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No SSH accounts found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap "Scan SSH Accounts" to find free accounts',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _sshAccounts.length,
                    itemBuilder: (context, index) {
                      final account = _sshAccounts[index];
                      final isExpired = account.isExpired;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isExpired ? Colors.red : Colors.green,
                            child: Icon(
                              isExpired ? Icons.error : Icons.cloud,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            '${account.username}@${account.host}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.red : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Port: ${account.port}'),
                              Text('Password: ${account.password}'),
                              Text(
                                'Expires: ${account.expiredDate.toString().substring(0, 16)}',
                                style: TextStyle(
                                  color: isExpired ? Colors.red : Colors.grey,
                                ),
                              ),
                              Text(
                                'Source: ${account.source}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'test',
                                child: Row(
                                  children: [
                                    Icon(Icons.play_arrow),
                                    SizedBox(width: 8),
                                    Text('Test Connection'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'copy',
                                child: Row(
                                  children: [
                                    Icon(Icons.copy),
                                    SizedBox(width: 8),
                                    Text('Copy Details'),
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
                            onSelected: (value) => _handleAccountAction(value, account),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _handleAccountAction(String action, SSHAccount account) async {
    switch (action) {
      case 'test':
        await _testSSHAccount(account);
        break;
      case 'copy':
        _copyAccountDetails(account);
        break;
      case 'delete':
        _deleteAccount(account);
        break;
    }
  }

  void _copyAccountDetails(SSHAccount account) {
    // In a real app, you would use Clipboard.setData
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account details copied to clipboard')),
    );
  }

  void _deleteAccount(SSHAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SSH Account'),
        content: Text('Are you sure you want to delete ${account.username}@${account.host}?'),
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
      await LocalStorage.instance.deleteSSHAccount(account.id!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SSH account deleted')),
      );
      _loadSSHAccounts();
    }
  }

  void _addManualSSH() {
    showDialog(
      context: context,
      builder: (context) => _ManualSSHDialog(
        onSave: (account) async {
          await LocalStorage.instance.insertSSHAccount(account);
          _loadSSHAccounts();
        },
      ),
    );
  }
}

class _ManualSSHDialog extends StatefulWidget {
  final Function(SSHAccount) onSave;

  const _ManualSSHDialog({required this.onSave});

  @override
  State<_ManualSSHDialog> createState() => _ManualSSHDialogState();
}

class _ManualSSHDialogState extends State<_ManualSSHDialog> {
  final _usernameController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _passwordController = TextEditingController();
  DateTime _expiredDate = DateTime.now().add(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Manual SSH Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Expiry Date'),
              subtitle: Text(_expiredDate.toString().substring(0, 10)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveAccount,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiredDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _expiredDate = date;
      });
    }
  }

  void _saveAccount() {
    if (_usernameController.text.isEmpty || 
        _hostController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final account = SSHAccount(
      username: _usernameController.text,
      host: _hostController.text,
      port: int.tryParse(_portController.text) ?? 22,
      password: _passwordController.text,
      expiredDate: _expiredDate,
      source: 'manual',
    );

    widget.onSave(account);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}