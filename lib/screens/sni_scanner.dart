import 'package:flutter/material.dart';
import '../models/sni_entry.dart';
import '../services/local_storage.dart';
import '../services/sni_scanner.dart';

class SniScannerScreen extends StatefulWidget {
  const SniScannerScreen({super.key});

  @override
  State<SniScannerScreen> createState() => _SniScannerScreenState();
}

class _SniScannerScreenState extends State<SniScannerScreen> {
  List<SniEntry> _sniEntries = [];
  bool _isLoading = false;
  bool _isScanning = false;
  final _customHostController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSniEntries();
  }

  Future<void> _loadSniEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final entries = await LocalStorage.instance.getSniEntries();
      setState(() {
        _sniEntries = entries;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading SNI entries: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _scanAllHosts() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final results = await SniScanner.scanAllHosts();
      
      for (final result in results) {
        // Check if entry exists
        final existingEntry = _sniEntries.where((e) => e.host == result.host).firstOrNull;
        
        if (existingEntry != null) {
          // Update existing entry
          final updatedEntry = existingEntry.copyWith(
            isActive: result.isActive,
            responseTime: result.responseTime,
            lastChecked: result.lastChecked,
          );
          await LocalStorage.instance.updateSniEntry(updatedEntry);
        } else {
          // Insert new entry
          await LocalStorage.instance.insertSniEntry(result);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned ${results.length} SNI hosts')),
      );

      _loadSniEntries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning SNI hosts: $e')),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _scanSingleHost(String host) async {
    try {
      final result = await SniScanner.scanSingleHost(host);
      
      // Check if entry exists
      final existingEntry = _sniEntries.where((e) => e.host == host).firstOrNull;
      
      if (existingEntry != null) {
        final updatedEntry = existingEntry.copyWith(
          isActive: result.isActive,
          responseTime: result.responseTime,
          lastChecked: result.lastChecked,
        );
        await LocalStorage.instance.updateSniEntry(updatedEntry);
      } else {
        await LocalStorage.instance.insertSniEntry(result);
      }

      _loadSniEntries();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isActive 
                ? 'Host $host is active (${result.responseTime}ms)'
                : 'Host $host is not accessible',
          ),
          backgroundColor: result.isActive ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning $host: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSnis = _sniEntries.where((e) => e.isActive).length;
    
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
                    'SNI Scanner',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Active SNI hosts: $activeSnis/${_sniEntries.length}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Custom host input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customHostController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Host',
                            hintText: 'e.g., example.com',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (_customHostController.text.isNotEmpty) {
                            _scanSingleHost(_customHostController.text);
                            _customHostController.clear();
                          }
                        },
                        child: const Text('Add & Scan'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scanAllHosts,
                    icon: _isScanning 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.network_check),
                    label: Text(_isScanning ? 'Scanning...' : 'Scan All SNI Hosts'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // SNI Entries List
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
                          'SNI Hosts (${_sniEntries.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: _loadSniEntries,
                              icon: const Icon(Icons.refresh),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'sort_status',
                                  child: Text('Sort by Status'),
                                ),
                                const PopupMenuItem(
                                  value: 'sort_speed',
                                  child: Text('Sort by Speed'),
                                ),
                                const PopupMenuItem(
                                  value: 'sort_name',
                                  child: Text('Sort by Name'),
                                ),
                              ],
                              onSelected: _sortEntries,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _sniEntries.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.network_check, size: 64, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text('No SNI hosts found'),
                                    Text('Tap "Scan All SNI Hosts" to get started'),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: _sniEntries.length,
                                itemBuilder: (context, index) {
                                  final entry = _sniEntries[index];
                                  return _buildSniEntryTile(entry);
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

  Widget _buildSniEntryTile(SniEntry entry) {
    final lastChecked = DateTime.now().difference(entry.lastChecked);
    final lastCheckedText = lastChecked.inMinutes < 1 
        ? 'Just now'
        : lastChecked.inHours < 1
            ? '${lastChecked.inMinutes}m ago'
            : lastChecked.inDays < 1
                ? '${lastChecked.inHours}h ago'
                : '${lastChecked.inDays}d ago';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: entry.isActive ? Colors.green : Colors.red,
        child: Icon(
          entry.isActive ? Icons.check : Icons.close,
          color: Colors.white,
        ),
      ),
      title: Text(entry.host),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Port: ${entry.port}'),
          Text(
            entry.isActive 
                ? 'Response: ${entry.responseTime}ms'
                : 'Not accessible',
            style: TextStyle(
              color: entry.isActive ? Colors.green : Colors.red,
            ),
          ),
          Text(
            'Last checked: $lastCheckedText',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'rescan',
            child: Text('Rescan'),
          ),
          const PopupMenuItem(
            value: 'test_speed',
            child: Text('Test Speed'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) => _handleSniAction(value, entry),
      ),
      onTap: () => _showSniDetails(entry),
    );
  }

  void _handleSniAction(String action, SniEntry entry) async {
    switch (action) {
      case 'rescan':
        _scanSingleHost(entry.host);
        break;
      case 'test_speed':
        _testSniSpeed(entry);
        break;
      case 'delete':
        _deleteSniEntry(entry);
        break;
    }
  }

  Future<void> _testSniSpeed(SniEntry entry) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing SNI speed...'),
          ],
        ),
      ),
    );

    try {
      final result = await SniScanner.testSniSpeed(entry.host, port: entry.port);
      
      final updatedEntry = entry.copyWith(
        isActive: result.isActive,
        responseTime: result.responseTime,
        lastChecked: result.lastChecked,
      );
      
      await LocalStorage.instance.updateSniEntry(updatedEntry);
      
      Navigator.pop(context); // Close loading dialog
      _loadSniEntries();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isActive 
                ? 'Average response time: ${result.responseTime}ms'
                : 'Host is not accessible',
          ),
          backgroundColor: result.isActive ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error testing SNI speed: $e')),
      );
    }
  }

  void _showSniDetails(SniEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(entry.host),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Host: ${entry.host}'),
            Text('Port: ${entry.port}'),
            Text('Status: ${entry.isActive ? 'Active' : 'Inactive'}'),
            Text('Response Time: ${entry.responseTime}ms'),
            Text('Last Checked: ${entry.lastChecked.toString().substring(0, 19)}'),
            Text('Created: ${entry.createdAt.toString().substring(0, 19)}'),
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

  Future<void> _deleteSniEntry(SniEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete SNI Entry'),
        content: Text('Are you sure you want to delete ${entry.host}?'),
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
      await LocalStorage.instance.deleteSniEntry(entry.id!);
      _loadSniEntries();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SNI entry deleted')),
      );
    }
  }

  void _sortEntries(String sortType) {
    setState(() {
      switch (sortType) {
        case 'sort_status':
          _sniEntries.sort((a, b) {
            if (a.isActive && !b.isActive) return -1;
            if (!a.isActive && b.isActive) return 1;
            return a.responseTime.compareTo(b.responseTime);
          });
          break;
        case 'sort_speed':
          _sniEntries.sort((a, b) => a.responseTime.compareTo(b.responseTime));
          break;
        case 'sort_name':
          _sniEntries.sort((a, b) => a.host.compareTo(b.host));
          break;
      }
    });
  }

  @override
  void dispose() {
    _customHostController.dispose();
    super.dispose();
  }
}