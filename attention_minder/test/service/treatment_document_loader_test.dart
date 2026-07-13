import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:attention_minder/service/treatment_document_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects PDF bytes independently of the file extension', () {
    final document = TreatmentDocumentLoader.loadBytes(
      Uint8List.fromList(utf8.encode('%PDF-1.7\n')),
    );

    expect(document.type, TreatmentDocumentType.pdf);
  });

  test('extracts readable paragraphs from DOCX bytes', () {
    const xml = '''
      <w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
        <w:body>
          <w:p><w:r><w:t>First paragraph.</w:t></w:r></w:p>
          <w:p><w:r><w:t>Second</w:t></w:r><w:r><w:t> paragraph.</w:t></w:r></w:p>
        </w:body>
      </w:document>
    ''';
    final archive = Archive()
      ..addFile(
        ArchiveFile.bytes(
          'word/document.xml',
          Uint8List.fromList(utf8.encode(xml)),
        ),
      );
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

    final document = TreatmentDocumentLoader.loadBytes(bytes);

    expect(document.type, TreatmentDocumentType.docx);
    expect(document.text, 'First paragraph.\n\nSecond paragraph.');
  });

  test('rejects unsupported downloaded content', () {
    expect(
      () => TreatmentDocumentLoader.loadBytes(
        Uint8List.fromList(utf8.encode('<html>Not a document</html>')),
      ),
      throwsFormatException,
    );
  });
}
