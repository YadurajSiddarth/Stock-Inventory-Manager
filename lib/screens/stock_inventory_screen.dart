import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/stock_item.dart';
import '../services/stock_service.dart';
import '../utils/stock_filter.dart';

const _navy = Color(0xFF172B2A);
const _purple = Color(0xFF147D70);
const _blue = Color(0xFF397D78);
const _gold = Color(0xFFB6D96C);
const _page = Color(0xFFF4F7F5);

class StockInventoryScreen extends StatefulWidget {
  const StockInventoryScreen({super.key});

  @override
  State<StockInventoryScreen> createState() => _StockInventoryScreenState();
}

class _StockInventoryScreenState extends State<StockInventoryScreen> {
  final StockService _service = StockService();
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _page,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            _DashboardScreen(
              service: _service,
              onNavigate: (i) => setState(() => _index = i),
            ),
            _AddItemScreen(
              service: _service,
              onSaved: () => setState(() => _index = 2),
            ),
            _RecordsScreen(service: _service),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 74,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDDECE5),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_box_outlined),
            selectedIcon: Icon(Icons.add_box),
            label: 'Add Item',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}

// DASHBOARD

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen({required this.service, required this.onNavigate});
  final StockService service;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StockItem>>(
      stream: service.watchStockItems(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <StockItem>[];
        final units = items.fold<int>(0, (sum, item) => sum + item.quantity);
        final low = items.where((item) => item.isLowStock).toList()
          ..sort((a, b) => a.quantity.compareTo(b.quantity));
        final value = items.fold<double>(
          0,
          (sum, item) => sum + item.quantity * item.unitPrice,
        );

        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HeroBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (snapshot.hasError)
                    const _MessagePanel(
                      icon: Icons.cloud_off,
                      title: 'Could not load dashboard',
                      message:
                          'Check your Firestore connection and permissions.',
                    )
                  else if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.all(36),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 850 ? 4 : 2;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: constraints.maxWidth < 380
                              ? 1.35
                              : 1.55,
                          children: [
                            _MetricCard(
                              title: 'Stock items',
                              value: '${items.length}',
                              icon: Icons.inventory_2,
                              color: _purple,
                            ),
                            _MetricCard(
                              title: 'Units on hand',
                              value: '$units',
                              icon: Icons.trending_up,
                              color: _blue,
                            ),
                            _MetricCard(
                              title: 'Low stock',
                              value: '${low.length}',
                              icon: Icons.warning_amber,
                              color: const Color(0xFFE34D5B),
                            ),
                            _MetricCard(
                              title: 'Stock value',
                              value: 'RM ${value.toStringAsFixed(2)}',
                              icon: Icons.account_balance_wallet,
                              color: _gold,
                              compact: true,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final buttons = [
                          _ActionButton(
                            label: 'Add Item',
                            icon: Icons.add_circle_outline,
                            color: _purple,
                            onTap: () => onNavigate(1),
                          ),
                          _ActionButton(
                            label: 'Search Stock',
                            icon: Icons.search,
                            color: _gold,
                            onTap: () => onNavigate(2),
                          ),
                        ];
                        if (constraints.maxWidth < 480) {
                          return Column(
                            children: [
                              buttons[0],
                              const SizedBox(height: 10),
                              buttons[1],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: buttons[0]),
                            const SizedBox(width: 12),
                            Expanded(child: buttons[1]),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _CategoryPanel(items: items),
                    const SizedBox(height: 18),
                    _ReorderPanel(items: low),
                    const SizedBox(height: 28),
                    const _AppFooter(),
                  ],
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: const BoxDecoration(
        color: _navy,
        border: Border(bottom: BorderSide(color: Color(0xFF31504B), width: 1)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _purple,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.spa_outlined,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'StockNest',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.5,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'INVENTORY WORKSPACE',
                    style: TextStyle(
                      color: Color(0xFFB7CBC5),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF25433D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Color(0xFFB6D96C)),
                  SizedBox(width: 6),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });
  final String title, value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Color(0xFF9AA9A3)),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: _navy,
                fontSize: compact ? 19 : 29,
                fontWeight: FontWeight.w800,
                letterSpacing: -.7,
              ),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF73837D),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    ),
  );
}

class _CategoryPanel extends StatelessWidget {
  const _CategoryPanel({required this.items});
  final List<StockItem> items;
  static const colors = [
    Color(0xFF4388F5),
    Color(0xFF9857F5),
    Color(0xFFFFA21A),
    Color(0xFF10B981),
  ];
  static const icons = [
    Icons.bolt,
    Icons.edit_note,
    Icons.handyman,
    Icons.shopping_cart,
  ];

