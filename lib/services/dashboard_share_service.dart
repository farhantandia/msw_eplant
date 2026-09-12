import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DashboardShareService {
  /// Captures a [RepaintBoundary] identified by [key] as a high-definition PNG
  /// and shares it via native share dialog (WhatsApp, Telegram, Email, etc.).
  static Future<bool> captureAndShare({
    required GlobalKey key,
    required String title,
    required String fileNamePrefix,
    BuildContext? context,
    double pixelRatio = 2.5,
  }) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        debugPrint('DashboardShareService: RenderRepaintBoundary not found for key: $key');
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dashboard view is not ready to capture.')),
          );
        }
        return false;
      }

      // Capture widget to image
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        debugPrint('DashboardShareService: Failed to convert image to PNG byte data');
        return false;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      // Save to temporary directory
      try {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final sanitizedPrefix = fileNamePrefix.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
        final file = File('${tempDir.path}/${sanitizedPrefix}_$timestamp.png');
        await file.writeAsBytes(pngBytes);

        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png', name: '$sanitizedPrefix.png')],
          text: title,
          subject: title,
        );
        return true;
      } catch (fileError) {
        debugPrint('DashboardShareService: File fallback due to: $fileError');
        // Fallback directly to memory XFile
        await Share.shareXFiles(
          [XFile.fromData(pngBytes, mimeType: 'image/png', name: '$fileNamePrefix.png')],
          text: title,
          subject: title,
        );
        return true;
      }
    } catch (e) {
      debugPrint('DashboardShareService error: $e');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share dashboard image: $e')),
        );
      }
      return false;
    }
  }
}
