import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/business_model.dart';
import '../../../../providers/business_provider.dart';
import '../../../../providers/client_provider.dart';
import '../../../../providers/invoice_provider.dart';
import '../../../../providers/item_provider.dart';
import '../../business/business_profile_screen.dart';

class BusinessSwitcherSheet extends StatelessWidget {
  const BusinessSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bizProv = context.watch<BusinessProvider>();
    final businesses = bizProv.businesses;
    final activeBiz = bizProv.activeBusiness;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Business',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'All invoices, catalog & clients adapt to your selection',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Businesses List
          if (businesses.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Column(
                children: [
                  Icon(Icons.business_rounded, size: 40, color: AppColors.textMuted),
                  SizedBox(height: 8),
                  Text('No businesses added yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                    'Create your first business profile to get started',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.45),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: businesses.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final biz = businesses[index];
                  final isSelected = activeBiz?.id != null && activeBiz?.id == biz.id;

                  return InkWell(
                    onTap: () async {
                      await bizProv.selectBusiness(biz);
                      if (context.mounted) {
                        context.read<InvoiceProvider>().setBusinessId(biz.id);
                        context.read<ClientProvider>().setBusinessId(biz.id);
                        context.read<ItemProvider>().setBusinessId(biz.id);
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withValues(alpha: 0.06) : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Business Avatar / Logo
                          _buildBusinessAvatar(biz),
                          const SizedBox(width: 12),

                          // Business Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        biz.businessName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (biz.tradeName != null && biz.tradeName!.isNotEmpty)
                                  Text(
                                    biz.tradeName!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    if (biz.gstin != null && biz.gstin!.isNotEmpty) ...[
                                      Text(
                                        'GSTIN: ${biz.gstin}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    // if (biz.state != null && biz.state!.isNotEmpty)
                                    //   Text(
                                    //     biz.state!,
                                    //     style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    //   ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Edit Button
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                            tooltip: 'Edit Profile',
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => BusinessProfileScreen(business: biz)),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 18),

          // Add New Business Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessProfileScreen(isNew: true)));
              },
              icon: const Icon(Icons.add_business_rounded, size: 20),
              label: const Text(
                'Add New Business Profile',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessAvatar(BusinessModel biz) {
    if (biz.logoPath != null && File(biz.logoPath!).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(File(biz.logoPath!), width: 44, height: 44, fit: BoxFit.cover),
      );
    }

    final initial = biz.businessName.isNotEmpty ? biz.businessName[0].toUpperCase() : 'B';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
      ),
    );
  }
}
