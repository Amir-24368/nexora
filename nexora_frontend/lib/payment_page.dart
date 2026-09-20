import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'user_cart_manager.dart';

class PaymentPage extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;
  final String username;
  const PaymentPage({super.key, required this.cartItems, required this.totalAmount, required this.username});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _dynamicPasswordController = TextEditingController();
  bool _isProcessing = false;

  void _formatCardNumber(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    String formatted = '';
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += digits[i];
    }
    _cardNumberController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }

  void _formatExpiry(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) digits = '${digits.substring(0, 2)}/${digits.substring(2)}';
    _expiryController.value = TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);

    try {
      // Link the purchase to the REAL logged-in account (email from the
      // stored session) -- the display username may be a full name, which
      // would break the backend's email-based customer matching.
      final email = await ApiService.getCurrentUserEmail();

      // Build the real sale payload: one line item per cart entry.
      // The backend recomputes the total server-side and links the customer
      // by email so the RFM engine gets fed automatically.
      final saleData = {
        'customer_email': email,
        'customer_name': widget.username,
        'status': 'COMPLETED',
        'items': widget.cartItems
            .map((item) => {
                  'product': item.product.id,
                  'quantity': item.quantity,
                  'price': item.product.effectivePrice,
                })
            .toList(),
      };

      await ApiService.createSale(saleData);

      CartManager().clearCart();
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString().replaceFirst('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secure Payment')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('Payment Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:'),
                          Text('\$${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                      decoration: const InputDecoration(labelText: 'Card Number', hintText: '1234 5678 9012 3456', prefixIcon: Icon(Icons.credit_card)),
                      onChanged: _formatCardNumber,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (v.replaceAll(RegExp(r'\s'), '').length != 16) return '16 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _expiryController,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            decoration: const InputDecoration(labelText: 'Expiry', hintText: 'MM/YY'),
                            onChanged: _formatExpiry,
                            validator: (v) => v == null || v.isEmpty ? 'Required' : RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(v) ? null : 'MM/YY',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cvvController,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                            obscureText: true,
                            decoration: const InputDecoration(labelText: 'CVV2', hintText: '123'),
                            validator: (v) => v == null || v.isEmpty ? 'Required' : v.length == 3 ? null : '3 digits',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dynamicPasswordController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Dynamic Password (OTP)', hintText: '4-6 digits'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : (v.length >= 4 && v.length <= 6) ? null : '4-6 digits',
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isProcessing ? null : _processPayment,
                        icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.lock_open),
                        label: Text(_isProcessing ? 'Processing...' : 'Pay Now'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _dynamicPasswordController.dispose();
    super.dispose();
  }
}