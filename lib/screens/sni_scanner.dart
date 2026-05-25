import 'package:flutter/material.dart';
import '../services/sni_scanner.dart';
import '../services/local_storage.dart';
import '../models/sni_entry.dart';

class SNIScannerScreen extends StatefulWidget {
  const SNIScannerScreen({super.key});

  @override
  State<SNIScannerScreen> createState() => _SNIScannerScreenState();
}

class _SNIScannerScreenState extends State<SNIScannerScreen> {
  List<SNIEntry> _sniEntries = [];
  bool _isScanning = false;
  String _filterCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadSNIEntries();
  }

  Future<void> _loadSNIEntries() async {
    final entries = await LocalStorage.instance.getSNIEntries();
    setState(() {
      _sniEntries = entries;
    });
  }

  Future<void> _scanAllSNIs() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final results = await SNIScanner.scanAllSNIs();

      // Save results to database
      for (final entry in results) {
        await LocalStorage.instance.insertSNIEntry(entry);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanned ${results.length} SNI hosts')),
        );
      }

      _loadSNIEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning SNIs: $e')),
        );
      }
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _testSingleSNI(SNIEntry entry) async {
    final result = await SNIScanner.testSNI(entry.hostname, port: entry.port);
    await LocalStorage.instance.updateSNIEntry(result);
    _loadSNIEntries();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isWorking
                ? '${entry.hostname} is working (${result.responseTime}ms)'
                : '${entry.hostname} failed: ${result.errorMessage ?? "Unknown error"}',
          ),
          backgroundColor: result.isWorking ? Colors.green : Colors.red,
        ),
      );
    }
  }

  List<SNIEntry> get _filteredEntries {
    if (_filterCategory == 'all') return _sniEntries;
    return _sniEntries.where((e) => e.category == _filterCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;
    final workingCount = filtered.where((e) => e.isWorking).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SNI Scanner'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadSNIEntries,
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
                      'SNI Host Scanner',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan and test SNI hosts for connectivity.',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _scanAllSNIs,
                            icon: _isScanning
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.search),
                            label: Text(_isScanning ? 'Scanning...' : 'Scan All SNIs'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Category Filter
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip('all', 'All'),
                _buildFilterChip('social', 'Social'),
                _buildFilterChip('cdn', 'CDN'),
                _buildFilterChip('telecom', 'Telecom'),
                _buildFilterChip('general', 'General'),
              ],
            ),
          ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Working: $workingCount / ${filtered.length}',
                  style: TextStyle(
                    color: workingCount > 0 ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // SNI List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.scanner, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No SNI entries found',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap "Scan All SNIs" to test SNI hosts',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final entry = filtered[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: entry.isWorking ? Colors.green : Colors.red,
                            child: Icon(
                              entry.isWorking ? Icons.check : Icons.close,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            entry.hostname,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Port: ${entry.port} | Category: ${entry.category}'),
                              if (entry.isWorking)
                                Text(
                                  'Response: ${entry.responseTime}ms',
                                  style: const TextStyle(color: Colors.green),
                                ),
                              if (!entry.isWorking && entry.errorMessage != null)
                                Text(
                                  'Error: ${entry.errorMessage}',
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () => _testSingleSNI(entry),
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

  Widget _buildFilterChip(String category, String label) {
    final isSelected = _filterCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterCategory = category;
          });
        },
      ),
    );
  }
}
