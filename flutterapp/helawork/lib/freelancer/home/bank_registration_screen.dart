import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:helawork/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BankRegistrationScreen extends StatefulWidget {
  const BankRegistrationScreen({super.key});

  @override
  State<BankRegistrationScreen> createState() => _BankRegistrationScreenState();
}

class _BankRegistrationScreenState extends State<BankRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _bankSearchController = TextEditingController();
  
  String? _selectedBankName;
  String? _selectedBankCode;
  List<Map<String, dynamic>> _banks = [];
  List<Map<String, dynamic>> _filteredBanks = [];
  bool _isLoading = false;
  bool _showBankDropdown = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    _accountController.text = '0123456789';
    _accountNameController.text = 'TEST ACCOUNT 0123456789';
    
    _initializeBanks();
  }

  void _initializeBanks() {
    final localBanks = [
      {'code': '01', 'name': 'Kenya Commercial Bank (Kenya) Ltd'},
      {'code': '02', 'name': 'Standard Chartered Bank Kenya'},
      {'code': '03', 'name': 'Absa Bank Kenya Plc'},
      {'code': '07', 'name': 'NCBA Bank Kenya'},
      {'code': '11', 'name': 'Co-operative Bank of Kenya Ltd'},
      {'code': '12', 'name': 'National Bank of Kenya Ltd'},
      {'code': '63', 'name': 'Diamond Trust Bank Kenya Ltd'},
      {'code': '68', 'name': 'Equity Bank Kenya Ltd'},
    ];
    
    setState(() {
      _banks = localBanks;
      _filteredBanks = List.from(localBanks);
      
      final equityBank = localBanks.firstWhere(
        (bank) => bank['name'] == 'Equity Bank Kenya Ltd',
        orElse: () => localBanks.first,
      );
      
      _selectedBankName = equityBank['name'];
      _selectedBankCode = equityBank['code'];
      _bankSearchController.text = equityBank['name']!;
    });
    
    print('Initialized banks. Selected bank: $_selectedBankName ($_selectedBankCode)');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<String?> _getUserToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_token') ?? prefs.getString('employer_token');
    } catch (e) {
      print('ERROR getting token: $e');
      return null;
    }
  }

  void _filterBanks(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredBanks = List.from(_banks);
        _showBankDropdown = true;
      });
      return;
    }

    setState(() {
      _filteredBanks = _banks
          .where((bank) =>
              bank['name'].toLowerCase().contains(query.toLowerCase()) ||
              bank['code'].contains(query))
          .toList();
      _showBankDropdown = true;
    });
  }

  void _selectBank(Map<String, dynamic> bank) {
    print('Selecting bank: ${bank['name']} (${bank['code']})');
    
    setState(() {
      _selectedBankName = bank['name'];
      _selectedBankCode = bank['code'];
      _bankSearchController.text = bank['name'];
      _showBankDropdown = false;
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formKey.currentState?.validate();
    });
  }

  String? _validateBank(String? value) {
    if (_selectedBankCode == null || _selectedBankCode!.isEmpty) {
      return 'Please select a bank';
    }
    return null;
  }

  Future<void> _verifyAndRegister() async {
    print('=== STARTING VERIFICATION ===');
    print('Bank Code: $_selectedBankCode');
    print('Bank Name: $_selectedBankName');
    print('Account: ${_accountController.text}');
    print('Name: ${_accountNameController.text}');
    
    if (!_formKey.currentState!.validate()) {
      print('FORM VALIDATION FAILED');
      
      if (_selectedBankCode == null) {
        print('ERROR: Bank not selected');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a bank from the list'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    print('FORM VALIDATION PASSED');
    
    setState(() => _isLoading = true);
    
    try {
      final String? token = await _getUserToken();
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to continue'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      print('Making API call with token: ${token.substring(0, min(20, token.length))}...');
      
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/api/banks/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'bank_code': _selectedBankCode,
          'account_number': _accountController.text.trim(),
          'account_name': _accountNameController.text.trim(),
        }),
      );

      print('API Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank account registered successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true);
      } else {
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Registration failed';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed with status: ${response.statusCode}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    setState(() => _isLoading = false);
    print('=== VERIFICATION COMPLETED ===');
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Bank Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Important:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selected: ${_selectedBankName ?? "No bank selected"}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Bank Code: ${_selectedBankCode ?? "N/A"}',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_selectedBankName == 'Equity Bank Kenya Ltd')
                        Text(
                          'Note: Using Paystack code 68 for Equity Bank Kenya Ltd',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                const Text(
                  'Select Bank *',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                
                TextFormField(
                  controller: _bankSearchController,
                  decoration: InputDecoration(
                    hintText: 'Type to search for bank...',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _bankSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _bankSearchController.clear();
                                _filteredBanks = List.from(_banks);
                                _showBankDropdown = true;
                              });
                            },
                          )
                        : null,
                    errorStyle: const TextStyle(color: Colors.red),
                  ),
                  onChanged: _filterBanks,
                  onTap: () {
                    setState(() {
                      _showBankDropdown = true;
                    });
                  },
                  validator: _validateBank,
                ),
                
                if (_showBankDropdown && _filteredBanks.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredBanks.length,
                      itemBuilder: (context, index) {
                        final bank = _filteredBanks[index];
                        final isSelected = _selectedBankCode == bank['code'];
                        
                        return ListTile(
                          title: Text(bank['name']),
                          subtitle: Text('Code: ${bank['code']}'),
                          tileColor: isSelected ? Colors.blue[50] : null,
                          trailing: isSelected 
                              ? const Icon(Icons.check, color: Colors.green, size: 20)
                              : null,
                          onTap: () => _selectBank(bank),
                        );
                      },
                    ),
                  ),
                
                if (_selectedBankName != null && _selectedBankCode != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SELECTED BANK:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedBankName!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Bank Code: $_selectedBankCode',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _accountController,
                  decoration: const InputDecoration(
                    labelText: 'Account Number *',
                    border: OutlineInputBorder(),
                    hintText: '0123456789',
                    prefixIcon: Icon(Icons.credit_card),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account number';
                    }
                    if (value.length != 10) {
                      return 'Account number must be 10 digits';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _accountNameController,
                  decoration: const InputDecoration(
                    labelText: 'Account Name *',
                    border: OutlineInputBorder(),
                    hintText: 'As it appears on bank statement',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter account name';
                    }
                    if (value.length < 2) {
                      return 'Account name is too short';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                
                const SizedBox(height: 24),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.amber),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Using test data: Account=0123456789, Name=TEST ACCOUNT 0123456789',
                          style: TextStyle(color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyAndRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Verifying with Paystack...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.verified_user, size: 24),
                              SizedBox(width: 12),
                              Text(
                                'Verify & Register Account',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API Endpoint:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text('POST ${AppConfig.baseUrl}/api/banks/'),
                      SizedBox(height: 8),
                      Text(
                        'Will send: bank_code, account_number, account_name',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}