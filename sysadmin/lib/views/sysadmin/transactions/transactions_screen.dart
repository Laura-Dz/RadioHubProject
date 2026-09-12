import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/sysadmin/transaction_model.dart' as sys_tx;
import '../../../view_models/sysadmin_view_model.dart';
import '../dashboard/widgets/stats_card.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _paymentMethodFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SysAdminViewModel>();
    final currencyFormatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    final allTransactions = viewModel.transactions;
    final subCount = allTransactions.where((t) => !t.isAnnouncement).length;
    final subRevenue = allTransactions
        .where((t) => !t.isAnnouncement && (t.status == sys_tx.TransactionStatus.paid || t.status == sys_tx.TransactionStatus.validated))
        .fold<double>(0.0, (sum, t) => sum + t.amount);

    // Apply search and filters
    final searchQuery = _searchController.text.trim().toLowerCase();
    final filteredTransactions = allTransactions.where((tx) {
      // Search query
      if (searchQuery.isNotEmpty) {
        final matchesId = tx.id.toLowerCase().contains(searchQuery);
        final matchesRadio = tx.radioName.toLowerCase().contains(searchQuery);
        final matchesInitiator = (tx.initiatorName ?? '').toLowerCase().contains(searchQuery) ||
            (tx.initiatorEmail ?? '').toLowerCase().contains(searchQuery);
        final matchesMethod = (tx.paymentMethod ?? '').toLowerCase().contains(searchQuery);
        if (!matchesId && !matchesRadio && !matchesInitiator && !matchesMethod) {
          return false;
        }
      }

      // Payment method filter
      if (_paymentMethodFilter != 'all') {
        if ((tx.paymentMethod ?? '').toLowerCase() != _paymentMethodFilter.toLowerCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.surface,
            elevation: 0,
            floating: true,
            title: const Row(
              children: [
                Icon(Icons.payments_rounded, color: AppColors.primaryLight, size: 22),
                SizedBox(width: 10),
                Text(
                  'TRANSACTIONS & PAYMENTS MONITORING',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
                tooltip: 'Refresh Transactions',
                onPressed: viewModel.refreshData,
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. STATS CARDS ROW
                Row(
                  children: [
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Subscriptions Revenue',
                        value: currencyFormatter.format(subRevenue),
                        icon: Icons.credit_card_rounded,
                        change: '$subCount station subscriptions',
                        isPositive: true,
                        color: AppColors.info,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: StatsCard(
                        title: 'Total Platform Revenue',
                        value: NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(viewModel.totalRevenue),
                        icon: Icons.account_balance_wallet_rounded,
                        change: '${allTransactions.where((t) => !t.isAnnouncement).length} total operations',
                        isPositive: true,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: StatsCard(
                        title: 'Supported Gateways',
                        value: 'MoMo / OM / Ecobank',
                        icon: Icons.phone_android_rounded,
                        change: 'Mobile & Banking',
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 2. SEARCH AND FILTERS BAR
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      // Search field
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search by initiator, receiver radio, payment method, or ID...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.textSecondary, size: 16),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {});
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Type filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.surface,
                            value: viewModel.transactionTypeFilter,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Types')),
                              DropdownMenuItem(value: 'subscription', child: Text('💳 Subscriptions')),
                            ],
                            onChanged: (val) {
                              if (val != null) viewModel.setTransactionFilters(type: val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Payment Method filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.surface,
                            value: _paymentMethodFilter,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Gateways')),
                              DropdownMenuItem(value: 'momo', child: Text('🟡 MoMo')),
                              DropdownMenuItem(value: 'om', child: Text('🟠 Orange Money')),
                              DropdownMenuItem(value: 'ecobank', child: Text('🔵 Ecobank')),
                              DropdownMenuItem(value: 'credit card', child: Text('💳 Card')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _paymentMethodFilter = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Status filter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: AppColors.surface,
                            value: viewModel.transactionStatusFilter,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                              DropdownMenuItem(value: 'paid', child: Text('✅ Paid')),
                              DropdownMenuItem(value: 'validated', child: Text('📄 Validated')),
                              DropdownMenuItem(value: 'pending', child: Text('⏳ Pending')),
                              DropdownMenuItem(value: 'failed', child: Text('❌ Failed')),
                            ],
                            onChanged: (val) {
                              if (val != null) viewModel.setTransactionFilters(status: val);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. TRANSACTION HISTORY TABLE
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'TRANSACTIONS LOG',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Showing ${filteredTransactions.length} entries',
                              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: AppColors.cardBorder, height: 1),

                      if (filteredTransactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No transactions found matching filters.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(AppColors.background.withOpacity(0.5)),
                              columns: const [
                                DataColumn(label: Text('# ID', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Initiator (Payer)', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Receiver (Radio)', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Amount', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Payment Method', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Date', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Receipt', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold))),
                              ],
                            rows: filteredTransactions.map((tx) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      '#${tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id}',
                                      style: const TextStyle(color: AppColors.textSecondary, fontFamily: 'monospace', fontSize: 12),
                                    ),
                                  ),
                                  // Initiator
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircleAvatar(
                                          radius: 14,
                                           backgroundColor: AppColors.primary.withOpacity(0.2),
                                           child: Text(
                                             (tx.initiatorName ?? 'U').substring(0, 1).toUpperCase(),
                                             style: const TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                                           ),
                                         ),
                                         const SizedBox(width: 8),
                                         Column(
                                           crossAxisAlignment: CrossAxisAlignment.start,
                                           mainAxisAlignment: MainAxisAlignment.center,
                                           children: [
                                             Text(
                                               tx.initiatorName ?? 'Station Administrator',
                                               style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                             ),
                                             if (tx.initiatorEmail != null)
                                               Text(
                                                 tx.initiatorEmail!,
                                                 style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                               ),
                                           ],
                                         ),
                                       ],
                                     ),
                                   ),
                                   // Receiver Radio
                                   DataCell(
                                     Row(
                                       mainAxisSize: MainAxisSize.min,
                                       children: [
                                         const Icon(Icons.radio_rounded, size: 16, color: AppColors.primaryLight),
                                         const SizedBox(width: 6),
                                         Text(
                                           tx.radioName,
                                           style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                         ),
                                       ],
                                     ),
                                   ),
                                   // Amount
                                   DataCell(
                                     Text(
                                       currencyFormatter.format(tx.amount),
                                       style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                     ),
                                   ),
                                   // Payment Method badge
                                   DataCell(_buildPaymentMethodBadge(tx.paymentMethod ?? 'MoMo')),
                                   // Status
                                   DataCell(
                                     Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                       decoration: BoxDecoration(
                                         color: _getStatusColor(tx.status).withOpacity(0.12),
                                         borderRadius: BorderRadius.circular(6),
                                         border: Border.all(color: _getStatusColor(tx.status).withOpacity(0.3), width: 0.5),
                                       ),
                                       child: Text(
                                         tx.statusLabel,
                                         style: TextStyle(
                                           color: _getStatusColor(tx.status),
                                           fontSize: 11,
                                           fontWeight: FontWeight.bold,
                                         ),
                                       ),
                                     ),
                                   ),
                                   // Date
                                   DataCell(
                                     Text(
                                       DateFormat('MMM d, yyyy').format(tx.createdAt),
                                       style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                     ),
                                   ),
                                   // Receipt action
                                   DataCell(
                                     OutlinedButton.icon(
                                       icon: const Icon(Icons.receipt_rounded, size: 14),
                                       label: const Text('Receipt'),
                                       style: OutlinedButton.styleFrom(
                                         foregroundColor: AppColors.primaryLight,
                                         side: const BorderSide(color: AppColors.primaryDark),
                                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                         textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                       ),
                                       onPressed: () => _showTransactionReceipt(context, tx),
                                     ),
                                   ),
                                 ],
                               );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodBadge(String method) {
    Color badgeColor = AppColors.info;
    Color textColor = Colors.white;
    String label = method;

    final lower = method.toLowerCase();
    if (lower.contains('momo')) {
      badgeColor = const Color(0xFFFFCC00);
      textColor = Colors.black;
      label = 'MoMo';
    } else if (lower.contains('om') || lower.contains('orange')) {
      badgeColor = const Color(0xFFFF7900);
      textColor = Colors.white;
      label = 'Orange Money';
    } else if (lower.contains('eco')) {
      badgeColor = const Color(0xFF005B94);
      textColor = Colors.white;
      label = 'Ecobank';
    } else {
      badgeColor = const Color(0xFF7C3AED);
      textColor = Colors.white;
      label = 'Credit Card';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withOpacity(0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(color: textColor == Colors.white ? AppColors.textPrimary : Colors.amber.shade200, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Color _getStatusColor(sys_tx.TransactionStatus status) {
    switch (status) {
      case sys_tx.TransactionStatus.paid:
      case sys_tx.TransactionStatus.validated:
        return AppColors.success;
      case sys_tx.TransactionStatus.pending:
        return AppColors.warning;
      case sys_tx.TransactionStatus.failed:
        return AppColors.error;
      case sys_tx.TransactionStatus.refunded:
        return AppColors.chartTalk;
    }
  }

  void _showTransactionReceipt(BuildContext context, sys_tx.Transaction tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_rounded, color: AppColors.primaryLight),
            const SizedBox(width: 8),
            Text('Transaction Financial Breakdown #${tx.id.length > 8 ? tx.id.substring(0, 8) : tx.id}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16)),
          ],
        ),
        content: Container(
          width: 480,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReceiptRow('Transaction Reference', '#${tx.id}'),
              _buildReceiptRow('Operation Type', tx.typeLabel),
              if (tx.announcementCategory != null)
                _buildReceiptRow('Announcement Category', tx.announcementCategory!),
              const Divider(color: AppColors.cardBorder, height: 16),

              // Payer & Payee Details
              _buildReceiptRow('Initiator (Payer)', tx.initiatorName ?? 'Station Administrator'),
              if (tx.initiatorEmail != null)
                _buildReceiptRow('Initiator Contact', tx.initiatorEmail!),
              _buildReceiptRow('Receiver Radio Station', tx.radioName),
              _buildReceiptRow('Payment Method', tx.paymentMethod ?? 'Mobile Money'),

              const Divider(color: AppColors.cardBorder, height: 16),

              _buildReceiptRow('Total Amount Billed', '\$${tx.amount.toStringAsFixed(2)}'),
              _buildReceiptRow('Payment Status', tx.statusLabel),
              _buildReceiptRow('Timestamp', DateFormat('MMMM dd, yyyy - hh:mm a').format(tx.createdAt)),

              if (tx.validatedBy != null) ...[
                const SizedBox(height: 6),
                _buildReceiptRow('Validated By', tx.validatedBy!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: AppColors.primaryLight)),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

