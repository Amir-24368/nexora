import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'user_cart_manager.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

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
      nxSnack(context, 'Payment successful!');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      nxSnack(context, 'Payment failed: ${e.toString().replaceFirst('Exception: ', '')}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Secure payment'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ---- Order summary ----
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: nxHeroGradient),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order total', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                            SizedBox(height: 2),
                            Text('Encrypted & secure', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                      ),
                      Text('\$${widget.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                NxCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        NxTextField(
                          controller: _cardNumberController,
                          label: 'Card number',
                          hint: '1234 5678 9012 3456',
                          prefixIcon: Icons.credit_card_rounded,
                          keyboardType: TextInputType.number,
                          maxLength: 19,
                          onChanged: _formatCardNumber,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (v.replaceAll(RegExp(r'\s'), '').length != 16) return 'Enter all 16 digits';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: NxTextField(
                                controller: _expiryController,
                                label: 'Expiry',
                                hint: 'MM/YY',
                                keyboardType: TextInputType.number,
                                maxLength: 5,
                                onChanged: _formatExpiry,
                                validator: (v) => v == null || v.isEmpty ? 'Required' : RegExp(r'^(0[1-9]|1[0-2])\/([0-9]{2})$').hasMatch(v) ? null : 'Use MM/YY',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: NxTextField(
                                controller: _cvvController,
                                label: 'CVV2',
                                hint: '123',
                                obscure: true,
                                keyboardType: TextInputType.number,
                                maxLength: 3,
                                suffix: const Icon(Icons.shield_outlined, size: 20),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : v.length == 3 ? null : '3 digits',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        NxTextField(
                          controller: _dynamicPasswordController,
                          label: 'Dynamic password (OTP)',
                          hint: '4-6 digits',
                          obscure: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          prefixIcon: Icons.password_rounded,
                          validator: (v) => v == null || v.isEmpty ? 'Required' : (v.length >= 4 && v.length <= 6) ? null : '4-6 digits',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: NxButton(
                    label: _isProcessing ? 'Processing…' : 'Pay now',
                    icon: Icons.lock_open_rounded,
                    onPressed: _isProcessing ? null : _processPayment,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This is a demo checkout — no real charge is made.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.textMuted),
                ),
              ],
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
