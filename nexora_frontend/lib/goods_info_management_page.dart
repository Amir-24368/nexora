import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/goods_info_record.dart';

class GoodsInfoManagementPage extends StatefulWidget {
  const GoodsInfoManagementPage({super.key});

  @override
  State<GoodsInfoManagementPage> createState() => _GoodsInfoManagementPageState();
}

class _GoodsInfoManagementPageState extends State<GoodsInfoManagementPage> {
  List<GoodsInfoRecord> records = [];

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

  Future<void> _loadRecords() async {
    try {
      final data = await ApiService.getGoodsInfo();
      setState(() {
        records = data.map((json) => GoodsInfoRecord.fromJson(json)).toList();
      });
    } catch (e) {
      print('Error loading goods info: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load records: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _addRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both start and end dates'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date must be after start date'), backgroundColor: Colors.red),
      );
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
      _loadRecords();
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record added'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add record: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteRecord(String id) async {
    try {
      await ApiService.deleteGoodsInfo(id);
      _loadRecords();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e'), backgroundColor: Colors.red),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goods Information Management'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _forController,
                      decoration: const InputDecoration(labelText: 'For (Product)'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _fromController,
                      decoration: const InputDecoration(labelText: 'From (Supplier)'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _selectDate(context, true),
                            child: Text(_startDate == null
                                ? 'Start Date'
                                : 'Start: ${_startDate!.toLocal().toString().split(' ')[0]}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: () => _selectDate(context, false),
                            child: Text(_endDate == null
                                ? 'End Date'
                                : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}'),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: _volumeBuyingController,
                      decoration: const InputDecoration(labelText: 'Volume Buying'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _volumeSellingController,
                      decoration: const InputDecoration(labelText: 'Volume Selling'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Enter a valid number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _addRecord,
                      child: const Text('Add Record'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: records.isEmpty
                ? const Center(child: Text('No records'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('For')),
                        DataColumn(label: Text('From')),
                        DataColumn(label: Text('Start')),
                        DataColumn(label: Text('End')),
                        DataColumn(label: Text('Buy Vol')),
                        DataColumn(label: Text('Sell Vol')),
                        DataColumn(label: Text('Price')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: records.map((r) => DataRow(cells: [
                        DataCell(Text(r.forField)),
                        DataCell(Text(r.fromField)),
                        DataCell(Text(r.startDate.toLocal().toString().split(' ')[0])),
                        DataCell(Text(r.endDate.toLocal().toString().split(' ')[0])),
                        DataCell(Text(r.volumeBuying.toString())),
                        DataCell(Text(r.volumeSelling.toString())),
                        DataCell(Text('\$${r.price.toStringAsFixed(2)}')),
                        DataCell(IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecord(r.id),
                        )),
                      ])).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}