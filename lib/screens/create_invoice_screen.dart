import 'package:flutter/material.dart';
import '../core/guards/subscription_action_guard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../core/formatters.dart';
import '../models/business_profile.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/product.dart';
import '../providers/app_providers.dart';
import 'widgets/app_card.dart';

class CreateInvoiceScreen extends ConsumerStatefulWidget {
  final Invoice? invoice;
  final String? preselectedCustomerId;

  const CreateInvoiceScreen({super.key, this.invoice, this.preselectedCustomerId});

  @override
  ConsumerState<CreateInvoiceScreen> createState() => _CreateInvoiceState();
}

class _CreateInvoiceState extends ConsumerState<CreateInvoiceScreen> {
  Customer? customer;
  late DateTime issue;
  late DateTime due;
  late bool includeVat;
  late double vatRate;
  final notes = TextEditingController();
  final discount = TextEditingController();
  final List<InvoiceLine> lines = [];
  bool saving = false;
  bool configInitialized = false;

  bool get editing => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final invoice = widget.invoice;
    issue = invoice?.issueDate ?? DateTime.now();
    due = invoice?.dueDate ?? DateTime.now().add(const Duration(days: 14));
    includeVat = false;
    vatRate = 16;
    if (invoice != null) {
      lines.addAll(invoice.lines);
      notes.text = invoice.notes;
      discount.text = invoice.discount.toStringAsFixed(2);
    } else {
      discount.text = '0';
    }
  }

  @override
  void dispose() {
    notes.dispose();
    discount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final business = ref.watch(businessProvider).valueOrNull;
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final products = ref.watch(productsProvider).valueOrNull ?? [];
    final selectedCustomer = _resolveCustomer(customers);
    if (!configInitialized && business != null) {
      if (widget.invoice != null) {
        includeVat = widget.invoice!.vatEnabled;
        vatRate = widget.invoice!.vatRate;
      } else {
        includeVat = business.vatRegistered;
        vatRate = business.vatRate;
        due = issue.add(Duration(days: business.defaultDueDays));
      }
      configInitialized = true;
    }
    final effectiveVatRate = vatRate;
    final subtotal = lines.fold(0.0, (sum, line) => sum + line.total);
    final taxable = lines.where((line) => line.taxable).fold(0.0, (sum, line) => sum + line.total);
    final discountValue = (double.tryParse(discount.text) ?? 0).clamp(0, subtotal).toDouble();
    final tax = includeVat ? taxable * effectiveVatRate / 100 : 0.0;
    final total = subtotal - discountValue + tax;

    if (customer == null && selectedCustomer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && customer == null) setState(() => customer = selectedCustomer);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Edit ${widget.invoice!.number}' : 'Create invoice'),
        actions: [
          if (editing)
            IconButton(
              tooltip: 'Duplicate',
              onPressed: saving ? null : () => _duplicate(business),
              icon: const Icon(Icons.copy_outlined),
            ),
        ],
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 120),
          children: [
            _section('Invoice details', Column(children: [
              _customerPicker(customers),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(child: _dateField('Issue date', issue, (value) => setState(() => issue = value))),
                const SizedBox(width: 10),
                Expanded(child: _dateField('Due date', due, (value) => setState(() => due = value))),
              ]),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: [
                    _duePreset('Today', 0),
                    _duePreset('7 days', 7),
                    _duePreset('14 days', 14),
                    _duePreset('30 days', 30),
                  ],
                ),
              ),
            ])),
            const SizedBox(height: 12),
            _section('Items', Column(children: [
              if (lines.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text('Add products, services or custom line items.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              ...lines.asMap().entries.map((entry) => _lineTile(entry.key, entry.value)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _addCustomLine, icon: const Icon(Icons.edit_note), label: const Text('Custom item'))),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(onPressed: () => _addCatalog(products), icon: const Icon(Icons.inventory_2_outlined), label: const Text('Catalog'))),
              ]),
            ])),
            const SizedBox(height: 12),
            _section('Totals & tax', Column(children: [
              _summary('Subtotal', subtotal),
              TextField(
                controller: discount,
                onChanged: (_) => setState(() {}),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Discount', prefixText: 'KSh '),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Charge VAT'),
                subtitle: Text(includeVat ? 'VAT applied to taxable items' : 'No VAT on this invoice'),
                value: includeVat,
                onChanged: (value) => setState(() => includeVat = value),
              ),
              if (includeVat)
                TextFormField(
                  initialValue: vatRate.toStringAsFixed(0),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'VAT rate (%)'),
                  onChanged: (value) => setState(() => vatRate = double.tryParse(value) ?? vatRate),
                ),
              if (includeVat) _summary('VAT', tax),
              const Divider(height: 26),
              _summary('Total', total, bold: true),
            ])),
            const SizedBox(height: 12),
            _section('Notes', TextField(controller: notes, maxLines: 4, decoration: const InputDecoration(hintText: 'Payment terms, thank-you note, delivery notes...'))),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
          child: Row(children: [
            Expanded(child: OutlinedButton(onPressed: saving ? null : () => _save(business, draft: true), child: const Text('Save draft'))),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: FilledButton.icon(onPressed: saving ? null : () => _save(business, draft: false), icon: Icon(editing ? Icons.save_rounded : Icons.send_rounded), label: Text(editing ? 'Save changes' : 'Create & send'))),
          ]),
        ),
      ),
    );
  }

  Customer? _resolveCustomer(List<Customer> customers) {
    if (customer != null) return customer;
    final id = widget.invoice?.customerId ?? widget.preselectedCustomerId;
    if (id == null) return null;
    for (final item in customers) {
      if (item.id == id) return item;
    }
    return null;
  }

  Widget _customerPicker(List<Customer> customers) => Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: customer?.id ?? widget.invoice?.customerId ?? widget.preselectedCustomerId,
            decoration: const InputDecoration(labelText: 'Customer', prefixIcon: Icon(Icons.person_outline)),
            hint: const Text('Select customer'),
            items: customers.map((item) => DropdownMenuItem(value: item.id, child: Text(item.name, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (id) => setState(() => customer = id == null ? null : customers.firstWhere((item) => item.id == id)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(tooltip: 'Quick add customer', onPressed: _quickAddCustomer, icon: const Icon(Icons.person_add_alt_1)),
      ]);

  Widget _section(String title, Widget child) => AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 14), child]));

  Widget _dateField(String label, DateTime value, ValueChanged<DateTime> onChanged) => InkWell(
        onTap: () async {
          final selected = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2100), initialDate: value);
          if (selected != null) onChanged(selected);
        },
        child: InputDecorator(decoration: InputDecoration(labelText: label), child: Text(shortDate.format(value))),
      );

  Widget _duePreset(String label, int days) => ActionChip(label: Text(label), onPressed: () => setState(() => due = DateTime(issue.year, issue.month, issue.day).add(Duration(days: days))));

  Widget _lineTile(int index, InvoiceLine line) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _editLine(index, line),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(line.description, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text('${_quantity(line.quantity)} × ${money.format(line.unitPrice)}${line.taxable ? ' • Taxable' : ''}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))])),
              Text(money.format(line.total), style: const TextStyle(fontWeight: FontWeight.w800)),
              PopupMenuButton<String>(onSelected: (value) { if (value == 'edit') _editLine(index, line); if (value == 'delete') setState(() => lines.removeAt(index)); }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit item')), PopupMenuItem(value: 'delete', child: Text('Remove'))]),
            ]),
          ),
        ),
      );

  String _quantity(double value) => value == value.roundToDouble() ? value.toStringAsFixed(0) : value.toStringAsFixed(2);

  Widget _summary(String label, double value, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w800 : null)), Text(money.format(value), style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600, fontSize: bold ? 19 : null))]));

  Future<void> _quickAddCustomer() async {
    if (!SubscriptionActionGuard.requireWrite(context, ref)) return;
    final result = await showDialog<Customer>(context: context, builder: (_) => _CustomerDialog());
    if (result == null) return;
    await ref.read(customersProvider.notifier).upsert(result);
    if (mounted) setState(() => customer = result);
  }

  Future<void> _addCustomLine() async {
    final result = await showDialog<InvoiceLine>(context: context, builder: (_) => const _LineDialog());
    if (result != null) setState(() => lines.add(result));
  }

  Future<void> _editLine(int index, InvoiceLine line) async {
    final result = await showDialog<InvoiceLine>(context: context, builder: (_) => _LineDialog(initial: line));
    if (result != null) setState(() => lines[index] = result);
  }

  Future<void> _addCatalog(List<ProductItem> products) async {
    if (products.isEmpty) {
      _addCustomLine();
      return;
    }
    final result = await showModalBottomSheet<ProductItem>(context: context, showDragHandle: true, builder: (_) => SafeArea(child: ListView(padding: const EdgeInsets.fromLTRB(18, 4, 18, 24), children: [Text('Catalog', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)), const SizedBox(height: 10), ...products.map((p) => ListTile(contentPadding: EdgeInsets.zero, title: Text(p.name), subtitle: Text('${p.type} • ${money.format(p.price)}'), trailing: const Icon(Icons.add_circle_outline), onTap: () => Navigator.pop(context, p)))])));
    if (result != null) setState(() => lines.add(InvoiceLine(id: const Uuid().v4(), description: result.name, quantity: 1, unitPrice: result.price, taxable: result.taxable)));
  }

  Future<void> _duplicate(BusinessProfile? business) async {
    if (!SubscriptionActionGuard.requireWrite(context, ref)) return;
    final original = widget.invoice;
    if (original == null) return;
    final b = business ?? BusinessProfile(id: 'default', name: 'My Business', businessType: 'Other');
    final copy = original.copyWith(id: const Uuid().v4(), number: '${b.invoicePrefix}-${b.nextInvoiceNumber.toString().padLeft(4, '0')}', payments: const [], status: InvoiceStatus.draft, archived: false);
    await ref.read(invoicesProvider.notifier).upsert(copy);
    await ref.read(businessProvider.notifier).save(b.copyWith(nextInvoiceNumber: b.nextInvoiceNumber + 1));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _save(BusinessProfile? business, {required bool draft}) async {
    if (!SubscriptionActionGuard.requireWrite(context, ref)) return;
    final selected = _resolveCustomer(ref.read(customersProvider).valueOrNull ?? []);
    if (selected == null) return _message('Select a customer first.');
    if (lines.isEmpty) return _message('Add at least one invoice item.');
    final b = business ?? BusinessProfile(id: 'default', name: 'My Business', businessType: 'Other');
    setState(() => saving = true);
    try {
      final original = widget.invoice;
      final number = original?.number ?? '${b.invoicePrefix}-${b.nextInvoiceNumber.toString().padLeft(4, '0')}';
      final saved = Invoice(id: original?.id ?? const Uuid().v4(), businessId: b.id, customerId: selected.id, customerName: selected.name, number: number, issueDate: issue, dueDate: due, lines: List.of(lines), status: draft ? InvoiceStatus.draft : ((original?.amountPaid ?? 0) > 0 ? InvoiceStatus.partiallyPaid : InvoiceStatus.sent), discount: (double.tryParse(discount.text) ?? 0).clamp(0, double.infinity).toDouble(), vatEnabled: includeVat, vatRate: vatRate, payments: original?.payments ?? const [], notes: notes.text.trim(), archived: original?.archived ?? false);
      await ref.read(invoicesProvider.notifier).upsert(saved);
      if (original == null) await ref.read(businessProvider.notifier).save(b.copyWith(nextInvoiceNumber: b.nextInvoiceNumber + 1));
      if (mounted) Navigator.pop(context, saved);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class _LineDialog extends StatefulWidget {
  final InvoiceLine? initial;
  const _LineDialog({this.initial});
  @override State<_LineDialog> createState() => _LineDialogState();
}
class _LineDialogState extends State<_LineDialog> {
  late final TextEditingController description;
  late final TextEditingController quantity;
  late final TextEditingController price;
  late bool taxable;
  @override void initState() { super.initState(); final x=widget.initial; description=TextEditingController(text:x?.description??''); quantity=TextEditingController(text:x?.quantity.toString()??'1'); price=TextEditingController(text:x?.unitPrice.toString()??''); taxable=x?.taxable??false; }
  @override void dispose(){description.dispose();quantity.dispose();price.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AlertDialog(title:Text(widget.initial==null?'Add line item':'Edit line item'),content:SingleChildScrollView(child:Column(children:[TextField(controller:description,decoration:const InputDecoration(labelText:'Description')),const SizedBox(height:10),Row(children:[Expanded(child:TextField(controller:quantity,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Quantity'))),const SizedBox(width:10),Expanded(child:TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Unit price')))]),SwitchListTile.adaptive(contentPadding:EdgeInsets.zero,title:const Text('Taxable'),value:taxable,onChanged:(v)=>setState(()=>taxable=v))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:(){final d=description.text.trim();final q=double.tryParse(quantity.text)??0;final p=double.tryParse(price.text)??0;if(d.isEmpty||q<=0||p<0)return;Navigator.pop(context,InvoiceLine(id:widget.initial?.id??const Uuid().v4(),description:d,quantity:q,unitPrice:p,taxable:taxable));},child:Text(widget.initial==null?'Add':'Save'))]);
}

class _CustomerDialog extends StatefulWidget { @override State<_CustomerDialog> createState()=>_CustomerDialogState(); }
class _CustomerDialogState extends State<_CustomerDialog>{final name=TextEditingController();final phone=TextEditingController();final email=TextEditingController();@override void dispose(){name.dispose();phone.dispose();email.dispose();super.dispose();}@override Widget build(BuildContext context)=>AlertDialog(title:const Text('Quick add customer'),content:SingleChildScrollView(child:Column(children:[TextField(controller:name,decoration:const InputDecoration(labelText:'Customer name')),const SizedBox(height:10),TextField(controller:phone,keyboardType:TextInputType.phone,decoration:const InputDecoration(labelText:'Phone')),const SizedBox(height:10),TextField(controller:email,keyboardType:TextInputType.emailAddress,decoration:const InputDecoration(labelText:'Email'))])),actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel')),FilledButton(onPressed:(){if(name.text.trim().isEmpty)return;Navigator.pop(context,Customer(id:const Uuid().v4(),name:name.text.trim(),phone:phone.text.trim(),email:email.text.trim()));},child:const Text('Add'))]);}
