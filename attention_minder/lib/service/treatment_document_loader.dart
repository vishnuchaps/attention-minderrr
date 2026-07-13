import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

enum TreatmentDocumentType { pdf, docx }

class LoadedTreatmentDocument {
  const LoadedTreatmentDocument.pdf()
    : type = TreatmentDocumentType.pdf,
      text = null;

  const LoadedTreatmentDocument.docx(this.text)
    : type = TreatmentDocumentType.docx;

  final TreatmentDocumentType type;
  final String? text;
}

class TreatmentDocumentLoader {
  const TreatmentDocumentLoader._();

  static Future<LoadedTreatmentDocument> load(String path) async {
    final bytes = await File(path).readAsBytes();
    return loadBytes(bytes);
  }

  static LoadedTreatmentDocument loadBytes(Uint8List bytes) {
    if (_startsWith(bytes, const [0x25, 0x50, 0x44, 0x46])) {
      return const LoadedTreatmentDocument.pdf();
    }

    if (!_startsWith(bytes, const [0x50, 0x4B])) {
      throw const FormatException(
        'The downloaded file is not a supported PDF or DOCX document.',
      );
    }

    final archive = ZipDecoder().decodeBytes(bytes, verify: true);
    final documentFile = archive.findFile('word/document.xml');
    if (documentFile == null) {
      throw const FormatException(
        'The downloaded Office file is not a valid DOCX document.',
      );
    }

    final documentBytes = documentFile.readBytes();
    if (documentBytes == null) {
      throw const FormatException('The DOCX document could not be read.');
    }
    final document = XmlDocument.parse(utf8.decode(documentBytes));
    final paragraphs = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'p')
        .map(_paragraphText)
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
    if (paragraphs.isEmpty) {
      throw const FormatException(
        'This DOCX document does not contain readable text.',
      );
    }
    return LoadedTreatmentDocument.docx(paragraphs.join('\n\n'));
  }

  static String _paragraphText(XmlElement paragraph) {
    final buffer = StringBuffer();
    for (final element in paragraph.descendants.whereType<XmlElement>()) {
      switch (element.name.local) {
        case 't':
          buffer.write(element.innerText);
        case 'tab':
          buffer.write('\t');
        case 'br':
        case 'cr':
          buffer.write('\n');
      }
    }
    return buffer.toString().trim();
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) return false;
    }
    return true;
  }
}
