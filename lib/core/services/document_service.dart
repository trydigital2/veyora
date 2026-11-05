import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;

import '../../features/resume/domain/resume_models.dart';

class DocumentException implements Exception {
  DocumentException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DocumentService {
  const DocumentService();

  Future<String> extractText({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final lower = fileName.toLowerCase();
    try {
      if (lower.endsWith('.pdf')) return _extractPdf(bytes);
      if (lower.endsWith('.docx')) return _extractDocx(bytes);
      throw DocumentException('Upload a PDF or DOCX file.');
    } on DocumentException {
      rethrow;
    } catch (_) {
      throw DocumentException(
        'We could not read that file. Try exporting it as a text-based PDF and upload again.',
      );
    }
  }

  String _extractPdf(Uint8List bytes) {
    final document = sf.PdfDocument(inputBytes: bytes);
    try {
      final result = sf.PdfTextExtractor(document).extractText().trim();
      if (result.length < 40) {
        throw DocumentException(
          'No readable text was found. Scanned PDFs need to be exported as text-based PDFs first.',
        );
      }
      return result;
    } finally {
      document.dispose();
    }
  }

  String _extractDocx(Uint8List bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final file = archive.findFile('word/document.xml');
    if (file == null) {
      throw DocumentException(
        'That DOCX file appears to be missing its content.',
      );
    }
    final xml = utf8.decode(file.content as List<int>, allowMalformed: true);
    final text = xml
        .replaceAll(RegExp(r'</w:p>'), '\n')
        .replaceAll(RegExp(r'<w:tab[^>]*/>'), '\t')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.length < 40) {
      throw DocumentException('No readable text was found in that DOCX file.');
    }
    return text;
  }

  Future<Uint8List> buildResumePdf(Resume resume) async {
    final doc = pw.Document();
    final accent = switch (resume.template) {
      'Minimal' => PdfColor.fromHex('#111827'),
      'Executive' => PdfColor.fromHex('#1E3A5F'),
      _ => PdfColor.fromHex('#7057E8'),
    };
    final base = pw.TextStyle(
      fontSize: 10,
      color: PdfColor.fromHex('#374151'),
      lineSpacing: 2,
    );
    final titleStyle = pw.TextStyle(
      fontSize: 26,
      fontWeight: pw.FontWeight.bold,
      color: accent,
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(42, 38, 42, 38),
        build: (context) {
          final blocks = <pw.Widget>[
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(resume.fullName, style: titleStyle),
                      if (resume.targetRole.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          resume.targetRole,
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: accent,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (resume.email.isNotEmpty)
                      pw.Text(resume.email, style: base),
                    if (resume.phone.isNotEmpty)
                      pw.Text(resume.phone, style: base),
                    if (resume.location.isNotEmpty)
                      pw.Text(resume.location, style: base),
                    if (resume.linkedin.isNotEmpty)
                      pw.Text(resume.linkedin, style: base),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: accent, thickness: 1.4),
            if (resume.summary.trim().isNotEmpty) ...[
              pw.SizedBox(height: 10),
              _heading('PROFESSIONAL SUMMARY', accent),
              pw.SizedBox(height: 5),
              pw.Text(resume.summary, style: base),
            ],
            if (resume.skills.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _heading('SKILLS', accent),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 6,
                children: resume.skills
                    .map(
                      (skill) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F1EEFB'),
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          skill,
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (resume.experience.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _heading('EXPERIENCE', accent),
              pw.SizedBox(height: 4),
              ...resume.experience.map(
                (exp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              '${exp.role} · ${exp.company}',
                              style: pw.TextStyle(
                                fontSize: 10.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                          pw.Text(exp.dateRange, style: base),
                        ],
                      ),
                      if (exp.description.trim().isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        ...exp.description
                            .split('\n')
                            .where((line) => line.trim().isNotEmpty)
                            .map(
                              (line) => pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 1.5),
                                child: pw.Text(
                                  line.trim().startsWith('•')
                                      ? line.trim()
                                      : '• ${line.trim()}',
                                  style: base,
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (resume.education.isNotEmpty) ...[
              pw.SizedBox(height: 4),
              _heading('EDUCATION', accent),
              pw.SizedBox(height: 4),
              ...resume.education.map(
                (edu) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text(
                          '${edu.degree}${edu.field.isNotEmpty ? ' in ${edu.field}' : ''} · ${edu.school}',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.Text(edu.dateRange, style: base),
                    ],
                  ),
                ),
              ),
            ],
          ];
          return blocks;
        },
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
          ),
        ),
      ),
    );
    return doc.save();
  }

  Future<Uint8List> buildCoverLetterPdf({
    required String title,
    required String company,
    required String content,
    required String fullName,
    String email = '',
    String phone = '',
  }) async {
    final doc = pw.Document();
    final accent = PdfColor.fromHex('#7057E8');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(54, 54, 54, 54),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                fullName,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: accent,
                ),
              ),
              pw.Text(
                DateTime.now().year.toString(),
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            [email, phone].where((e) => e.trim().isNotEmpty).join('  •  '),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          pw.Divider(color: accent, thickness: 1.2),
          pw.SizedBox(height: 18),
          pw.Text(
            'Application for $title${company.trim().isEmpty ? '' : ' at $company'}',
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          ...content
              .split('\n')
              .map(
                (line) => pw.Text(
                  line,
                  style: const pw.TextStyle(fontSize: 11, lineSpacing: 4),
                ),
              ),
        ],
      ),
    );
    return doc.save();
  }

  Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  pw.Widget _heading(String text, PdfColor accent) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9.5,
        fontWeight: pw.FontWeight.bold,
        color: accent,
        letterSpacing: 1.1,
      ),
    );
  }
}
