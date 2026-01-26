import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Ensure these imports match your project structure
import 'package:helawork/freelancer/provider/auth_provider.dart';
import 'package:helawork/wallet_service.dart'; 

class BankRegistrationScreen extends StatefulWidget {
  const BankRegistrationScreen({super.key, required String token});

  @override
  State<BankRegistrationScreen> createState() => _BankRegistrationScreenState();
}

class _BankRegistrationScreenState extends State<BankRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankSearchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  final WalletService _walletService = WalletService(); 
  
  String? _selectedBankCode;
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _filteredBanks = [];
  bool _isLoading = false;
  OverlayEntry? _overlayEntry;
  final FocusNode _bankFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializeBanks();
    _bankFocusNode.addListener(() {
      if (!_bankFocusNode.hasFocus) _removeOverlay();
    });
  }

  void _initializeBanks() {
    final localBanks = [
      {'code': '068', 'name': 'Equity Bank Kenya Ltd'},
      {'code': '011', 'name': 'Kenya Commercial Bank (KCB)'},
      {'code': '011', 'name': 'Co-operative Bank'},
      {'code': '003', 'name': 'Absa Bank Kenya'},
      {'code': '044', 'name': 'Standard Chartered Bank'},
      {'code': '063', 'name': 'Diamond Trust Bank'},
      {'code': '007', 'name': 'NCBA Bank'},
      {'code': '070', 'name': 'Family Bank'},
    ];
    setState(() {
      _banks = localBanks;
      _filteredBanks = List.from(localBanks);
    });
  }

  // --- UI Helpers ---
  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Overlay Search Logic ---
  void _showOverlay() {
    _removeOverlay(); 
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 32, 
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 60), 
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 250),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredBanks.length,
                itemBuilder: (context, index) {
                  final bank = _filteredBanks[index];
                  return ListTile(
                    dense: true,
                    title: Text(bank['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Code: ${bank['code']}'),
                    onTap: () => _selectBank(bank),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _filterBanks(String query) {
    setState(() {
      _filteredBanks = _banks
          .where((bank) =>
              bank['name'].toLowerCase().contains(query.toLowerCase()) ||
              bank['code'].contains(query))
          .toList();
    });
    if (_bankFocusNode.hasFocus) _showOverlay();
  }

  void _selectBank(Map<String, dynamic> bank) {
    setState(() {
      _selectedBankCode = bank['code'];
      _bankSearchController.text = bank['name'];
    });
    _removeOverlay();
    _bankFocusNode.unfocus();
  }

  // --- API Call ---
  Future<void> _verifyAndRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    // 1. Get token from AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final String? token = authProvider.token;

    if (token == null) {
      _showSnackBar('Session expired. Please login.', Colors.red);
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // 2. Use your WalletService to call the backend
      final result = await _walletService.registerBankAccount(
        token, 
        _accountController.text.trim(),
        _selectedBankCode!,
        _accountNameController.text.trim(),
      );

      if (result != null && result['success'] == true) {
        _showSnackBar(result['message'] ?? 'Bank account registered!', Colors.green);
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result?['message'] ?? 'Verification failed', Colors.orange);
      }
    } catch (e) {
      _showSnackBar('Network connection error', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CompositedTransformTarget(
                link: _layerLink,
                child: TextFormField(
                  controller: _bankSearchController,
                  focusNode: _bankFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Select Bank *',
                    prefixIcon: Icon(Icons.account_balance),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: _filterBanks,
                  onTap: () {
                    if (_filteredBanks.isNotEmpty) _showOverlay();
                  },
                  validator: (value) => _selectedBankCode == null ? 'Please select a bank' : null,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(13)],
                decoration: const InputDecoration(
                  labelText: 'Account Number *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) => (value!.length < 10) ? 'Enter a valid account number' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _accountNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Account Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => (value!.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyAndRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text('Verify & Save Bank', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _bankFocusNode.dispose();
    _accountController.dispose();
    _accountNameController.dispose();
    _bankSearchController.dispose();
    super.dispose();
  }
}