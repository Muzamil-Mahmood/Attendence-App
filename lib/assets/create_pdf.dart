import 'package:attendec/assets/pdf_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../pages/add_memeber.dart';

// ─────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────
class C {
  static const bg      = Color(0xFF12121F);
  static const card    = Color(0xFF1E1E30);
  static const accent  = Color(0xFF3D7BFF);
  static const green   = Color(0xFF2DD4A0);
  static const red     = Color(0xFFFF5A5A);
  static const amber   = Color(0xFFFFB347);
  static const divider = Color(0xFF2A2A42);
  static const tp      = Color(0xFFFFFFFF);
  static const ts      = Color(0xFF9898B0);
  static const tm      = Color(0xFF5A5A7A);
}

// ─────────────────────────────────────────
// ATTENDANCE REPORT PAGE
// ─────────────────────────────────────────
class AttendanceReportPage extends StatefulWidget {
  const AttendanceReportPage({super.key});
  @override
  State<AttendanceReportPage> createState() =>
      _AttendanceReportPageState();
}

class _AttendanceReportPageState
    extends State<AttendanceReportPage> {
  DateTime _selectedDate = DateTime.now();
  bool _loading          = false;
  bool _generating       = false;
  List<Map<String, dynamic>> _records = [];
  Map<String, dynamic>? _summary;

  // ── Date key ────────────────────────────
  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  String _fmtDate(DateTime d) {
    const m = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December'
    ];
    const wd = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${wd[d.weekday - 1]}, ${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _fmtShort(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // ── Fetch attendance records ─────────────
// ── Fetch attendance records ─────────────
  Future<void> _fetchData() async {
    setState(() { _loading = true; _records = []; _summary = null; });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Fetch summary doc — scoped to user
      final summaryDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('attendance')
          .doc(_dateKey)
          .get();

      if (summaryDoc.exists) {
        _summary = summaryDoc.data();
      }

      // Fetch records sub-collection ordered by row
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('attendance')
          .doc(_dateKey)
          .collection('records')
          .orderBy('row')
          .get();

      setState(() {
        _records = snap.docs.map((d) => d.data()).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Failed to load: $e', isError: true);
    }
  }

  // ── Date picker ──────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: C.accent,
            surface: C.card,
            onSurface: C.tp,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _fetchData();
    }
  }

  // ── Generate & Preview PDF ───────────────
  Future<void> _generatePdf() async {
    if (_records.isEmpty) {
      _showSnack('No data to generate PDF!', isError: true);
      return;
    }
    setState(() => _generating = true);

    try {
      final pdf = pw.Document();

      // PDF color helpers
      final headerColor  = PdfColor.fromHex('3D7BFF');
      final presentColor = PdfColor.fromHex('2DD4A0');
      final absentColor  = PdfColor.fromHex('FF5A5A');
      final leaveColor   = PdfColor.fromHex('FFB347');
      final bgColor      = PdfColor.fromHex('F4F6FB');
      final rowAlt       = PdfColor.fromHex('EEF2FF');

      // Stats
      final totalPresent = _records
          .where((r) => r['status'] == 'Present')
          .length;
      final totalAbsent = _records
          .where((r) => r['status'] == 'Absent')
          .length;
      final totalLeave = _records
          .where((r) => r['status'] == 'Leave')
          .length;
      final total = _records.length;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => _buildPdfHeader(
              _fmtDate(_selectedDate), headerColor),
          footer: (ctx) => _buildPdfFooter(ctx),
          build: (ctx) => [
            pw.SizedBox(height: 16),

            // ── Summary cards ──────────────
            _buildSummaryRow(
              total, totalPresent, totalAbsent, totalLeave,
              presentColor, absentColor, leaveColor, headerColor,
            ),
            pw.SizedBox(height: 20),

            // ── Table title ────────────────
            pw.Text(
              'Attendance Details',
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('1A1A2E'),
              ),
            ),
            pw.SizedBox(height: 8),

            // ── Attendance table ───────────
            _buildTable(
              _records,
              headerColor,
              presentColor,
              absentColor,
              leaveColor,
              bgColor,
              rowAlt,
            ),
            pw.SizedBox(height: 16),

            // ── Footer note ────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('EEF2FF'),
                borderRadius:
                const pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'This report was auto-generated from the AttendyPro System on '
                    '${_fmtShort(DateTime.now())}.',
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColor.fromHex('5A5A7A'),
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );

      setState(() => _generating = false);

      // Open print/share preview
      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name:
        'Attendance_Report_$_dateKey.pdf',
      );
    } catch (e) {
      setState(() => _generating = false);
      _showSnack('Failed to generate PDF: $e', isError: true);
    }
  }

  // ── PDF Header ───────────────────────────
  pw.Widget _buildPdfHeader(
      String date, PdfColor headerColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
              color: headerColor, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment:
            pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Daily Attendance Report  By AttendyPro',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: headerColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                date,
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColor.fromHex('9898B0'),
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: headerColor,
              borderRadius: const pw.BorderRadius.all(
                  pw.Radius.circular(6)),
            ),
            child: pw.Text(
              'OFFICIAL DOCUMENT',
              style: pw.TextStyle(
                fontSize: 8,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── PDF Footer ───────────────────────────
  pw.Widget _buildPdfFooter(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
              color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment:
        pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'HR Attendance System',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('9898B0'),
            ),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('9898B0'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary Row ──────────────────────────
  pw.Widget _buildSummaryRow(
      int total,
      int present,
      int absent,
      int leave,
      PdfColor presentColor,
      PdfColor absentColor,
      PdfColor leaveColor,
      PdfColor accentColor,
      ) {
    return pw.Row(
      children: [
        _summaryCard('Total', '$total',
            accentColor),
        pw.SizedBox(width: 8),
        _summaryCard('Present', '$present',
            presentColor),
        pw.SizedBox(width: 8),
        _summaryCard('Absent', '$absent',
            absentColor),
        pw.SizedBox(width: 8),
        _summaryCard('Leave', '$leave',
            leaveColor),
      ],
    );
  }

  pw.Widget _summaryCard(
      String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(
            vertical: 10, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: PdfColor(
            color.red,
            color.green,
            color.blue,
            0.12,
          ),
          borderRadius: const pw.BorderRadius.all(
              pw.Radius.circular(8)),
          border: pw.Border.all(
            color: PdfColor(
              color.red,
              color.green,
              color.blue,
              0.3,
            ),
            width: 0.5,
          ),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColor.fromHex('5A5A7A'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Attendance Table ─────────────────────
  pw.Widget _buildTable(
      List<Map<String, dynamic>> records,
      PdfColor headerColor,
      PdfColor presentColor,
      PdfColor absentColor,
      PdfColor leaveColor,
      PdfColor bgColor,
      PdfColor rowAlt,
      ) {
    PdfColor statusColor(String status) {
      switch (status) {
        case 'Present': return presentColor;
        case 'Absent':  return absentColor;
        case 'Leave':   return leaveColor;
        default:        return PdfColor.fromHex('9898B0');
      }
    }

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColor.fromHex('E0E0F0'),
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FixedColumnWidth(36),   // #
        1: const pw.FlexColumnWidth(3),     // Name
        2: const pw.FlexColumnWidth(2),     // Employee ID
        3: const pw.FlexColumnWidth(1.5),   // Status
        4: const pw.FlexColumnWidth(1.5),   // Date
      },
      children: [
        // ── Header row ──────────────────
        pw.TableRow(
          decoration: pw.BoxDecoration(color: headerColor),
          children: [
            _tableHeader('#'),
            _tableHeader('Name'),
            _tableHeader('Employee ID'),
            _tableHeader('Status'),
            _tableHeader('Date'),
          ],
        ),
        // ── Data rows ───────────────────
        ...records.asMap().entries.map((entry) {
          final i      = entry.key;
          final record = entry.value;
          final status = record['status'] ?? '—';
          final isEven = i % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : rowAlt,
            ),
            children: [
              // Row number
              _tableCell(
                '${record['row'] ?? i + 1}',
                align: pw.TextAlign.center,
                color: PdfColor.fromHex('9898B0'),
              ),
              // Name
              _tableCell(record['name'] ?? '—'),
              // Employee ID
              _tableCell(
                record['employeeId'] ?? '—',
                isBold: true,
                color: headerColor,
              ),
              // Status (colored badge-like)
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 6, vertical: 6),
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(
                      statusColor(status).red,
                      statusColor(status).green,
                      statusColor(status).blue,
                      0.15,
                    ),
                    borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    status,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: statusColor(status),
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
              // Date
              _tableCell(
                record['date'] ?? _dateKey,
                color: PdfColor.fromHex('5A5A7A'),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableHeader(String text) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(
        horizontal: 8, vertical: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );

  pw.Widget _tableCell(
      String text, {
        pw.TextAlign align = pw.TextAlign.left,
        PdfColor? color,
        bool isBold = false,
      }) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
            horizontal: 8, vertical: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            color: color ?? PdfColor.fromHex('1A1A2E'),
            fontWeight: isBold
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          ),
          textAlign: align,
        ),
      );

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? C.red : C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final present =
        _records.where((r) => r['status'] == 'Present').length;
    final absent =
        _records.where((r) => r['status'] == 'Absent').length;
    final leave =
        _records.where((r) => r['status'] == 'Leave').length;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: C.ts, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Daily Report',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: C.tp)),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const MonthlyReportPage())),
            child:Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3D7BFF),
                    Color(0xFF1A4FCC)
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.download,
                      color: Colors.white, size: 14),
                  SizedBox(width: 1),
                  Text('Monthly',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),

        ],
      ),
      body: Column(
        children: [
          // ── Date picker bar ──────────────
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: C.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: C.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                        Icons.calendar_today_rounded,
                        color: C.accent,
                        size: 16),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(_fmtDate(_selectedDate),
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: C.tp)),
                      const SizedBox(height: 2),
                      const Text('Tap to change date',
                          style: TextStyle(
                              fontSize: 10, color: C.ts)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: C.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.edit_calendar_rounded,
                            color: C.accent, size: 13),
                        SizedBox(width: 4),
                        Text('Change',
                            style: TextStyle(
                                fontSize: 11,
                                color: C.accent,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Stats row ────────────────────
          if (_records.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _statChip('${_records.length}', 'Total',
                      C.accent),
                  const SizedBox(width: 10),
                  _statChip('$present', 'Present', C.green),
                  const SizedBox(width: 10),
                  _statChip('$absent', 'Absent', C.red),
                  const SizedBox(width: 10),
                  _statChip('$leave', 'Leave', C.amber),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Table / Empty / Loading ───────
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: C.accent))
                : _records.isEmpty
                ? _buildEmpty()
                : buildTable(),
          ),
        ],
      ),

      // ── Generate PDF button ──────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: C.card,
          border: Border(top: BorderSide(color: C.divider)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: GestureDetector(
            onTap: _generating || _records.isEmpty
                ? null
                : _generatePdf,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: _records.isEmpty
                    ? null
                    : const LinearGradient(
                  colors: [
                    Color(0xFF3D7BFF),
                    Color(0xFF1A4FCC)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                color: _records.isEmpty ? C.divider : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _records.isEmpty
                    ? null
                    : [
                  BoxShadow(
                    color:
                    C.accent.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: _generating
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5),
                )
                    : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf_rounded,
                      color: _records.isEmpty
                          ? C.tm
                          : Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _records.isEmpty
                          ? 'No Data Available'
                          : 'Generate & Download PDF',
                      style: TextStyle(
                        color: _records.isEmpty
                            ? C.tm
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Stats chip ───────────────────────────
  Widget _statChip(
      String val, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(val,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: C.ts)),
            ],
          ),
        ),
      );

  // ── Flutter table preview ────────────────
  Widget buildTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: DataTable(
            headingRowColor:
            WidgetStateProperty.all(C.accent),
            headingTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            dataRowColor: WidgetStateProperty.resolveWith(
                  (states) => C.card,
            ),
            dividerThickness: 0.5,
            columnSpacing: 20,
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Employee ID')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Date')),
            ],
            rows: _records.asMap().entries.map((entry) {
              final i      = entry.key;
              final record = entry.value;
              final status = record['status'] ?? '—';

              Color statusColor;
              switch (status) {
                case 'Present':
                  statusColor = C.green;
                  break;
                case 'Absent':
                  statusColor = C.red;
                  break;
                case 'Leave':
                  statusColor = C.amber;
                  break;
                default:
                  statusColor = C.tm;
              }

              return DataRow(
                cells: [
                  DataCell(Text(
                    '${record['row'] ?? i + 1}',
                    style: const TextStyle(
                        color: C.ts, fontSize: 12),
                  )),
                  DataCell(Text(
                    record['name'] ?? '—',
                    style: const TextStyle(
                        color: C.tp,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  )),
                  DataCell(Text(
                    record['employeeId'] ?? '—',
                    style: const TextStyle(
                        color: C.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  )),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                          statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700),
                    ),
                  )),
                  DataCell(Text(
                    record['date'] ?? _dateKey,
                    style: const TextStyle(
                        color: C.ts, fontSize: 11),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ── Empty state ──────────────────────────
  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.description_outlined,
            color: C.tm, size: 56),
        const SizedBox(height: 14),
        const Text('No attendance records found\nfor this date.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: C.ts, fontSize: 14, height: 1.6)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: C.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: C.accent.withOpacity(0.3)),
            ),
            child: const Text('Choose Another Date',
                style: TextStyle(
                    color: C.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );
}