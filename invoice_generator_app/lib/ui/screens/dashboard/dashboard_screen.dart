import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../../providers/business_provider.dart';
import '../../../providers/client_provider.dart';
import '../../../providers/invoice_provider.dart';
import '../../../providers/item_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../common/app_card.dart';
import '../../common/empty_state_view.dart';
import '../../common/metric_card.dart';
import '../../common/status_badge.dart';
import '../invoice/create_invoice_screen.dart';
import '../invoice/invoice_detail_screen.dart';
import '../../../core/utils/pdf_export_helper.dart';
import 'widgets/business_switcher_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeBiz = context.read<BusinessProvider>().activeBusiness;
      if (activeBiz?.id != null) {
        context.read<InvoiceProvider>().setBusinessId(activeBiz!.id);
        context.read<ClientProvider>().setBusinessId(activeBiz.id);
        context.read<ItemProvider>().setBusinessId(activeBiz.id);
      }
    });
  }

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
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const BusinessSwitcherSheet(),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Text(
                            business != null && business.businessName.isNotEmpty
                                ? business.businessName
                                : 'Select Business',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 18, color: AppColors.primary),
                      ],
                    ),
                    Text(
                      business?.gstin != null && business!.gstin!.isNotEmpty
                          ? 'GSTIN: ${business.gstin}'
                          : (business?.state != null ? business!.state! : 'Tap to switch / add business'),
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_dashboard',
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
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
              height: 100,
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
            const SizedBox(height: 15),

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
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateInvoiceScreen()));
                },
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: invoiceProv.invoices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
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
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
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
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: inv.id!)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─────────────────────────────────────────────
          // Invoice Number + Status + More
          // ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '# ${inv.invoiceNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
                      ),
                    ),
                    if (inv.placeOfSupplyCode != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'POS: ${inv.placeOfSupplyCode}',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              StatusBadge(status: inv.status),

              const SizedBox(width: 2),

              // More Menu
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 20,
                icon: Icon(Icons.more_vert),
                splashRadius: 20,
                tooltip: 'More options',
                onSelected: (value) async {
                  final fullInvoice = await context.read<InvoiceProvider>().getInvoice(inv.id!);

                  if (fullInvoice == null || !context.mounted) return;

                  switch (value) {
                    case 'pdf':
                      await PdfExportHelper.downloadAndOpenPdf(context, fullInvoice);
                      break;

                    case 'share':
                      await PdfExportHelper.sharePdf(context, fullInvoice);
                      break;

                    case 'edit':
                      if (!context.mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CreateInvoiceScreen(editInvoiceId: inv.id)),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'pdf',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 10),
                        Text('Download'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share_rounded, size: 18, color: Color(0xFF059669)),
                        SizedBox(width: 10),
                        Text('Share'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 7),

          // ─────────────────────────────────────────────
          // Client + Amount
          // ─────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Client Information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inv.clientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),

                    if (inv.clientCompanyName != null && inv.clientCompanyName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        inv.clientCompanyName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],

                    const SizedBox(height: 5),

                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 11, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            DateFormatter.formatShort(DateFormatter.parse(inv.invoiceDate)),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Text('•', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ),
                        const Text('Due', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            DateFormatter.formatShort(DateFormatter.parse(inv.dueDate)),
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Amount
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

                  if (inv.balanceDue > 0 && inv.status != 'paid') ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Due: ${CurrencyFormatter.format(inv.balanceDue, symbol: inv.currencySymbol, currencyCode: inv.currencyCode)}',
                        style: const TextStyle(fontSize: 10, color: AppColors.danger, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ─────────────────────────────────────────────
          // Bottom Summary Row
          // ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.surfaceVariant, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Icon(Icons.receipt_long_outlined, size: 14, color: AppColors.textMuted),
                // const SizedBox(width: 5),
                // const Text(
                //   'Invoice',
                //   style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                // ),
                const Spacer(),
                const Text('Tap to view details', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right_rounded, size: 15, color: AppColors.textSecondary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildInvoiceCard(BuildContext context, InvoiceModel inv) {
  //   return AppCard(
  //     padding: const EdgeInsets.all(14),
  //     onTap: () {
  //       Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: inv.id!)));
  //     },
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 Text(
  //                   '# ${inv.invoiceNumber}',
  //                   style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary),
  //                 ),
  //                 if (inv.placeOfSupplyCode != null) ...[
  //                   const SizedBox(width: 8),
  //                   Container(
  //                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
  //                     decoration: BoxDecoration(
  //                       color: AppColors.surfaceVariant,
  //                       borderRadius: BorderRadius.circular(4),
  //                     ),
  //                     child: Text(
  //                       'POS: ${inv.placeOfSupplyCode}',
  //                       style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
  //                     ),
  //                   ),
  //                 ],
  //               ],
  //             ),
  //             StatusBadge(status: inv.status),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(inv.clientName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
  //                   if (inv.clientCompanyName != null && inv.clientCompanyName!.isNotEmpty)
  //                     Text(
  //                       inv.clientCompanyName!,
  //                       style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
  //                     ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     'Date: ${DateFormatter.formatShort(DateFormatter.parse(inv.invoiceDate))} • Due: ${DateFormatter.formatShort(DateFormatter.parse(inv.dueDate))}',
  //                     style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Column(
  //               crossAxisAlignment: CrossAxisAlignment.end,
  //               children: [
  //                 Text(
  //                   CurrencyFormatter.format(
  //                     inv.grandTotal,
  //                     symbol: inv.currencySymbol,
  //                     currencyCode: inv.currencyCode,
  //                   ),
  //                   style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
  //                 ),
  //                 if (inv.balanceDue > 0 && inv.status != 'paid')
  //                   Text(
  //                     'Due: ${CurrencyFormatter.format(inv.balanceDue, symbol: inv.currencySymbol, currencyCode: inv.currencyCode)}',
  //                     style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600),
  //                   ),
  //               ],
  //             ),
  //           ],
  //         ),
  //         const Divider(height: 16),
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Row(
  //               children: [
  //                 // Direct PDF Download & Open
  //                 InkWell(
  //                   onTap: () async {
  //                     final fullInvoice = await context.read<InvoiceProvider>().getInvoice(inv.id!);
  //                     if (fullInvoice != null && context.mounted) {
  //                       await PdfExportHelper.downloadAndOpenPdf(context, fullInvoice);
  //                     }
  //                   },
  //                   borderRadius: BorderRadius.circular(6),
  //                   child: const Padding(
  //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                     child: Row(
  //                       children: [
  //                         Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.primary),
  //                         SizedBox(width: 4),
  //                         Text(
  //                           'PDF',
  //                           style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 6),
  //                 // Direct Share
  //                 InkWell(
  //                   onTap: () async {
  //                     final fullInvoice = await context.read<InvoiceProvider>().getInvoice(inv.id!);
  //                     if (fullInvoice != null && context.mounted) {
  //                       await PdfExportHelper.sharePdf(context, fullInvoice);
  //                     }
  //                   },
  //                   borderRadius: BorderRadius.circular(6),
  //                   child: const Padding(
  //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                     child: Row(
  //                       children: [
  //                         Icon(Icons.share_rounded, size: 15, color: Color(0xFF059669)),
  //                         SizedBox(width: 4),
  //                         Text(
  //                           'Share',
  //                           style: TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 6),
  //                 InkWell(
  //                   onTap: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(builder: (_) => CreateInvoiceScreen(editInvoiceId: inv.id)),
  //                     );
  //                   },
  //                   borderRadius: BorderRadius.circular(6),
  //                   child: const Padding(
  //                     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //                     child: Row(
  //                       children: [
  //                         Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
  //                         SizedBox(width: 4),
  //                         Text(
  //                           'Edit',
  //                           style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
  //                         ),
  //                       ],
  //                     ),
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
