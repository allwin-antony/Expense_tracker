import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Parsed data from a UPI QR code.
class UpiQrData {
  final String rawUri;
  final String payeeAddress; // pa
  final String payeeName; // pn
  final String? amount; // am (null if not in QR)
  final String? transactionNote; // tn
  final String? merchantCode; // mc
  final String? transactionRef; // tr

  const UpiQrData({
    required this.rawUri,
    required this.payeeAddress,
    required this.payeeName,
    this.amount,
    this.transactionNote,
    this.merchantCode,
    this.transactionRef,
  });
}

/// Full-screen QR code scanner for UPI payment QR codes.
///
/// Returns a [UpiQrData] via Navigator.pop on successful scan,
/// or null if the user cancels.
class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasScanned = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parse a UPI URI string into structured data.
  /// Returns null if the string is not a valid UPI URI.
  UpiQrData? _parseUpiUri(String raw) {
    try {
      final uri = Uri.parse(raw);

      // UPI URIs use scheme "upi" and path/host "pay"
      if (uri.scheme.toLowerCase() != 'upi') return null;

      final params = uri.queryParameters;
      final pa = params['pa'];

      if (pa == null || pa.isEmpty) return null;

      return UpiQrData(
        rawUri: raw,
        payeeAddress: pa,
        payeeName: params['pn'] ?? '',
        amount: (params['am'] != null && params['am']!.isNotEmpty && params['am'] != '0')
            ? params['am']
            : null,
        transactionNote: params['tn'],
        merchantCode: params['mc'],
        transactionRef: params['tr'],
      );
    } catch (e) {
      return null;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final parsed = _parseUpiUri(raw);
      if (parsed != null) {
        setState(() => _hasScanned = true);
        _controller.stop();
        Navigator.of(context).pop(parsed);
        return;
      }
    }

    // If we get here, a QR was detected but it wasn't a valid UPI QR
    if (!_hasScanned) {
      setState(() {
        _errorMessage = 'Not a valid UPI QR code. Please scan a UPI payment QR.';
      });
      // Clear error after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _errorMessage = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan UPI QR Code'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on ? Icons.flash_on : Icons.flash_off,
                  color: state.torchState == TorchState.on ? Colors.amber : Colors.white,
                );
              },
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan overlay with cutout
          CustomPaint(
            size: size,
            painter: _ScanOverlayPainter(
              scanAreaSize: scanAreaSize,
              borderColor: _errorMessage != null
                  ? Colors.red.withValues(alpha: 0.8)
                  : theme.colorScheme.primary.withValues(alpha: 0.8),
            ),
          ),

          // Corner brackets for the scan area
          Center(
            child: SizedBox(
              width: scanAreaSize,
              height: scanAreaSize,
              child: CustomPaint(
                painter: _CornerBracketPainter(
                  color: _errorMessage != null
                      ? Colors.red
                      : theme.colorScheme.primary,
                  strokeWidth: 4.0,
                  bracketLength: 30.0,
                ),
              ),
            ),
          ),

          // Instructions text
          Positioned(
            bottom: 120,
            left: 32,
            right: 32,
            child: Column(
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Point your camera at a UPI QR code',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints a semi-transparent overlay with a clear cutout for the scan area.
class _ScanOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  _ScanOverlayPainter({required this.scanAreaSize, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final scanRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    // Draw overlay with cutout
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor;
}

/// Paints corner brackets around the scan area.
class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double bracketLength;

  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.bracketLength,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final l = bracketLength;

    // Top-left
    canvas.drawLine(Offset(0, l), Offset.zero, paint);
    canvas.drawLine(Offset.zero, Offset(l, 0), paint);

    // Top-right
    canvas.drawLine(Offset(w - l, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, l), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, h - l), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(l, h), paint);

    // Bottom-right
    canvas.drawLine(Offset(w, h - l), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w - l, h), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerBracketPainter oldDelegate) =>
      oldDelegate.color != color;
}
