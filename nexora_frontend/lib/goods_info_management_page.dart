import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/goods_info_record.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class GoodsInfoManagementPage extends StatefulWidget {
  const GoodsInfoManagementPage({super.key});

  @override
  State<GoodsInfoManagementPage> createState() => _GoodsInfoManagementPageState();
}

class _GoodsInfoManagementPageState extends State<GoodsInfoManagementPage> {
  List<GoodsInfoRecord> records = [];
  bool isLoading = true;
  String error = '';

  final _formKey = GlobalKey<FormState>();
  final _forController = TextEditingController();
  final _fromController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _volumeBuyingController = TextEditingController();
  final _volumeSellingController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _forController.dispose();
    _fromController.dispose();
    _volumeBuyingController.dispose();
    _volumeSellingController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    try {
      final data = await ApiService.getGoodsInfo();
      if (!mounted) return;
      setState(() {
        records = data.map((json) => GoodsInfoRecord.fromJson(json)).toList();
        isLoading = false;
        error = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      nxSnack(context, 'Select both start and end dates', isError: true);
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      nxSnack(context, 'End date must be after start date', isError: true);
      return;
    }

    final volumeBuying = double.parse(_volumeBuyingController.text);
    final volumeSelling = double.parse(_volumeSellingController.text);
    final price = double.parse(_priceController.text);

    final recordData = {
      'for_field': _forController.text,
      'from_field': _fromController.text,
      'start_date': _startDate!.toIso8601String(),
      'end_date': _endDate!.toIso8601String(),
      'volume_buying': volumeBuying,
      'volume_selling': volumeSelling,
      'price': price,
    };

    try {
      await ApiService.createGoodsInfo(recordData);
      _clearForm();
      await _loadRecords();
      if (!mounted) return;
      nxSnack(context, 'Record added');
    } catch (e) {
      if (!mounted) return;
      nxSnack(context, 'Failed to add record: $e', isError: true);
    }
  }

  void _showAddDialog() {
    _clearForm();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          String fmt(DateTime? d) => d == null ? 'Tap to select' : d.toLocal().toString().split(' ')[0];
          return nxDialog(
            context: dialogContext,
            title: 'New goods info record',
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  NxTextField(controller: _forController, label: 'For (product)', validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 10),
                  NxTextField(controller: _fromController, label: 'From (supplier)', validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final picked = await showDatePicker(context: dialogContext, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setDialogState(() => _startDate = picked);
                          },
                          child: _dateBox(fmt(_startDate), 'Start date'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final picked = await showDatePicker(context: dialogContext, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                            if (picked != null) setDialogState(() => _endDate = picked);
                          },
                          child: _dateBox(fmt(_endDate), 'End date'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: NxTextField(controller: _volumeBuyingController, label: 'Volume buying', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Enter a valid number' : null))),
                      const SizedBox(width: 10),
                      Expanded(child: NxTextField(controller: _volumeSellingController, label: 'Volume selling', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Enter a valid number' : null))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  NxTextField(controller: _priceController, label: 'Price', keyboardType: const TextInputType.numberWithOptions(decimal: true), validator: (v) => v == null || v.isEmpty ? 'Required' : (double.tryParse(v) == null ? 'Enter a valid number' : null)),
                ],
              ),
            ),
            actions: [
              NxButton(label: 'Cancel', variant: NxButtonVariant.ghost, onPressed: () => Navigator.pop(dialogContext)),
              NxButton(label: 'Add record', onPressed: _addRecord),
            ],
          );
        },
      ),
    );
  }


  Widget _dateBox(String text, String fallback) {
    final palette = nxOf(context);
    final hasValue = text != fallback;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.border)),
      child: Row(
        children: [
          Icon(Icons.calendar_today_rounded, size: 17, color: palette.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13.5, color: hasValue ? palette.textPrimary : palette.textMuted, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(GoodsInfoRecord r) async {
    final confirmed = await nxConfirm(
      context,
      title: 'Delete record',
      message: 'Delete the bulk info for "${r.forField}" from "${r.fromField}"? This cannot be undone.',
      confirmLabel: 'Delete',
      variant: NxButtonVariant.danger,
    );
    if (!confirmed) return;
    try {
      await ApiService.deleteGoodsInfo(r.id);
      await _loadRecords();
      if (!mounted) return;
      nxSnack(context, 'Record deleted');
    } catch (e) {
      if (!mounted) return;
      nxSnack(context, 'Delete failed: $e', isError: true);
    }
  }

  void _clearForm() {
    _forController.clear();
    _fromController.clear();
    _startDate = null;
    _endDate = null;
    _volumeBuyingController.clear();
    _volumeSellingController.clear();
    _priceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    if (isLoading) {
      return const NxLoader();
    }

    if (error.isNotEmpty && records.isEmpty) {
      return NxErrorView(message: error, onRetry: _loadRecords);
    }

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const NxBackButton(),
        title: const Text('Goods Costs'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: palette.primary,
        foregroundColor: palette.textOnAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New record'),
      ),
      body: records.isEmpty
          ? NxEmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No goods info records yet',
              message: 'Use it to log bulk purchases: volume bought, volume sold and the price paid to a supplier.',
              actionLabel: 'New record',
              onAction: _showAddDialog,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 900;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                  itemCount: records.length,
                  itemBuilder: (context, i) {
                    final r = records[i];
                    if (wide) {
                      return NxCard(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(r.forField, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                                Text('From ${r.fromField}', style: TextStyle(fontSize: 12, color: palette.textMuted)),
                              ]),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('${_fmt(r.startDate)}  →  ${_fmt(r.endDate)}', style: TextStyle(fontSize: 13, color: palette.textMuted)),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text('${r.volumeBuying} buy · ${r.volumeSelling} sell', style: TextStyle(fontSize: 12.5, color: palette.textMuted)),
                            ),
                            SizedBox(
                              width: 90,
                              child: Text('\$${r.price.toStringAsFixed(2)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: palette.success)),
                            ),
                            NxIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Delete', color: palette.danger, onTap: () => _deleteRecord(r)),
                          ],
                        ),
                      );
                    }
                    return NxCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      onTap: () => _deleteRecord(r),
                      child: Row(
                        children: [
                          NxIconBlock(icon: Icons.receipt_long_outlined, color: palette.info),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${r.forField} — ${_fmt(r.startDate)} → ${_fmt(r.endDate)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: palette.textPrimary)),
                              Text('From ${r.fromField} · Buy ${r.volumeBuying} · Sell ${r.volumeSelling}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: palette.textMuted)),
                            ]),
                          ),
                          const SizedBox(width: 8),
                          Text('\$${r.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w800, color: palette.success)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _fmt(DateTime date) => date.toLocal().toString().split(' ')[0];
}
