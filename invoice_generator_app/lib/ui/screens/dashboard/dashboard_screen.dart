import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_card.dart';
import '../../common/empty_state_view.dart';
import '../../common/metric_card.dart';
import '../../common/status_badge.dart';
import '../business/business_profile_screen.dart';
import '../clients/client_list_screen.dart';
import '../invoice/create_invoice_screen.dart';
import '../invoice/invoice_detail_screen.dart';
import '../items/item_list_screen.dart';
import '../pdf_preview/pdf_preview_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoiceProv = context.watch<InvoiceProvider>();
    final bizProv = context.watch<BusinessProvider>();
    final setProv = context.watch<SettingsProvider>();

    final metrics = invoiceProv.metrics;
    final business = bizProv.business;
    final currencySymbol = setProv.settings.currencySymbol;
    final currencyCode = setProv.settings.currencyCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 16,
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BusinessProfileScreen()),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      business != null && business.businessName.isNotEmpty
                          ? business.businessName
                          : 'Set Business Profile',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          business?.gstin != null && business!.gstin!.isNotEmpty
                              ? 'GSTIN: ${business.gstin}'
                              : 'Tap to configure GST & Bank',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.textPrimary),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Invoice', style: TextStyle(fontWeight: FontWeight.w700)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await invoiceProv.loadInvoices();
          await invoiceProv.loadMetrics();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
          children: [
            // 1. FINANCIAL METRICS HORIZONTAL CAROUSEL
            SizedBox(
              height: 118,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  MetricCard(
                    title: 'Total Invoiced',
                    amount: metrics.totalInvoiced,
                    count: metrics.totalCount,
                    currencySymbol: currencySymbol,
                    currencyCode: currencyCode,
                    icon: Icons.receipt_long_rounded,
                    accentColor: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  MetricCard(
                    title: 'Received (Paid)',
                    amount: metrics.totalPaid,
                    count: metrics.paidCount,
                    currencySymbol: currencySymbol,
                    currencyCode: currencyCode,
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: AppColors.success,
                  ),
                  const SizedBox(width: 12),
                  MetricCard(
                    title: 'Pending (Unpaid)',
                    amount: metrics.totalUnpaid,
                    count: metrics.unpaidCount,
                    currencySymbol: currencySymbol,
                    currencyCode: currencyCode,
                    icon: Icons.schedule_rounded,
                    accentColor: AppColors.warning,
                  ),
                  if (metrics.totalOverdue > 0) ...[
                    const SizedBox(width: 12),
                    MetricCard(
                      title: 'Overdue',
                      amount: metrics.totalOverdue,
                      count: metrics.overdueCount,
                      currencySymbol: currencySymbol,
                      currencyCode: currencyCode,
                      icon: Icons.warning_amber_rounded,
                      accentColor: AppColors.danger,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. QUICK ACTION TILES
            _buildQuickActions(context),
            const SizedBox(height: 18),

            // 3. SEARCH BAR
            TextField(
              controller: _searchController,
              onChanged: (val) => invoiceProv.setSearchQuery(val),
              decoration: InputDecoration(
                hintText: 'Search by Invoice # or Customer...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          invoiceProv.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
            const SizedBox(height: 12),

            // 4. FILTER PILLS BAR
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All (${metrics.totalCount})', invoiceProv),
                  const SizedBox(width: 8),
                  _buildFilterChip('unpaid', 'Unpaid (${metrics.unpaidCount})', invoiceProv),
                  const SizedBox(width: 8),
                  _buildFilterChip('paid', 'Paid (${metrics.paidCount})', invoiceProv),
                  const SizedBox(width: 8),
                  _buildFilterChip('overdue', 'Overdue (${metrics.overdueCount})', invoiceProv),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. INVOICES LIST
            if (invoiceProv.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (invoiceProv.invoices.isEmpty)
              EmptyStateView(
                icon: Icons.receipt_long_outlined,
                title: 'No Invoices Found',
                message: _searchController.text.isNotEmpty
                    ? 'No invoices match your search query.'
                    : 'Create your first GST or International invoice in seconds!',
                buttonText: _searchController.text.isEmpty ? 'Create Invoice' : null,
                onButtonPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
                  );
                },
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoiceProv.invoices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final inv = invoiceProv.invoices[index];
                  return _buildInvoiceCard(context, inv);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        _buildActionTile(
          context,
          icon: Icons.add_circle_outline_rounded,
          title: 'New Invoice',
          color: AppColors.primary,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildActionTile(
          context,
          icon: Icons.people_outline_rounded,
          title: 'Customers',
          color: AppColors.accent,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientListScreen()),
            );
          },
        ),
        const SizedBox(width: 10),
        _buildActionTile(
          context,
          icon: Icons.inventory_2_outlined,
          title: 'Catalog',
          color: AppColors.success,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ItemListScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String status, String label, InvoiceProvider provider) {
    final isSelected = provider.selectedStatus == status;
    return InkWell(
      onTap: () => provider.setFilterStatus(status),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel inv) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: inv.id!)),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '# ${inv.invoiceNumber}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
                  ),
                  if (inv.placeOfSupplyCode != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'POS: ${inv.placeOfSupplyCode}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ],
              ),
              StatusBadge(status: inv.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.clientName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    if (inv.clientCompanyName != null && inv.clientCompanyName!.isNotEmpty)
                      Text(
                        inv.clientCompanyName!,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormatter.formatShort(DateFormatter.parse(inv.invoiceDate))} • Due: ${DateFormatter.formatShort(DateFormatter.parse(inv.dueDate))}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(
                      inv.grandTotal,
                      symbol: inv.currencySymbol,
                      currencyCode: inv.currencyCode,
                    ),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  if (inv.balanceDue > 0 && inv.status != 'paid')
                    Text(
                      'Due: ${CurrencyFormatter.format(inv.balanceDue, symbol: inv.currencySymbol, currencyCode: inv.currencyCode)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${inv.items.length} items',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final fullInvoice = await context.read<InvoiceProvider>().getInvoice(inv.id!);
                      if (fullInvoice != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PdfPreviewScreen(invoice: fullInvoice)),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Text('PDF', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateInvoiceScreen(editInvoiceId: inv.id)),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text('Edit', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
