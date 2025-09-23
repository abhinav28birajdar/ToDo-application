import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PDFService {
  static Future<Uint8List> generateUserProfilePDF({
    required String userName,
    required String userEmail,
    required String? userPhone,
    required DateTime memberSince,
    required int totalTasks,
    required int completedTasks,
    required int pendingTasks,
  }) async {
    final pdf = pw.Document();

    // Get current date for the report
    final now = DateTime.now();
    final dateFormat = DateFormat('MMM dd, yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        color: PdfColors.blue,
                        width: 2,
                      ),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Pro-Organizer',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'User Profile Report',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.normal,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated on ${dateFormat.format(now)}',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // User Information Section
                pw.Text(
                  'User Information',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),

                pw.SizedBox(height: 16),

                // User details in a table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    _buildTableRow('Full Name', userName),
                    _buildTableRow('Email Address', userEmail),
                    _buildTableRow('Phone Number', userPhone ?? 'Not provided'),
                    _buildTableRow(
                        'Member Since', dateFormat.format(memberSince)),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Task Statistics Section
                pw.Text(
                  'Task Statistics',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.black,
                  ),
                ),

                pw.SizedBox(height: 16),

                // Statistics cards
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildStatCard(
                        'Total Tasks',
                        totalTasks.toString(),
                        PdfColors.blue,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: _buildStatCard(
                        'Completed',
                        completedTasks.toString(),
                        PdfColors.green,
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      child: _buildStatCard(
                        'Pending',
                        pendingTasks.toString(),
                        PdfColors.orange,
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Completion rate
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Task Completion Rate',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        totalTasks > 0
                            ? '${((completedTasks / totalTasks) * 100).toStringAsFixed(1)}%'
                            : '0%',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Footer
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 1,
                      ),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'This report was generated automatically by Pro-Organizer',
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return await pdf.save();
  }

  static pw.TableRow _buildTableRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          color: PdfColors.grey50,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatCard(String title, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> printPDF(Uint8List pdfData) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
    );
  }

  static Future<String> savePDF(Uint8List pdfData, String fileName) async {
    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/$fileName");
    await file.writeAsBytes(pdfData);
    return file.path;
  }
}
