import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  final TextEditingController _upiIdController = TextEditingController();
  final TextEditingController _upiNameController = TextEditingController();

  final List<Map<String, dynamic>> _upiOptions = [];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSaving = false;

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _paymentDocs = [];

  @override
  void initState() {
    super.initState();
    _fetchPaymentDocuments();
  }

  Future<void> _fetchPaymentDocuments() async {
    try {
      final querySnapshot = await _firestore.collection('payment').get();

      setState(() {
        _paymentDocs = querySnapshot.docs;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch payment docs: $e')),
      );
    }
  }

  void _addUpiOption() {
    final upiId = _upiIdController.text.trim();
    final upiName = _upiNameController.text.trim();

    if (upiId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a UPI ID')));
      return;
    }

    setState(() {
      _upiOptions.add({
        'upiId': upiId,
        'upiName': upiName.isEmpty ? 'Unnamed UPI' : upiName,
        'status': 'active',
        'preference': 1,
      });
      _upiIdController.clear();
      _upiNameController.clear();
    });
  }

  Future<void> _saveUpiOptions() async {
    if (_upiOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one UPI option before saving'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final docRef = _firestore.collection('payment').doc('payment');

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

        if (snapshot.exists) {
          final existingOptions = List<Map<String, dynamic>>.from(
            snapshot.data()?['upiOptions'] ?? [],
          );

          int highestPreference = 0;
          for (var option in existingOptions) {
            final pref = option['preference'];
            if (pref is int && pref > highestPreference) {
              highestPreference = pref;
            }
          }

          int nextPreference = highestPreference + 1;

          final newOptionsWithPref = _upiOptions.map((option) {
            final updatedOption = Map<String, dynamic>.from(option);
            updatedOption['preference'] = nextPreference;
            nextPreference++;
            return updatedOption;
          }).toList();

          final updatedOptions = [...existingOptions, ...newOptionsWithPref];

          transaction.update(docRef, {
            'upiOptions': updatedOptions,
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else {
          transaction.set(docRef, {
            'upiOptions': _upiOptions,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI payment options saved successfully')),
      );

      setState(() {
        _upiOptions.clear();
      });

      await _fetchPaymentDocuments();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save UPI options: $e')));
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    _upiIdController.dispose();
    _upiNameController.dispose();
    super.dispose();
  }

  Widget _buildPaymentCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final upiOptions = List<Map<String, dynamic>>.from(
      data['upiOptions'] ?? [],
    );

    final activeOptions = upiOptions
        .where((option) => option['status'] == 'active')
        .toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          'Payment Doc ID: ${doc.id}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          'Created: ${data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toLocal().toString() : "Unknown"}',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: activeOptions.isEmpty
            ? [
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'No active UPI options',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ]
            : activeOptions.map((option) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    option['upiName'] ?? 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${option['upiId'] ?? ''}\nPreference: ${option['preference'] ?? "N/A"}',
                    style: const TextStyle(color: Colors.black87),
                  ),
                  leading: const Icon(Icons.payment, color: Colors.orange),
                );
              }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Management'),
        backgroundColor: Colors.deepOrange,
        elevation: 5,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Input form container
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your text',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _upiIdController,
                        decoration: InputDecoration(
                          labelText: 'UPI ID',
                          hintText: 'example@upi',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.account_balance_wallet),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _upiNameController,
                        decoration: InputDecoration(
                          labelText: 'UPI Name (optional)',
                          hintText: 'Google Pay, PhonePe, etc.',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          prefixIcon: const Icon(Icons.payment),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text(
                            'Add UPI Option',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _addUpiOption,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Current UPI options added (preview)
              Expanded(
                flex: 1,
                child: _upiOptions.isEmpty
                    ? Center(
                        child: Text(
                          'No UPI options added yet',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _upiOptions.length,
                        itemBuilder: (context, index) {
                          final option = _upiOptions[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                option['upiName'] ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(option['upiId'] ?? ''),
                              trailing: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Remove this UPI option',
                                onPressed: () {
                                  setState(() {
                                    _upiOptions.removeAt(index);
                                  });
                                },
                              ),
                              leading: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.deepOrange,
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 10),
              const Divider(thickness: 2),

              // Firestore payment docs list
              Expanded(
                flex: 2,
                child: _paymentDocs.isEmpty
                    ? Center(
                        child: Text(
                          'No payment documents found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _paymentDocs.length,
                        itemBuilder: (context, index) =>
                            _buildPaymentCard(_paymentDocs[index]),
                      ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveUpiOptions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text(
                          'Save UPI Options to Firebase',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
