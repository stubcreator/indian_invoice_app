import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/invoice_model.dart';
import '../../common/app_card.dart';
import '../../common/status_badge.dart';
import '../navigation/main_navigation_screen.dart';

class ThankYouScreen extends StatefulWidget {
  final InvoiceModel invoice;
  final Uint8List pdfBytes;
  final String? colorHex;

  const ThankYouScreen({
    super.key,
    required this.invoice,
    required this.pdfBytes,
    this.colorHex,
  });

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    _animationController.forward();

    // Trigger review dialog after screen loads as requested in PO flow
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) {
          _showReviewDialog();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showReviewDialog() {
    int rating = 5;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String feedbackHint;
            switch (rating) {
              case 5:
                feedbackHint = 'Loved it! Highly recommended! 🎉';
                break;
              case 4:
                feedbackHint = 'Great experience! 👍';
                break;
              case 3:
                feedbackHint = 'Good, but has room to improve. 💡';
                break;
              case 2:
                feedbackHint = 'Could be much better. ⚠️';
                break;
              case 1:
              default:
                feedbackHint = 'Disappointed. Let us know why. 😞';
                break;
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 44,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Rate Your Experience',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enjoying Invoice Generator Pro? Your feedback helps us make billing fast and effortless!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Interactive 5 Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final starNumber = index + 1;
                        final isFilled = starNumber <= rating;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              rating = starNumber;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.star_rounded,
                              size: 38,
                              color: isFilled ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      feedbackHint,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Dialog Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppColors.cardBorder),
                            ),
                            child: const Text(
                              'Maybe Later',
                              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogCtx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(rating >= 4
                                      ? 'Thank you for your 5-star support! ❤️'
                                      : 'Thank you for your valuable feedback!'),
                                  backgroundColor: AppColors.primary,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(color: AppColors.textWhite, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<File> _writePdfToFile() async {
    final dir = await getTemporaryDirectory();
    final cleanNum = widget.invoice.invoiceNumber.replaceAll('/', '_').replaceAll('\\', '_');
    final file = File('${dir.path}/Invoice_$cleanNum.pdf');
    await file.writeAsBytes(widget.pdfBytes);
    return file;
  }

  // 1. Download PDF Action
  Future<void> _downloadPdf() async {
    setState(() => _isProcessing = true);
    try {
      final file = await _writePdfToFile();
      final result = await OpenFile.open(file.path);
      if (mounted) {
        if (result.type == ResultType.done) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invoice saved at ${file.path} and opened!'),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to: ${file.path}'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download PDF: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 2. Share PDF Action
  Future<void> _sharePdf() async {
    setState(() => _isProcessing = true);
    try {
      final file = await _writePdfToFile();
      final cleanNum = widget.invoice.invoiceNumber;
      final total = widget.invoice.grandTotal.toStringAsFixed(2);
      final bizName = widget.invoice.business?.businessName ?? 'our company';

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Invoice #$cleanNum from $bizName',
        text: 'Hello, please find attached Invoice #$cleanNum for ${widget.invoice.currencySymbol}$total from $bizName. Thank you!',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share PDF: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // 3. Email PDF Action
  Future<void> _sendEmail() async {
    final clientEmail = widget.invoice.client?.email?.trim() ?? '';
    final bizName = widget.invoice.business?.businessName ?? 'Invoice Generator';
    final invNum = widget.invoice.invoiceNumber;
    final total = '${widget.invoice.currencySymbol} ${widget.invoice.grandTotal.toStringAsFixed(2)}';

    if (clientEmail.isEmpty) {
      _showEmailInputDialog();
      return;
    }

    _launchEmail(clientEmail, invNum, total, bizName);
  }

  Future<void> _launchEmail(String recipient, String invNum, String total, String bizName) async {
    final subject = Uri.encodeComponent('Invoice #$invNum from $bizName');
    final body = Uri.encodeComponent(
      'Dear ${widget.invoice.clientName},\n\n'
      'Please find details for your Invoice #$invNum:\n'
      'Total Amount: $total\n'
      'Issue Date: ${widget.invoice.invoiceDate}\n'
      'Due Date: ${widget.invoice.dueDate}\n\n'
      'Thank you for your business!\n\n'
      'Best regards,\n$bizName',
    );

    final mailtoUri = Uri.parse('mailto:$recipient?subject=$subject&body=$body');

    try {
      final launched = await launchUrl(mailtoUri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No email app found on device.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email app: $e')),
        );
      }
    }
  }

  void _showEmailInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Invoice via Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter recipient email address:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'client@example.com',
                prefixIcon: Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final email = controller.text.trim();
              if (email.isNotEmpty) {
                Navigator.pop(ctx);
                _launchEmail(
                  email,
                  widget.invoice.invoiceNumber,
                  '${widget.invoice.currencySymbol} ${widget.invoice.grandTotal.toStringAsFixed(2)}',
                  widget.invoice.business?.businessName ?? 'Invoice Generator',
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Send', style: TextStyle(color: AppColors.textWhite)),
          ),
        ],
      ),
    );
  }

  // 4. Home Action
  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _goHome();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Invoice Generated'),
          leading: IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Home',
            onPressed: _goHome,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Column(
            children: [
              // Celebration Badge
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 42,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Thank You!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Invoice #${widget.invoice.invoiceNumber} is ready to send',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Invoice Details Summary Card
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CLIENT',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.invoice.clientName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            if (widget.invoice.clientCompanyName != null && widget.invoice.clientCompanyName!.isNotEmpty)
                              Text(
                                widget.invoice.clientCompanyName!,
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                          ],
                        ),
                        StatusBadge(status: widget.invoice.status),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryItem('Invoice Date', widget.invoice.invoiceDate),
                        _buildSummaryItem('Due Date', widget.invoice.dueDate),
                        _buildSummaryItem(
                          'Total Amount',
                          CurrencyFormatter.format(widget.invoice.grandTotal, symbol: widget.invoice.currencySymbol),
                          isBold: true,
                          valueColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4 Core Action Buttons
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.file_download_outlined,
                      title: 'Download',
                      subtitle: 'Save & open PDF',
                      color: const Color(0xFF2563EB),
                      onTap: _isProcessing ? null : _downloadPdf,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.share_rounded,
                      title: 'Share',
                      subtitle: 'WhatsApp, Drive, etc.',
                      color: const Color(0xFF059669),
                      onTap: _isProcessing ? null : _sharePdf,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: widget.invoice.client?.email?.isNotEmpty == true
                          ? widget.invoice.client!.email!
                          : 'Send via mail',
                      color: const Color(0xFF7C3AED),
                      onTap: _isProcessing ? null : _sendEmail,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      subtitle: 'Go to dashboard',
                      color: const Color(0xFF0F172A),
                      onTap: _goHome,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Rate us banner
              InkWell(
                onTap: _showReviewDialog,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loving the App? Give us 5 Stars!',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF92400E),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Help us grow by rating your experience.',
                              style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFD97706)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
