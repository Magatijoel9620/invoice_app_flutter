import 'package:flutter/material.dart';
import 'package:myapp/models/line_item.dart';
import '../models/invoice.dart';
import '../services/invoice_storage_service.dart';
import 'invoice_list_screen.dart';

class InvoiceEntryScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final Invoice? existingInvoice;

  const InvoiceEntryScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    this.existingInvoice,
  });

  @override
  _InvoiceEntryScreenState createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _dateController = TextEditingController();
  List<LineItem> lineItems = [];
  double _totalAmount = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      _clientNameController.text = widget.existingInvoice!.clientName;
      _invoiceNumberController.text = widget.existingInvoice!.invoiceNumber;
      _dateController.text =
          widget.existingInvoice!.date.toLocal().toString().split(' ')[0];
      lineItems.addAll(widget.existingInvoice!.lineItems);
      _totalAmount = widget.existingInvoice!.totalAmount;
    } else {
      _dateController.text = DateTime.now().toLocal().toString().split(' ')[0];
    }
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _invoiceNumberController.dispose();
    _dateController.dispose();
    for (var item in lineItems) {
      item.descriptionController.dispose();
      item.quantityController.dispose();
      item.unitPriceController.dispose();
    }
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      lineItems.add(LineItem(
        description: '',
        quantity: 1,
        unitPrice: 0.0,
        total: 0.0,
        descriptionController: TextEditingController(),
        quantityController: TextEditingController(text: '1'),
        unitPriceController: TextEditingController(text: '0.0'),
      ));
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      lineItems.removeAt(index);
      _updateTotal();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  void _updateTotal() {
    double total = 0;
    for (var item in lineItems) {
      total += item.quantity * item.unitPrice;
    }
    setState(() {
      _totalAmount = total;
    });
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.validate() ?? false) {
      bool allValid = lineItems.every(
        (item) =>
            item.description.isNotEmpty &&
            item.quantity > 0 &&
            item.unitPrice >= 0,
      );

      if (!allValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all line item fields correctly'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final invoice = Invoice(
        id: widget.existingInvoice?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        clientName: _clientNameController.text,
        invoiceNumber: _invoiceNumberController.text,
        date: DateTime.parse(_dateController.text),
        lineItems: lineItems,
        totalAmount: _totalAmount,
      );

      try {
        if (widget.existingInvoice == null) {
          await InvoiceStorageService.saveInvoice(invoice);
        } else {
          await InvoiceStorageService.updateInvoice(
            widget.existingInvoice!,
            invoice,
          );
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => InvoiceListScreen(
              isDarkMode: widget.isDarkMode,
              toggleTheme: widget.toggleTheme,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving invoice: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all the required fields.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Entry'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _invoiceNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Invoice Number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _dateController,
                        decoration: const InputDecoration(
                          labelText: 'Date (YYYY-MM-DD)',
                          prefixIcon: Icon(Icons.date_range),
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ...lineItems
                  .asMap()
                  .entries
                  .map((entry) => _buildLineItem(entry.key, entry.value))
                  .toList(),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Line Item'),
                  onPressed: _addLineItem,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        '\$${_totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save Invoice'),
                  onPressed: _saveInvoice,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLineItem(int index, LineItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: item.descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => item.description = value,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: item.quantityController,
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  item.quantity = int.tryParse(value) ?? 1;
                  _updateTotal();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: item.unitPriceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '\$',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  item.unitPrice = double.tryParse(value.replaceAll(',', '.')) ?? 0;
                  _updateTotal();
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _removeLineItem(index),
            ),
          ],
        ),
      ),
    );
  }
}
