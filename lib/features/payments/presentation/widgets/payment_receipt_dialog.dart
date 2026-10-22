import 'dart:ui' as ui;
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/payment_model.dart';

class PaymentReceiptDialog extends StatefulWidget {
  final PaymentReceipt receipt;

  const PaymentReceiptDialog({super.key, required this.receipt});

  @override
  State<PaymentReceiptDialog> createState() => _PaymentReceiptDialogState();
}

class _PaymentReceiptDialogState extends State<PaymentReceiptDialog> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isSaving = false;
  String? _saveStatus;

  Future<void> _saveAsPng() async {
    setState(() {
      _isSaving = true;
      _saveStatus = null;
    });

    try {
      final boundary =
          _receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('تعذر التقاط صورة الإيصال');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('تعذر تشفير بيانات الصورة');

      final bytes = byteData.buffer.asUint8List();
      final idShort = widget.receipt.paymentId.length >= 8
          ? widget.receipt.paymentId.substring(0, 8)
          : widget.receipt.paymentId;
      final fileName = 'taj_receipt_$idShort';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        ext: 'png',
        mimeType: MimeType.png,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveStatus = 'تم حفظ الإيصال بنجاح ✓';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveStatus = 'تعذر الحفظ: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The printable/exportable receipt card (captured by RepaintBoundary)
              RepaintBoundary(
                key: _receiptKey,
                child: _ReceiptCardContent(receipt: widget.receipt),
              ),

              const SizedBox(height: 16),

              // Save status feedback
              if (_saveStatus != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _saveStatus!.contains('✓')
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _saveStatus!.contains('✓')
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                  child: Text(
                    _saveStatus!,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _saveStatus!.contains('✓')
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ),
              ],

              // Actions
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: _isSaving ? null : _saveAsPng,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _isSaving ? 'جارٍ التنزيل...' : 'حفظ الإيصال كصورة (PNG)',
                      style: const TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'إغلاق',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.w700,
                      ),
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
}

class _ReceiptCardContent extends StatelessWidget {
  final PaymentReceipt receipt;

  const _ReceiptCardContent({required this.receipt});

  @override
  Widget build(BuildContext context) {
    String formattedDate;
    try {
      formattedDate = DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(receipt.paidAt);
    } catch (_) {
      formattedDate =
          '${receipt.paidAt.year}/${receipt.paidAt.month.toString().padLeft(2, '0')}/${receipt.paidAt.day.toString().padLeft(2, '0')}';
    }
    final receiptNumberDisplay =
        (receipt.receiptNumber != null && receipt.receiptNumber!.isNotEmpty)
            ? receipt.receiptNumber!
            : (receipt.paymentId.length >= 8
                ? receipt.paymentId.substring(0, 8).toUpperCase()
                : receipt.paymentId.toUpperCase());

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Header
          Center(
            child: Image.asset(
              'assets/images/Untitled-1.png',
              height: Responsive.spacing(context, 48),
              errorBuilder: (_, __, ___) => const Icon(
                Icons.verified_outlined,
                color: AppColors.gold,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'إيصال سداد رسمي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.gold,
              ),
            ),
          ),
          const Center(
            child: Text(
              'مركز تاج دنتكس للتدريب الطبي التخصصي',
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 14),

          // Meta Row: Receipt Number & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'رقم الإيصال: #$receiptNumberDisplay',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  formattedDate,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Trainee & Course Info Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
            ),
            child: Column(
              children: [
                _ReceiptRow(
                  label: 'اسم المتدرب',
                  value: receipt.traineeName,
                ),
                if (receipt.traineeCode != null && receipt.traineeCode!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ReceiptRow(
                    label: 'كود المتدرب',
                    value: receipt.traineeCode!,
                    valueColor: AppColors.gold,
                  ),
                ],
                const SizedBox(height: 8),
                _ReceiptRow(
                  label: 'الدورة التدريبية',
                  value: receipt.courseName,
                ),
                if (receipt.cohortName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ReceiptRow(
                    label: 'المجموعة',
                    value: receipt.cohortName,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Financial Amount Box (Highlight)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                const Text(
                  'المبلغ المسدد',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${receipt.amount.toStringAsFixed(0)} ${receipt.currencySymbol}',
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 8),
                _ReceiptRow(
                  label: 'طريقة الدفع',
                  value: receipt.paymentMethodAr,
                ),
                if (receipt.externalReference != null &&
                    receipt.externalReference!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _ReceiptRow(
                    label: 'رقم العملية / الحوالة',
                    value: receipt.externalReference!,
                  ),
                ],
                if (receipt.notes != null && receipt.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _ReceiptRow(
                    label: 'ملاحظات',
                    value: receipt.notes!,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Official Stamp & Verification Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'معتمد ومسجل إلكترونياً بالنظام المحاسبي للمركز',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'هذا الإيصال سند رسمي صادر عن مركز تاج دنتكس ولا يحتاج لتوقيع يدوي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Cairo',
                fontSize: 10,
                color: Color(0xFF777777),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
