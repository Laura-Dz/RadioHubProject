import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/transaction_model.dart';
import '../../../core/constants/app_colors.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  TransactionType? _typeFilter;
  TransactionStatus? _statusFilter;
  String _sort = 'date_desc';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();

    // Only the radio admin's own transactions: subscription + announcement (base only).
    final visible = vm.transactions
        .where((t) =>
            t.type == TransactionType.subscription ||
            (t.type == TransactionType.announcement &&
                t.status == TransactionStatus.released))
        .toList();

    final filtered = _filterAndSort(visible);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              tooltip: 'Configure Payment Accounts',
              icon: const Icon(Icons.account_balance_wallet_outlined),
              onPressed: () => _openPaymentAccounts(context, vm),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Summary strip
            Row(
              children: [
                Expanded(child: _summary(
                  'Total transactions',
                  visible.length.toString(),
                  Icons.receipt_long,
                  AppColors.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _summary(
                  'Expenses (subscription)',
                  '${_sumWhere(visible, TransactionType.subscription).toStringAsFixed(0)} XAF',
                  Icons.arrow_upward,
                  AppColors.error,
                )),
                const SizedBox(width: 12),
                Expanded(child: _summary(
                  'Revenue (announcement)',
                  '${_sumWhere(visible, TransactionType.announcement).toStringAsFixed(0)} XAF',
                  Icons.arrow_downward,
                  AppColors.success,
                )),
              ],
            ),
            const SizedBox(height: 20),

            // Toolbar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search by method, reference, or other party...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _typeDropdown(),
                const SizedBox(width: 8),
                _statusDropdown(),
                const SizedBox(width: 8),
                _sortDropdown(),
              ],
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? _empty()
                  : Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: AppColors.divider),
                        itemBuilder: (_, i) => _row(filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- SUMMARY ----------------

  Widget _summary(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _sumWhere(List<RadioTransaction> list, TransactionType type) {
    return list
        .where((t) => t.type == type)
        .fold<double>(0, (s, t) => s + (type == TransactionType.subscription
            ? t.totalAmount
            : t.baseAmount));
  }

  // ---------------- FILTERS ----------------

  Widget _typeDropdown() {
    return SizedBox(
      width: 175,
      child: DropdownButtonFormField<TransactionType?>(
        value: _typeFilter,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Type',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('All types', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: TransactionType.subscription, child: Text('Subscription', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: TransactionType.announcement, child: Text('Announcement', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _typeFilter = v),
      ),
    );
  }

  Widget _statusDropdown() {
    return SizedBox(
      width: 175,
      child: DropdownButtonFormField<TransactionStatus?>(
        value: _statusFilter,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Status',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        items: const [
          DropdownMenuItem(value: null, child: Text('All statuses', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: TransactionStatus.released, child: Text('Released', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: TransactionStatus.pending, child: Text('Pending', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: TransactionStatus.failed, child: Text('Failed', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _statusFilter = v),
      ),
    );
  }

  Widget _sortDropdown() {
    return SizedBox(
      width: 175,
      child: DropdownButtonFormField<String>(
        value: _sort,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Sort',
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        items: const [
          DropdownMenuItem(value: 'date_desc', child: Text('Newest first', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: 'date_asc', child: Text('Oldest first', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: 'amount_desc', child: Text('Highest amount', overflow: TextOverflow.ellipsis)),
          DropdownMenuItem(value: 'amount_asc', child: Text('Lowest amount', overflow: TextOverflow.ellipsis)),
        ],
        onChanged: (v) => setState(() => _sort = v ?? 'date_desc'),
      ),
    );
  }

  List<RadioTransaction> _filterAndSort(List<RadioTransaction> src) {
    final s = _searchCtrl.text.toLowerCase();
    final list = src.where((t) {
      final matchSearch = s.isEmpty ||
          (t.paymentMethod ?? '').toLowerCase().contains(s) ||
          (t.escrowReference ?? '').toLowerCase().contains(s) ||
          (t.initiatorName ?? '').toLowerCase().contains(s);
      final matchType = _typeFilter == null || t.type == _typeFilter;
      final matchStatus = _statusFilter == null || t.status == _statusFilter;
      return matchSearch && matchType && matchStatus;
    }).toList();

    switch (_sort) {
      case 'date_asc':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'amount_desc':
        list.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'amount_asc':
        list.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      default:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return list;
  }

  // ---------------- ROW ----------------

  Widget _row(RadioTransaction t) => _Row(t: t);

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 72, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No transactions found',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text('Adjust your filters or wait for new activity.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  void _openPaymentAccounts(BuildContext context, RadioAdminViewModel vm) {
    vm.loadPaymentAccounts();
    showDialog(
      context: context,
      builder: (_) => _PaymentAccountsModal(vm: vm),
    );
  }
}

// ============================================================
// ROW WIDGET
// ============================================================

class _Row extends StatefulWidget {
  final RadioTransaction t;
  const _Row({required this.t});

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _expanded = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isExpense = t.type == TransactionType.subscription;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _hovered ? AppColors.hover : Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (isExpense ? AppColors.error : AppColors.success).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isExpense ? Icons.card_membership : Icons.campaign_outlined,
                        size: 18,
                        color: isExpense ? AppColors.error : AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isExpense ? 'Subscription' : 'Announcement payout',
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('d MMM yyyy • HH:mm').format(t.createdAt),
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _cell('Payment', t.paymentMethod ?? '—')),
                    Expanded(
                      child: _cell(
                        isExpense ? 'Charged' : 'Received',
                        '${(isExpense ? t.totalAmount : t.baseAmount).toStringAsFixed(0)} ${t.currency}',
                        bold: true,
                        color: isExpense ? AppColors.error : AppColors.success,
                      ),
                    ),
                    _statusBadge(t.status),
                    const SizedBox(width: 8),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 180),
                  crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: const SizedBox.shrink(),
                  secondChild: _details(t),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String label, String value, {bool bold = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(TransactionStatus s) {
    final (color, label) = switch (s) {
      TransactionStatus.released => (AppColors.success, 'Completed'),
      TransactionStatus.pending => (AppColors.warning, 'Pending'),
      TransactionStatus.failed => (AppColors.error, 'Failed'),
      TransactionStatus.inEscrow => (AppColors.escrowHeld, 'Processing'),
      TransactionStatus.refunded => (AppColors.escrowRefunded, 'Refunded'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _details(RadioTransaction t) {
    return Container(
      margin: const EdgeInsets.only(top: 12, left: 52),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('Transaction ID', t.id),
          if (t.subscriptionId != null) _detailRow('Subscription ID', t.subscriptionId!),
          if (t.announcementId != null) _detailRow('Announcement ID', t.announcementId!),
          _detailRow('Created', DateFormat('d MMM yyyy HH:mm').format(t.createdAt)),
          if (t.releasedAt != null)
            _detailRow('Completed', DateFormat('d MMM yyyy HH:mm').format(t.releasedAt!)),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 150,
              child: Text(label,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500, fontFamily: 'monospace')),
            ),
          ],
        ),
      );
}

// ============================================================
// PAYMENT ACCOUNTS MODAL
// ============================================================

class _PaymentAccountsModal extends StatefulWidget {
  final RadioAdminViewModel vm;
  const _PaymentAccountsModal({required this.vm});

  @override
  State<_PaymentAccountsModal> createState() => _PaymentAccountsModalState();
}

class _PaymentAccountsModalState extends State<_PaymentAccountsModal> {
  late TextEditingController _omCtrl;
  late TextEditingController _momoCtrl;
  late TextEditingController _bankCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final accounts = widget.vm.paymentAccounts;
    _omCtrl = TextEditingController(text: accounts['om'] ?? '');
    _momoCtrl = TextEditingController(text: accounts['momo'] ?? '');
    _bankCtrl = TextEditingController(text: accounts['bank'] ?? '');
  }

  @override
  void dispose() {
    _omCtrl.dispose();
    _momoCtrl.dispose();
    _bankCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Account Numbers',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Default accounts for each payment method',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _accountField(
                controller: _omCtrl,
                label: 'Orange Money (OM)',
                hint: '2376XXXXXXXX',
                icon: Icons.sim_card_outlined,
                iconColor: const Color(0xFFFF6600),
              ),
              const SizedBox(height: 14),
              _accountField(
                controller: _momoCtrl,
                label: 'MTN Mobile Money (MoMo)',
                hint: '2376XXXXXXXX',
                icon: Icons.sim_card_outlined,
                iconColor: const Color(0xFFFFCC00),
              ),
              const SizedBox(height: 14),
              _accountField(
                controller: _bankCtrl,
                label: 'Card / Bank Account Number',
                hint: 'IBAN or account number',
                icon: Icons.credit_card_outlined,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: AppColors.info),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'These are the default numbers used for outgoing payments. You can still change the number at the time of each payment.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined, size: 16),
                    label: Text(_saving ? 'Saving...' : 'Save Accounts'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accountField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: iconColor, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.vm.savePaymentAccounts({
        'om': _omCtrl.text.trim(),
        'momo': _momoCtrl.text.trim(),
        'bank': _bankCtrl.text.trim(),
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment accounts saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: \$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
