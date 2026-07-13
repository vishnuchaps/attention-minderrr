import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class ResultPdfExporter {
  const ResultPdfExporter._();

  static Future<String?> exportManagementPage(GlobalKey boundaryKey) async {
    await WidgetsBinding.instance.endOfFrame;

    final boundary = boundaryKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) {
      throw StateError('The management report is not ready to export.');
    }

    final pixelRatio = math.min(
      2.0,
      math.max(1.0, 10000 / boundary.size.height),
    );
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw StateError('Could not render the management report.');
    }

    final pngBytes = byteData.buffer.asUint8List();
    final pdfBytes = _createPaginatedPdf(
      pngBytes: pngBytes,
      imageWidth: boundary.size.width * pixelRatio,
      imageHeight: boundary.size.height * pixelRatio,
    );
    final timestamp = DateTime.now().toIso8601String().replaceAll(
      RegExp(r'[:.]'),
      '-',
    );
    final fileName = 'attention-management-result-$timestamp';

    final savedPath = await FileSaver.instance.saveAs(
      name: fileName,
      bytes: Uint8List.fromList(pdfBytes),
      fileExtension: 'pdf',
      mimeType: MimeType.pdf,
    );
    return savedPath == null ? null : '$fileName.pdf';
  }

  static List<int> _createPaginatedPdf({
    required Uint8List pngBytes,
    required double imageWidth,
    required double imageHeight,
  }) {
    final document = PdfDocument();
    document.pageSettings.size = PdfPageSize.a4;
    document.pageSettings.margins.all = 24;

    final bitmap = PdfBitmap(pngBytes);
    final pageWidth = document.pageSettings.size.width - 48;
    final pageHeight = document.pageSettings.size.height - 48;
    final renderedHeight = imageHeight * (pageWidth / imageWidth);
    final pageCount = math.max(1, (renderedHeight / pageHeight).ceil());

    for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
      final page = document.pages.add();
      page.graphics.save();
      page.graphics.setClip(bounds: Rect.fromLTWH(0, 0, pageWidth, pageHeight));
      page.graphics.drawImage(
        bitmap,
        Rect.fromLTWH(0, -(pageIndex * pageHeight), pageWidth, renderedHeight),
      );
      page.graphics.restore();
    }

    final bytes = document.saveSync();
    document.dispose();
    return bytes;
  }
}
