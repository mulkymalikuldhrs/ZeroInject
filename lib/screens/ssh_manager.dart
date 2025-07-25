import 'package:flutter/material.dart';
import '../models/ssh_account.dart';
import '../services/local_storage.dart';
import '../services/ssh_scraper.dart';

class SshManagerScreen extends StatefulWidget {
  const SshManagerScreen({super.key});

  @override
  State<SshManagerScreen> createState() => _SshManagerScreenState();
}

class _SshManagerScreenState extends State<SshManagerScreen> {
  List<SshAccount> _sshAccounts = [];
  bool _isLoading = false;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _loadSshAccounts();
  }

  Future<void> _loadSshAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await LocalStorage.instance.getSshAccounts();
      setState(() {
        _sshAccounts = accounts;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading SSH accounts: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchFreeAccounts() async {
    setState(() {
      _isFetching = true;
    });

    try {
      final accounts = await SshScraper.fetchFreeAccounts();
      
      if (accounts.isEmpty) {
        // Fallback to default accounts
        final defaultAccounts = await SshScraper.getDefaultAccounts();
        accounts.addAll(defaultAccounts);
      }

      for (final account in accounts) {
        await LocalStorage.instance.insertSshAccount(account);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fetched ${accounts.length} SSH accounts')),
      );

      _loadSshAccounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching SSH accounts: $e')),
      );
    } finally {
      setState(() {
        _isFetching = false;
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
          // Header with actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'SSH Account Manager',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isFetching ? null : _fetchFreeAccounts,
                          icon: _isFetching 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.download),
                          label: Text(_isFetching ? 'Fetching...' : 'Fetch Free SSH'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showAddAccountDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Manual'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // SSH Accounts List
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
                          'SSH Accounts (${_sshAccounts.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: _loadSshAccounts,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _sshAccounts.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.computer, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('No SSH accounts found'),
                                    Text('Tap "Fetch Free SSH" to get started'),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _sshAccounts.length,
                                itemBuilder: (context, index) {
                                  final account = _sshAccounts[index];
                                  return _buildSshAccountTile(account);
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

  Widget _buildSshAccountTile(SshAccount account) {
    final isExpired = account.isExpired;
    final daysLeft = account.expired.difference(DateTime.now()).inDays;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isExpired ? Colors.red : Colors.green,
        child: Icon(
          isExpired ? Icons.error : Icons.computer,
          color: Colors.white,
        ),
      ),
      title: Text(account.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('User: ${account.user}'),
          Text(
            isExpired 
                ? 'Expired ${(-daysLeft)} days ago'
                : 'Expires in $daysLeft days',
            style: TextStyle(
              color: isExpired ? Colors.red : Colors.green,
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
            value: 'edit',
            child: Text('Edit'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) => _handleAccountAction(value, account),
      ),
      onTap: () => _showAccountDetails(account),
    );
  }

  void _handleAccountAction(String action, SshAccount account) async {
    switch (action) {
      case 'test':
        _testSshConnection(account);
        break;
      case 'edit':
        _showEditAccountDialog(account);
        break;
      case 'delete':
        _deleteSshAccount(account);
        break;
    }
  }

  Future<void> _testSshConnection(SshAccount account) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing SSH connection...'),
          ],
        ),
      ),
    );

    try {
      // Simple socket connection test
      final socket = await Socket.connect(
        account.host,
        account.port,
        timeout: const Duration(seconds: 10),
      );
      await socket.close();
      
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('SSH connection successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('SSH connection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAccountDetails(SshAccount account) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(account.displayName),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Host: ${account.host}'),
            Text('Port: ${account.port}'),
            Text('User: ${account.user}'),
            Text('Password: ${account.password}'),
            Text('Expires: ${account.expired.toString().substring(0, 19)}'),
            Text('Status: ${account.isExpired ? 'Expired' : 'Active'}'),
          ],
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

  void _showAddAccountDialog() {
    final hostController = TextEditingController();
    final portController = TextEditingController(text: '22');
    final userController = TextEditingController();
    final passwordController = TextEditingController();
    final expiredController = TextEditingController(
      text: DateTime.now().add(const Duration(days: 30)).toString().substring(0, 10),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add SSH Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                decoration: const InputDecoration(labelText: 'Host'),
              ),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: expiredController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date (YYYY-MM-DD)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final account = SshAccount(
                  host: hostController.text,
                  port: int.parse(portController.text),
                  user: userController.text,
                  password: passwordController.text,
                  expired: DateTime.parse(expiredController.text),
                );
                
                await LocalStorage.instance.insertSshAccount(account);
                Navigator.pop(context);
                _loadSshAccounts();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SSH account added')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error adding account: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditAccountDialog(SshAccount account) {
    final hostController = TextEditingController(text: account.host);
    final portController = TextEditingController(text: account.port.toString());
    final userController = TextEditingController(text: account.user);
    final passwordController = TextEditingController(text: account.password);
    final expiredController = TextEditingController(
      text: account.expired.toString().substring(0, 10),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit SSH Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                decoration: const InputDecoration(labelText: 'Host'),
              ),
              TextField(
                controller: portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: userController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              TextField(
                controller: expiredController,
                decoration: const InputDecoration(
                  labelText: 'Expiry Date (YYYY-MM-DD)',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final updatedAccount = SshAccount(
                  id: account.id,
                  host: hostController.text,
                  port: int.parse(portController.text),
                  user: userController.text,
                  password: passwordController.text,
                  expired: DateTime.parse(expiredController.text),
                  createdAt: account.createdAt,
                );
                
                await LocalStorage.instance.updateSshAccount(updatedAccount);
                Navigator.pop(context);
                _loadSshAccounts();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SSH account updated')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating account: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSshAccount(SshAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SSH Account'),
        content: Text('Are you sure you want to delete ${account.displayName}?'),
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
      await LocalStorage.instance.deleteSshAccount(account.id!);
      _loadSshAccounts();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SSH account deleted')),
      );
    }
  }
}