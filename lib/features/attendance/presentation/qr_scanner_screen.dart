import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/app_error_handler.dart';
import '../data/attendance_repository.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;
  final _attendanceRepo = AttendanceRepository();
  bool _processing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = MobileScannerController(
      formats: const [BarcodeFormat.qrCode],
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        if (!_processing) {
          _controller.start();
        }
      case AppLifecycleState.inactive:
        _controller.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _processing = true);
    _controller.stop();

    final qrToken = barcode!.rawValue!;

    try {
      final data = await _attendanceRepo.recordAttendance(qrToken);

      if (!mounted) return;

      final success = data['success'] == true;
      final isOfflineQueued = data['offline_queued'] == true;
      final isAlreadyRecorded = data['already_recorded'] == true;
      final message = data['message'] ?? data['error'] ?? '';

      await _showResultDialog(
        success: success,
        isOfflineQueued: isOfflineQueued,
        isAlreadyRecorded: isAlreadyRecorded,
        message: message,
      );
    } catch (e) {
      if (!mounted) return;
      await _showResultDialog(
        success: false,
        isOfflineQueued: false,
        isAlreadyRecorded: false,
        message: AppErrorHandler.friendlyMessage(e),
      );
    }
  }

  Future<void> _showResultDialog({
    required bool success,
    required bool isOfflineQueued,
    required bool isAlreadyRecorded,
    required String message,
  }) async {
    final IconData dialogIcon;
    final Color dialogColor;
    final String dialogTitle;

    if (isOfflineQueued) {
      dialogIcon = Icons.cloud_queue_rounded;
      dialogColor = AppColors.gold;
      dialogTitle = 'تم الحفظ أوفلاين';
    } else if (isAlreadyRecorded) {
      dialogIcon = Icons.info_outline_rounded;
      dialogColor = AppColors.warning;
      dialogTitle = 'مسجل مسبقاً';
    } else if (success) {
      dialogIcon = Icons.check_circle_rounded;
      dialogColor = AppColors.success;
      dialogTitle = 'تم التسجيل بنجاح ✓';
    } else {
      dialogIcon = Icons.error_outline_rounded;
      dialogColor = AppColors.error;
      dialogTitle = 'فشل التسجيل';
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              dialogIcon,
              color: dialogColor,
              size: Responsive.iconSize(context, 72),
            ),
            SizedBox(height: Responsive.spacing(context, 16)),
            Text(
              dialogTitle,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 18),
                fontWeight: FontWeight.w700,
                color: dialogColor,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: Responsive.spacing(context, 8)),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 14),
                color: AppColors.textSecondary,
                fontFamily: 'Cairo',
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: dialogColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                context.pop();
                if (success) {
                  context.pop();
                } else {
                  setState(() => _processing = false);
                  _controller.start();
                }
              },
              child: Text(
                'حسناً',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: Responsive.fontSize(context, 16),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanSize = Responsive.isTablet(context)
        ? 300.0
        : Responsive.isDesktop(context)
            ? 350.0
            : 250.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'مسح رمز QR للحضور',
          style: TextStyle(
            fontFamily: 'Cairo',
            fontSize: Responsive.fontSize(context, 18),
            color: AppColors.gold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchOn ? Icons.flash_on : Icons.flash_off,
              color: _torchOn ? AppColors.gold : AppColors.textSecondary,
            ),
            onPressed: () {
              setState(() => _torchOn = !_torchOn);
              _controller.toggleTorch();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Dark overlay with scan window
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanSize,
                    height: scanSize,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Scan frame corners
          Center(
            child: SizedBox(
              width: scanSize,
              height: scanSize,
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    child: _Corner(color: AppColors.gold),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Transform.scale(
                        scaleX: -1, child: _Corner(color: AppColors.gold)),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Transform.scale(
                        scaleY: -1, child: _Corner(color: AppColors.gold)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Transform.scale(
                        scaleX: -1,
                        scaleY: -1,
                        child: _Corner(color: AppColors.gold)),
                  ),
                ],
              ),
            ),
          ),

          // Bottom instruction text
          Positioned(
            bottom: Responsive.spacing(context, 60),
            left: 0,
            right: 0,
            child: Text(
              'وجّه الكاميرا نحو رمز QR المعروض',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: Responsive.fontSize(context, 16),
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          // Processing overlay
          if (_processing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
        ],
      ),
    );
  }
}

// Corner decoration
class _Corner extends StatelessWidget {
  final Color color;

  const _Corner({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(painter: _CornerPainter(color: color)),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;

  const _CornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CornerPainter oldDelegate) => false;
}