  @override
  Widget build(BuildContext context) {
    final totals = stockCategories
        .map(
          (c) => items
              .where((i) => i.category == c)
              .fold<int>(0, (s, i) => s + i.quantity),
        )
        .toList();
    final counts = stockCategories
        .map((c) => items.where((i) => i.category == c).length)
        .toList();
    final maxValue = totals.fold<int>(0, (a, b) => a > b ? a : b);

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelTitle(icon: Icons.bar_chart, title: 'Stock by category'),
          const SizedBox(height: 18),
          for (var i = 0; i < stockCategories.length; i++) ...[
            Row(
              children: [
                Icon(icons[i], color: colors[i], size: 22),
                const SizedBox(width: 8),
                SizedBox(
                  width: 92,
                  child: Text(
                    stockCategories[i],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: LinearProgressIndicator(
                      value: maxValue == 0 ? 0 : totals[i] / maxValue,
                      minHeight: 12,
                      backgroundColor: const Color(0xFFE7E8F0),
                      valueColor: AlwaysStoppedAnimation(colors[i]),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 75,
                  child: Text(
                    '${totals[i]} units · ${counts[i]}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF737B9B),
                    ),
                  ),
                ),
              ],
            ),
            if (i != stockCategories.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _ReorderPanel extends StatelessWidget {
  const _ReorderPanel({required this.items});
  final List<StockItem> items;

  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _PanelTitle(
                icon: Icons.notifications_active,
                title: 'Needs reorder',
              ),
            ),
            _Pill(
              '${items.length} items',
              color: const Color(0xFFFFE7E9),
              textColor: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (items.isEmpty)
          const Text(
            'No items currently need reordering.',
            style: TextStyle(color: Colors.grey),
          )
        else
          for (final item in items.take(8)) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    _categoryIcon(item.category),
                    color: _categoryColor(item.category),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${item.itemName} · ${item.sku}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${item.quantity} / ${item.reorderLevel}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    ),
  );
}

// ADD ITEM

class _AddItemScreen extends StatefulWidget {
  const _AddItemScreen({required this.service, required this.onSaved});
  final StockService service;
  final VoidCallback onSaved;

  @override
  State<_AddItemScreen> createState() => _AddItemScreenState();
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.copyWith(text: newValue.text.toUpperCase());
}

class _AddItemScreenState extends State<_AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sku = TextEditingController();
  final _name = TextEditingController();
  final _quantity = TextEditingController();
  final _price = TextEditingController();
  final _reorder = TextEditingController();
  String? _category;
  bool _saving = false;

  @override
  void dispose() {
    _sku.dispose();
    _name.dispose();
    _quantity.dispose();
    _price.dispose();
    _reorder.dispose();
    super.dispose();
  }

  String? _validateSku(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter an SKU.';
    if (!RegExp(r'^STK-\d{3}$').hasMatch(v))
      return 'Use STK- followed by exactly three digits.';
    return null;
  }

  String? _validateName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter an item name.';
    if (v.length < 3) return 'Item name must contain at least 3 characters.';
    return null;
  }

  String? _validateInteger(String? value, String label) {
    final v = value?.trim() ?? '';
    final n = int.tryParse(v);
    if (v.isEmpty) return '$label is required.';
    if (n == null || n < 0)
      return '$label must be a whole number of at least zero.';
    return null;
  }

  String? _validatePrice(String? value) {
    final v = value?.trim() ?? '';
    final n = double.tryParse(v);
    if (v.isEmpty) return 'Enter the unit price.';
    if (n == null || !n.isFinite || n <= 0)
      return 'Price must be greater than RM 0.00.';
    return null;
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await widget.service.addStockItem(
        sku: _sku.text.trim(),
        itemName: _name.text.trim(),
        category: _category!,
        quantity: int.parse(_quantity.text.trim()),
        unitPrice: double.parse(_price.text.trim()),
        reorderLevel: int.parse(_reorder.text.trim()),
      );
      if (!mounted) return;
      _sku.clear();
      _name.clear();
      _quantity.clear();
      _price.clear();
      _reorder.clear();
      setState(() {
        _category = null;
        _saving = false;
      });
      _showMessage('Stock item saved successfully.');
      widget.onSaved();
    } on TimeoutException {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        'No confirmation from Firestore. Your form data is retained.',
        error: true,
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage(
        'Could not save item (${e.code}). Check Firestore access.',
        error: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Could not save item: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              const _SectionBanner(title: 'Add Stock Item'),
              const SizedBox(height: 16),
              _LivePreview(
                name: _name.text,
                sku: _sku.text,
                category: _category,
                quantity: int.tryParse(_quantity.text) ?? 0,
                reorder: int.tryParse(_reorder.text) ?? 0,
                price: double.tryParse(_price.text) ?? 0,
              ),
              const SizedBox(height: 16),
              _Panel(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _PanelTitle(
                        icon: Icons.edit_note,
                        title: 'Item details',
                      ),
                      const SizedBox(height: 18),
                      _buildField(
                        _sku,
                        'SKU',
                        Icons.qr_code_2,
                        validator: _validateSku,
                        hint: 'STK-101',
                        formatters: [_UpperCaseFormatter()],
                      ),
                      const SizedBox(height: 13),
                      _buildField(
                        _name,
                        'Item name',
                        Icons.inventory_2_outlined,
                        validator: _validateName,
                        hint: 'USB C Cable',
                        capitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 13),
                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: stockCategories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: _saving
                            ? null
                            : (v) => setState(() => _category = v),
                        validator: (v) =>
                            v == null ? 'Select a category.' : null,
                      ),
                      const SizedBox(height: 13),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final quantityField = _buildField(
                            _quantity,
                            'Quantity',
                            Icons.numbers,
                            validator: (v) => _validateInteger(v, 'Quantity'),
                            keyboard: TextInputType.number,
                          );
                          final reorderField = _buildField(
                            _reorder,
                            'Reorder level',
                            Icons.notifications_active_outlined,
                            validator: (v) =>
                                _validateInteger(v, 'Reorder level'),
                            keyboard: TextInputType.number,
                          );
                          if (constraints.maxWidth < 440) {
                            return Column(
                              children: [
                                quantityField,
                                const SizedBox(height: 13),
                                reorderField,
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(child: quantityField),
                              const SizedBox(width: 12),
                              Expanded(child: reorderField),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 13),
                      _buildField(
                        _price,
                        'Unit price (RM)',
                        Icons.payments_outlined,
                        validator: _validatePrice,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        hint: '19.90',
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        height: 54,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.cloud_upload_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save Item'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'All fields are required · Saved to Firestore › stockItems',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF7B829E),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    required String? Function(String?) validator,
    TextInputType? keyboard,
    String? hint,
    List<TextInputFormatter>? formatters,
    TextCapitalization capitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_saving,
      keyboardType: keyboard,
      inputFormatters: formatters,
      textCapitalization: capitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
      onChanged: (_) => setState(() {}),
    );
  }
}

class _SectionBanner extends StatelessWidget {
  const _SectionBanner({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
    decoration: const BoxDecoration(
      color: _navy,
      border: Border(bottom: BorderSide(color: Color(0xFF31504B))),
    ),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 30,
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        const Icon(Icons.eco_outlined, color: Color(0xFFB7CBC5)),
      ],
    ),
  );
}

class _LivePreview extends StatelessWidget {
  const _LivePreview({
    required this.name,
    required this.sku,
    required this.category,
    required this.quantity,
    required this.reorder,
    required this.price,
  });
  final String name, sku;
  final String? category;
  final int quantity, reorder;
  final double price;

  @override
  Widget build(BuildContext context) {
    final isLow = quantity <= reorder;
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE PREVIEW',
            style: TextStyle(
              color: _gold,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFEEF0F8),
                child: Icon(Icons.inventory_2, color: _navy),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? 'Your item name' : name,
                      style: const TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 5,
                      children: [
                        _Pill(sku.isEmpty ? 'STK-000' : sku),
                        _Pill(category ?? 'Category'),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _Pill(
                    isLow ? 'LOW STOCK' : 'OK',
                    color: isLow
                        ? const Color(0xFFFFE7E9)
                        : const Color(0xFFE3F6EA),
                    textColor: isLow ? Colors.red : Colors.green,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Quantity: $quantity     Reorder at: $reorder',
            style: const TextStyle(color: Color(0xFF737B9B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// RECORDS

class _RecordsScreen extends StatefulWidget {
  const _RecordsScreen({required this.service});
  final StockService service;

  @override
  State<_RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<_RecordsScreen> {
  final _search = TextEditingController();
  String _category = 'All';
  bool _lowOnly = false;
  QuantitySort _sort = QuantitySort.newest;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _search.clear();
    setState(() {
      _category = 'All';
      _lowOnly = false;
      _sort = QuantitySort.newest;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SectionBanner(title: 'All Records'),
        Expanded(
          child: StreamBuilder<List<StockItem>>(
            stream: widget.service.watchStockItems(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _MessagePanel(
                  icon: Icons.cloud_off,
                  title: 'Could not load records',
                  message: 'Check your connection and Firestore permissions.',
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snapshot.data ?? const <StockItem>[];
              final visible = filterAndSortStock(
                all,
                keyword: _search.text,
                category: _category,
                lowStockOnly: _lowOnly,
                sort: _sort,
              );

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(15, 13, 15, 8),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Search by item name or SKU',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _FilterChip(
                                label: 'All',
                                selected: _category == 'All',
                                onTap: () => setState(() => _category = 'All'),
                              ),
                              for (final c in stockCategories)
                                _FilterChip(
                                  label: c,
                                  selected: _category == c,
                                  onTap: () => setState(() => _category = c),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 7,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilterChip(
                              label: const Text('Low stock only'),
                              selected: _lowOnly,
                              onSelected: (v) => setState(() => _lowOnly = v),
                            ),
                            DropdownButton<QuantitySort>(
                              value: _sort,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(
                                  value: QuantitySort.newest,
                                  child: Text('Newest first'),
                                ),
                                DropdownMenuItem(
                                  value: QuantitySort.ascending,
                                  child: Text('Quantity ↑'),
                                ),
                                DropdownMenuItem(
                                  value: QuantitySort.descending,
                                  child: Text('Quantity ↓'),
                                ),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _sort = v);
                              },
                            ),
                            TextButton.icon(
                              onPressed: _clearFilters,
                              icon: const Icon(Icons.filter_alt_off),
                              label: const Text('Clear'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${visible.length} of ${all.length}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _navy,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${all.where((i) => i.isLowStock).length} low stock',
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: visible.isEmpty
                        ? _MessagePanel(
                            icon: Icons.inventory_2_outlined,
                            title: all.isEmpty
                                ? 'No stock items yet'
                                : 'No matching items',
                            message: all.isEmpty
                                ? 'Add your first stock item.'
                                : 'Try another keyword or clear the filters.',
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
                            itemCount: visible.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 9),
                            itemBuilder: (context, index) =>
                                _RecordCard(item: visible[index]),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// SHARED COMPONENTS

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(right: 5),
    child: ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE7E9FF),
    ),
  );
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.item});
  final StockItem item;

  @override
  Widget build(BuildContext context) {
    final low = item.isLowStock;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border(
          left: BorderSide(
            color: low ? Colors.redAccent : _categoryColor(item.category),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _categoryColor(item.category)
                    .withValues(alpha: .12),
                child: Icon(
                  _categoryIcon(item.category),
                  color: _categoryColor(item.category),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.itemName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _navy,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                'RM ${item.unitPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            children: [
              _Pill(item.sku),
              _Pill(item.category),
              _Pill(
                low ? 'LOW STOCK' : 'OK',
                color: low ? const Color(0xFFFFE7E9) : const Color(0xFFE3F6EA),
                textColor: low ? Colors.red : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                'Qty ${item.quantity}',
                style: const TextStyle(color: Color(0xFF69718E)),
              ),
              const SizedBox(width: 13),
              Text(
                'Reorder at ${item.reorderLevel}',
                style: const TextStyle(color: Color(0xFF69718E)),
              ),
              const Spacer(),
              if (item.createdAt != null)
                Text(
                  '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year}',
                  style: const TextStyle(
                    color: Color(0xFF9298AD),
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE3EBE7)),
    ),
    child: child,
  );
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: _gold, size: 22),
      const SizedBox(width: 9),
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: _navy,
        ),
      ),
    ],
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, {this.color, this.textColor});
  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color ?? const Color(0xFFEEF0F8),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: textColor ?? _navy,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title, message;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 46, color: const Color(0xFF9298AD)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF737B9B)),
          ),
        ],
      ),
    ),
  );
}

IconData _categoryIcon(String category) {
  switch (category) {
    case 'Electronics':
      return Icons.bolt;
    case 'Stationery':
      return Icons.edit_note;
    case 'Hardware':
      return Icons.handyman;
    case 'Grocery':
      return Icons.shopping_cart;
    default:
      return Icons.inventory_2;
  }
}

Color _categoryColor(String category) {
  switch (category) {
    case 'Electronics':
      return const Color(0xFF4388F5);
    case 'Stationery':
      return const Color(0xFF9857F5);
    case 'Hardware':
      return const Color(0xFFFFA21A);
    case 'Grocery':
      return const Color(0xFF10B981);
    default:
      return _purple;
  }
}

class _AppFooter extends StatelessWidget {
  const _AppFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: const BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco_outlined, color: _gold, size: 22),
              SizedBox(width: 8),
              Text(
                'StockNest',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Smarter inventory management.',
            style: TextStyle(color: Color(0xFFB7CBC5), fontSize: 13),
          ),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFF31504B)),
          const SizedBox(height: 10),
          const Text(
            'By Yaduraj Siddarth · Stock Inventory Manager',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFB7CBC5), fontSize: 11),
          ),
          const SizedBox(height: 5),
          const Text(
            '© 2026 StockNest. All rights reserved.',
            style: TextStyle(color: Color(0xFFB7CBC5), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
