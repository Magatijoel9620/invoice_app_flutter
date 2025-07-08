import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatters
import 'package:intl/intl.dart'; // For date formatting and number formatting
import 'package:myapp/models/line_item.dart'; // Assuming your LineItem model
import '../models/invoice.dart';
import '../services/invoice_storage_service.dart';
import 'invoice_list_screen.dart';
// import 'invoice_list_screen.dart'; // We'll pop with a result instead of direct navigation

// (LineItemUIData class remains the same as you provided)
class LineItemUIData {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  String description;
  int quantity;
  double unitPrice;
  final UniqueKey id = UniqueKey();

  LineItemUIData({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  })  : descriptionController = TextEditingController(text: description),
        quantityController = TextEditingController(text: quantity.toString()),
        unitPriceController = TextEditingController(text: unitPrice.toStringAsFixed(2));

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    unitPriceController.dispose();
  }

  LineItem toLineItemModel() {
    return LineItem(
      description: descriptionController.text,
      quantity: int.tryParse(quantityController.text) ?? 1,
      unitPrice: double.tryParse(unitPriceController.text.replaceAll(',', '.')) ?? 0.0,
      total: (int.tryParse(quantityController.text) ?? 1) * (double.tryParse(unitPriceController.text.replaceAll(',', '.')) ?? 0.0),
    );
  }
}


class InvoiceEntryScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final Invoice? existingInvoice;
  final bool isInBottomSheet; // New parameter
  final ScrollController? scrollController; // New parameter for DraggableScrollableSheet

  const InvoiceEntryScreen({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    this.existingInvoice,
    this.isInBottomSheet = false, // Default to false
    this.scrollController,
  });

  @override
  _InvoiceEntryScreenState createState() => _InvoiceEntryScreenState();
}

