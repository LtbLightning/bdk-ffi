import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BDK Bitcoin Wallet',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home: const WalletHomePage(),
    );
  }
}

class WalletHomePage extends StatefulWidget {
  const WalletHomePage({super.key});

  @override
  State<WalletHomePage> createState() => _WalletHomePageState();
}

class _WalletHomePageState extends State<WalletHomePage> {
  Wallet? _wallet;
  Mnemonic? _mnemonic;
  String? _currentAddress;
  Balance? _balance;
  bool _isLoading = false;
  final List<AddressInfo> _addresses = [];
  Network _network =
      Network.regtest; // Changed to regtest - most common for local electrs

  // Configure your local Electrum server URL here
  String _electrumUrl = 'tcp://localhost:50000'; // electrs default port

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    setState(() => _isLoading = true);

    try {
      final mnemonic = Mnemonic(WordCount.words12);
      print('Generated mnemonic: ${mnemonic.toString()}');

      final secretKey = DescriptorSecretKey(_network, mnemonic, null);

      // Create external and internal descriptors for the wallet
      final externalDescriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.external_,
        _network,
      );
      final internalDescriptor = Descriptor.newBip84(
        secretKey,
        KeychainKind.internal,
        _network,
      );

      print('External descriptor: ${externalDescriptor.toString()}');

      // Create wallet with in-memory persistence
      final persister = Persister.newInMemory();
      final wallet = Wallet(
        externalDescriptor,
        internalDescriptor,
        _network,
        persister,
        20, // lookahead
      );

      // Get first address
      final addressInfo = wallet.nextUnusedAddress(KeychainKind.external_);
      final balance = wallet.balance();

      setState(() {
        _wallet = wallet;
        _mnemonic = mnemonic;
        _currentAddress = addressInfo.address.toString();
        _addresses.add(addressInfo);
        _balance = balance;
      });

      print(
          'Wallet initialized with address: ${addressInfo.address} (index: ${addressInfo.index})');
      print('Balance: ${balance.total}');
    } catch (e) {
      print('Error initializing wallet: $e');
      if (mounted) {
        _showError('Failed to initialize wallet: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _generateNewAddress() async {
    if (_wallet == null) return;
    setState(() => _isLoading = true);

    try {
      final addressInfo = _wallet!.nextUnusedAddress(KeychainKind.external_);

      setState(() {
        _currentAddress = addressInfo.address.toString();
        _addresses.add(addressInfo);
      });

      print(
          'Generated address: ${addressInfo.address} (index: ${addressInfo.index})');
      _showSuccess('New address generated!');
    } catch (e) {
      print('Error generating address: $e');
      _showError('Failed to generate address: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshBalance() async {
    if (_wallet == null) return;
    setState(() => _isLoading = true);

    try {
      print('Connecting to Electrum server at: $_electrumUrl');

      // Create Electrum client (url, socks5 proxy)
      final electrumClient = ElectrumClient(_electrumUrl, null);

      // Test connection
      print('Testing connection...');
      electrumClient.ping();
      print('Connection successful!');

      // Create a full scan request
      print('Creating full scan request...');
      final request = _wallet!.startFullScan().build();

      // Perform full scan (request, stopGap, batchSize, fetchPrevTxouts)
      print('Syncing wallet with blockchain...');
      final update = electrumClient.fullScan(request, 20, 5, true);

      // Apply the update to the wallet
      _wallet!.applyUpdate(update);
      print('Wallet synced successfully');

      // Get updated balance
      final balance = _wallet!.balance();
      setState(() {
        _balance = balance;
      });

      print(
          'Balance: ${balance.total.toSat()} sats (Confirmed: ${balance.confirmed.toSat()}, Pending: ${balance.trustedPending.toSat()})');
      _showSuccess('Synced with blockchain! Balance updated.');
    } catch (e) {
      print('Error syncing with Electrum: $e');

      // Provide helpful error messages
      String errorMessage = 'Failed to sync: $e';
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('connect')) {
        errorMessage = 'Cannot connect to Electrum server.\n'
            'Check that:\n'
            '• Server is running at $_electrumUrl\n'
            '• Port 50000 is correct\n'
            '• URL uses tcp:// prefix';
      } else if (e.toString().contains('timeout')) {
        errorMessage =
            'Connection timeout. Is electrs running at $_electrumUrl?';
      }

      _showError(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSuccess('Copied to clipboard!');
  }

  void _showMnemonic() {
    if (_mnemonic == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recovery Phrase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Write down these 12 words in order and keep them safe:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              _mnemonic!.toString(),
              style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Never share your recovery phrase with anyone!',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              _copyToClipboard(_mnemonic!.toString());
              Navigator.pop(context);
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  void _showAddressList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Addresses'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _addresses.length,
            itemBuilder: (context, index) => ListTile(
              leading: CircleAvatar(child: Text('${_addresses[index].index}')),
              title: Text(
                _addresses[index].address.toString(),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () =>
                    _copyToClipboard(_addresses[index].address.toString()),
              ),
            ),
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

  void _showElectrumSettings() {
    final controller = TextEditingController(text: _electrumUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Electrum Server Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your Electrum server URL:'),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'tcp://localhost:50000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Common ports:\n'
              '• electrs testnet: tcp://localhost:50000\n'
              '• electrs mainnet: tcp://localhost:50001\n'
              '• Use tcp:// prefix for Electrum',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _electrumUrl = controller.text;
              });
              Navigator.pop(context);
              _showSuccess('Electrum URL updated to: $_electrumUrl');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BDK Bitcoin Wallet'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showElectrumSettings,
            tooltip: 'Electrum Server Settings',
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key),
            onPressed: _showMnemonic,
            tooltip: 'Show Recovery Phrase',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _wallet == null
              ? const Center(child: Text('Initializing wallet...'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.network_check,
                                      color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Network: ${_network.toString().split('.').last.toUpperCase()}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.bolt,
                                      size: 16, color: Colors.orange.shade700),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Electrum: $_electrumUrl',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              const Text('Total Balance',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Text(
                                '${_balance?.total.toSat() ?? 0} sats',
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '≈ ${_balance?.total.toBtc() ?? 0.0} BTC',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _refreshBalance,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Refresh Balance'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Current Receive Address',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: SelectableText(
                                  _currentAddress ?? 'No address',
                                  style: const TextStyle(
                                      fontSize: 14, fontFamily: 'monospace'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _copyToClipboard(_currentAddress ?? ''),
                                    icon: const Icon(Icons.copy, size: 18),
                                    label: const Text('Copy'),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _generateNewAddress,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('New Address'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _showAddressList,
                        icon: const Icon(Icons.list),
                        label:
                            Text('View All Addresses (${_addresses.length})'),
                      ),
                      const SizedBox(height: 24),
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.blue.shade700),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Wallet Information',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                  '• This is a ${_network.toString().split('.').last} testnet wallet'),
                              const Text('• Uses BIP84 (native SegWit)'),
                              const Text('• All data is stored in memory only'),
                              const Text(
                                  '• Tap the key icon to view your recovery phrase'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