class _InvoiceEntryScreenState extends State<InvoiceEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _clientNameController = TextEditingController();
  final _invoiceNumberController = TextEditingController();
  final _dateController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  List<LineItemUIData> _lineItemUIList = [];
  double _totalAmount = 0.0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingInvoice != null) {
      final invoice = widget.existingInvoice!;
      _clientNameController.text = invoice.clientName;
      _invoiceNumberController.text = invoice.invoiceNumber;
      _dateController.text = _dateFormat.format(invoice.date.toLocal());
      _lineItemUIList = invoice.lineItems.map((item) => LineItemUIData(
        description: item.description,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
      )).toList();
      // totalAmount should come from the invoice model if it stores it,
      // otherwise calculate it if necessary.
      // _totalAmount = invoice.totalAmount; // Assuming Invoice model has accurate total
    } else {
      _dateController.text = _dateFormat.format(DateTime.now().toLocal());
    }
    _updateTotalAmount(); // Calculate initial total
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _invoiceNumberController.dispose();
    _dateController.dispose();
    for (var itemData in _lineItemUIList) {
      itemData.dispose();
    }
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      _lineItemUIList.add(LineItemUIData(description: '', quantity: 1, unitPrice: 0.0));
    });
    _updateTotalAmount();
  }

  void _removeLineItem(int index) {
    if (index < 0 || index >= _lineItemUIList.length) return;
    final itemData = _lineItemUIList[index];
    setState(() {
      _lineItemUIList.removeAt(index);
    });
    itemData.dispose();
    _updateTotalAmount();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(DateTime(2000)) ? DateTime.now() : initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: widget.isDarkMode ? ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
          ) : ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ), dialogTheme: DialogThemeData(backgroundColor: Theme.of(context).colorScheme.surfaceContainer),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = _dateFormat.format(picked.toLocal());
      });
    }
  }

  void _updateTotalAmount() {
    double total = 0;
    for (var itemData in _lineItemUIList) {
      final qty = int.tryParse(itemData.quantityController.text) ?? 0;
      final price = double.tryParse(itemData.unitPriceController.text.replaceAll(',', '.')) ?? 0.0;
      total += qty * price;
    }
    setState(() {
      _totalAmount = total;
    });
  }

  Future<void> _saveInvoice() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showErrorSnackBar('Please fill all required fields in the invoice details.');
      return;
    }

    for (int i = 0; i < _lineItemUIList.length; i++) {
      final item = _lineItemUIList[i];
      if (item.descriptionController.text.isEmpty) {
        _showErrorSnackBar('Please enter a description for line item ${i + 1}.');
        return;
      }
      if ((int.tryParse(item.quantityController.text) ?? 0) <= 0) {
        _showErrorSnackBar('Quantity must be greater than 0 for line item ${i + 1}.');
        return;
      }
      if ((double.tryParse(item.unitPriceController.text.replaceAll(',', '.')) ?? -1) < 0) {
        _showErrorSnackBar('Unit price cannot be negative for line item ${i + 1}.');
        return;
      }
    }
    if (_lineItemUIList.isEmpty && !widget.isInBottomSheet) { // Allow empty for bottom sheet if user just cancels
      _showErrorSnackBar('Please add at least one line item.');
      return;
    }


    setState(() => _isLoading = true);

    final List<LineItem> finalLineItems = _lineItemUIList.map((uiData) {
      return uiData.toLineItemModel();
    }).toList();


    final invoice = Invoice(
      id: widget.existingInvoice?.id ?? '', // Let storage service assign ID if new
      clientName: _clientNameController.text.trim(),
      invoiceNumber: _invoiceNumberController.text.trim(),
      date: _dateFormat.parse(_dateController.text),
      lineItems: finalLineItems,
      totalAmount: _totalAmount, // This is now calculated and stored
      isArchived: widget.existingInvoice?.isArchived ?? false,
    );

    try {
      if (widget.existingInvoice == null) {
        await InvoiceStorageService.addInvoice(invoice);
      } else {
        // Ensure you pass the correct existing invoice ID for update
        await InvoiceStorageService.updateInvoice(invoice);
      }

      if (mounted) {
        _showSuccessSnackBar('Invoice saved successfully!');
        // If in bottom sheet, pop with true. Otherwise, navigate.
        if (widget.isInBottomSheet) {
          Navigator.pop(context, true); // Pop with success result
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => InvoiceListScreen(isDarkMode: widget.isDarkMode, toggleTheme: widget.toggleTheme
                // Pass any necessary parameters to your InvoiceListScreen
                // For example, if it needs the theme toggle:
                // isDarkMode: widget.isDarkMode,
                // toggleTheme: widget.toggleTheme,
              ),
            ),
                (Route<dynamic> route) => false, // This predicate removes all previous routes
          );
          // If you want to simply push it on top and allow going back to the
          // home/dashboard (whatever was before InvoiceEntryScreen), you might use:
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (context) => InvoiceListScreen(...)),
          // );
          // Or if InvoiceListScreen is always the "root" after this action:
          // Navigator.of(context).popUntil((route) => route.isFirst); // Go to first route
          // Navigator.of(context).push(MaterialPageRoute(builder: (context) => InvoiceListScreen(...)));

        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error saving invoice: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        // For bottom sheet, margin ensures it doesn't get obscured by system UI
        margin: widget.isInBottomSheet ? const EdgeInsets.fromLTRB(10, 5, 10, 10) : null,

      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        margin: widget.isInBottomSheet ? const EdgeInsets.fromLTRB(10, 5, 10, 10) : null,
      ),
    );
  }

  // Helper to build the main form content, reusable by both modes
  Widget _buildFormContent(ThemeData theme, ColorScheme colorScheme, TextTheme textTheme) {
    return SingleChildScrollView(
      controller: widget.scrollController, // Use passed controller for DraggableScrollableSheet
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isInBottomSheet) // Show details card only in full screen
              _buildInvoiceDetailsCard(theme, colorScheme),
            if (!widget.isInBottomSheet) const SizedBox(height: 24),

            if(widget.isInBottomSheet) ...[ // Specific layout for top of bottom sheet
              _buildTextFormField(
                controller: _clientNameController,
                labelText: 'Client Name',
                prefixIcon: Icons.person_outline,
                validator: (value) => (value == null || value.isEmpty) ? 'Client name is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextFormField(
                      controller: _invoiceNumberController,
                      labelText: 'Invoice Number',
                      prefixIcon: Icons.numbers_outlined,
                      validator: (value) => (value == null || value.isEmpty) ? 'Invoice number is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextFormField(
                      controller: _dateController,
                      labelText: 'Date', // Shorter label for smaller space
                      prefixIcon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      validator: (value) => (value == null || value.isEmpty) ? 'Date is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: colorScheme.outline.withOpacity(0.5)),
              const SizedBox(height: 10),
            ],

            Text('Line Items', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_lineItemUIList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.list_alt_outlined, size: 48, color: colorScheme.outline),
                      const SizedBox(height: 8),
                      Text('No line items yet.', style: textTheme.titleMedium?.copyWith(color: colorScheme.outline)),
                      Text('Click "Add Line Item" to start.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
                    ],
                  ),
                ),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lineItemUIList.length,
              itemBuilder: (context, index) {
                return _buildLineItemWidget(_lineItemUIList[index], index, theme);
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Add Line Item'),
                onPressed: _addLineItem,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildTotalAmountCard(theme, colorScheme),
            // Save button is handled differently for bottom sheet vs full screen
            if (!widget.isInBottomSheet) ...[
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Invoice'),
                  onPressed: _isLoading ? null : _saveInvoice,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ]
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    Widget mainContent = Stack(
      children: [
        _buildFormContent(theme, colorScheme, textTheme), // Reusable form part
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );

    if (widget.isInBottomSheet) {
      return Material( // Or Container, ensure it has a background color from the theme
        color: theme.canvasColor, // Use canvasColor for the sheet background itself
        child: Column(
          mainAxisSize: MainAxisSize.min, // Important for Column in bottom sheet
          children: [
            // Custom Header for the sheet
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingInvoice == null ? 'New Invoice' : 'Edit Invoice',
                    style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                    onPressed: _isLoading ? null : () => Navigator.pop(context), // Dismiss without saving
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: mainContent), // The form content goes here
            // Save/Cancel buttons at the bottom of the sheet
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: _isLoading ? null : () => Navigator.pop(context), // Dismiss without saving
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_alt_outlined),
                    label: const Text('Save'),
                    onPressed: _isLoading ? null : _saveInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Original full-screen Scaffold implementation
      return Scaffold(
        // appBar: AppBar(
        //   title: Text(widget.existingInvoice == null ? 'New Invoice' : 'Edit Invoice'),
        //   leading: IconButton(
        //     icon: const Icon(Icons.close),
        //     onPressed: () => Navigator.of(context).pop(), // Just pop for full screen close
        //   ),
        //   actions: [
        //     // Theme toggle could be here if needed for full screen mode
        //     // IconButton(
        //     //   icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
        //     //   onPressed: widget.toggleTheme,
        //     // ),
        //   ],
        // ),
        body: mainContent,
      );
    }
  }

  // _buildInvoiceDetailsCard, _buildLineItemWidget, _buildTotalAmountCard, _buildTextFormField
  // remain largely the same, but ensure they use 'theme' and 'colorScheme' passed to them
  // or `Theme.of(context)` if appropriate.

  Widget _buildInvoiceDetailsCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoice Details', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
            const Divider(height: 20),
            _buildTextFormField(
              controller: _clientNameController,
              labelText: 'Client Name',
              prefixIcon: Icons.person_outline,
              validator: (value) => (value == null || value.isEmpty) ? 'Client name is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _invoiceNumberController,
              labelText: 'Invoice Number',
              prefixIcon: Icons.numbers_outlined,
              validator: (value) => (value == null || value.isEmpty) ? 'Invoice number is required' : null,
            ),
            const SizedBox(height: 16),
            _buildTextFormField(
              controller: _dateController,
              labelText: 'Date (YYYY-MM-DD)',
              prefixIcon: Icons.calendar_today_outlined,
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) => (value == null || value.isEmpty) ? 'Date is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineItemWidget(LineItemUIData itemData, int index, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Item ${index + 1}', style: theme.textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  onPressed: () => _removeLineItem(index),
                  tooltip: 'Remove Item',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildTextFormField(
              controller: itemData.descriptionController,
              labelText: 'Description',
              prefixIcon: Icons.description_outlined,
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              onChanged: (_) => _updateTotalAmount(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    controller: itemData.quantityController,
                    labelText: 'Qty',
                    prefixIcon: Icons.format_list_numbered,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => (int.tryParse(v!) ?? 0) <= 0 ? 'Invalid' : null,
                    onChanged: (_) => _updateTotalAmount(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextFormField(
                    controller: itemData.unitPriceController,
                    labelText: 'Unit Price',
                    prefixIcon: Icons.attach_money,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    validator: (v) => (double.tryParse(v!.replaceAll(',', '.')) ?? -1) < 0 ? 'Invalid' : null,
                    onChanged: (_) => _updateTotalAmount(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAmountCard(ThemeData theme, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Amount:', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
            Text(
              _currencyFormat.format(_totalAmount),
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    IconData? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
  }) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: theme.colorScheme.primary.withOpacity(0.8)) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3), // Slightly different fill
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), // Adjusted padding
      ),
      style: theme.textTheme.bodyLarge,
    );
  }
}
