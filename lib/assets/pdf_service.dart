import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
// EMPLOYEE MONTHLY SUMMARY MODEL
// ─────────────────────────────────────────
class EmpSummary {
  final String name;
  final String employeeId;
  int present = 0;
  int absent  = 0;
  int leave   = 0;
  int total   = 0;

  EmpSummary({required this.name, required this.employeeId});

  double get attendanceRate =>
      total == 0 ? 0 : (present / total * 100);
}

// ─────────────────────────────────────────
// MONTHLY REPORT PAGE
// ─────────────────────────────────────────
class MonthlyReportPage extends StatefulWidget {
  const MonthlyReportPage({super.key});
  @override
  State<MonthlyReportPage> createState() =>
      _MonthlyReportPageState();
}

class _MonthlyReportPageState
    extends State<MonthlyReportPage> {
  int  _selectedMonth = DateTime.now().month;
  int  _selectedYear  = DateTime.now().year;
  bool _loading       = false;
  bool _generating    = false;

  List<EmpSummary>   _summaries   = [];
  int _totalWorkingDays            = 0;

  // month names
  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December',
  ];
  static const _shortMonths = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  String get _monthLabel =>
      '${_months[_selectedMonth - 1]} $_selectedYear';

  @override
  void initState() {
    super.initState();
    _fetchMonthlyData();
  }

  // ── Fetch all daily records for the month ──
  Future<void> _fetchMonthlyData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() { _loading = true; _summaries = []; });

    try {
      // 1. How many days in selected month?
      final daysInMonth = DateUtils.getDaysInMonth(
          _selectedYear, _selectedMonth);

      // 2. Build all date keys for the month
      final dateKeys = List.generate(daysInMonth, (i) {
        final day = i + 1;
        return '$_selectedYear-'
            '${_selectedMonth.toString().padLeft(2, '0')}-'
            '${day.toString().padLeft(2, '0')}';
      });

      // 3. Fetch records for each day in parallel
      final futures = dateKeys.map((key) =>
          FirebaseFirestore.instance
              .collection('users').doc(uid).collection('attendance').doc(key).collection('records').get());

      final results = await Future.wait(futures);

      // 4. Build employee summary map
      final Map<String, EmpSummary> summaryMap = {};
      int workingDays = 0;

      for (final snap in results) {
        if (snap.docs.isEmpty) continue;
        workingDays++; // day has records = working day

        for (final doc in snap.docs) {
          final data       = doc.data();
          final empId      = data['employeeId'] ?? '';
          final name       = data['name']       ?? '';
          final status     = data['status']     ?? '';

          if (empId.isEmpty) continue;

          summaryMap[empId] ??=
              EmpSummary(name: name, employeeId: empId);

          summaryMap[empId]!.total++;
          switch (status) {
            case 'Present': summaryMap[empId]!.present++; break;
            case 'Absent':  summaryMap[empId]!.absent++;  break;
            case 'Leave':   summaryMap[empId]!.leave++;   break;
          }
        }
      }

      setState(() {
        _summaries = summaryMap.values.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        _totalWorkingDays = workingDays;
        _loading          = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Failed to load: $e', isError: true);
    }
  }

  // ── Month / Year picker ──────────────────
  void _showMonthPicker() {
    int tempMonth = _selectedMonth;
    int tempYear  = _selectedYear;

    showModalBottomSheet(
      context: context,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: C.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              const Text('Select Month & Year',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: C.tp)),
              const SizedBox(height: 20),

              // Year selector
              Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () =>
                        setModal(() => tempYear--),
                    icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: C.ts),
                  ),
                  Text('$tempYear',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: C.tp)),
                  IconButton(
                    onPressed: () {
                      if (tempYear < DateTime.now().year) {
                        setModal(() => tempYear++);
                      }
                    },
                    icon: Icon(
                      Icons.chevron_right_rounded,
                      color: tempYear < DateTime.now().year
                          ? C.ts
                          : C.tm,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Month grid
              GridView.builder(
                shrinkWrap: true,
                physics:
                const NeverScrollableScrollPhysics(),
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: 12,
                itemBuilder: (_, i) {
                  final m       = i + 1;
                  final sel     = m == tempMonth;
                  final isDisabled = tempYear ==
                      DateTime.now().year &&
                      m > DateTime.now().month;
                  return GestureDetector(
                    onTap: isDisabled
                        ? null
                        : () => setModal(() => tempMonth = m),
                    child: AnimatedContainer(
                      duration:
                      const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: sel
                            ? C.accent
                            : C.divider.withOpacity(0.5),
                        borderRadius:
                        BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _shortMonths[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDisabled
                              ? C.tm
                              : sel
                              ? Colors.white
                              : C.ts,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedMonth = tempMonth;
                      _selectedYear  = tempYear;
                    });
                    _fetchMonthlyData();
                  },
                  child: const Text('Apply',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grand totals ─────────────────────────
  int get _grandPresent =>
      _summaries.fold(0, (s, e) => s + e.present);
  int get _grandAbsent =>
      _summaries.fold(0, (s, e) => s + e.absent);
  int get _grandLeave =>
      _summaries.fold(0, (s, e) => s + e.leave);

  // ── Generate PDF ─────────────────────────
  Future<void> _generatePdf() async {
    if (_summaries.isEmpty) {
      _showSnack('No data to generate PDF!', isError: true);
      return;
    }
    setState(() => _generating = true);

    try {
      final pdf = pw.Document();

      // PDF colors
      final headerColor  = PdfColor.fromHex('3D7BFF');
      final presentColor = PdfColor.fromHex('2DD4A0');
      final absentColor  = PdfColor.fromHex('FF5A5A');
      final leaveColor   = PdfColor.fromHex('FFB347');
      final rowAlt       = PdfColor.fromHex('EEF2FF');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          header: (ctx) =>
              _pdfHeader(headerColor),
          footer: (ctx) =>
              _pdfFooter(ctx),
          build: (ctx) => [
            pw.SizedBox(height: 14),

            // ── Month info banner ──────────
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColor(0.24, 0.48, 1.0, 0.08),
                borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8)),
                border: pw.Border.all(
                    color: PdfColor(0.24, 0.48, 1.0, 0.3),
                    width: 0.5),
              ),
              child: pw.Row(
                mainAxisAlignment:
                pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment:
                    pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Monthly Report: $_monthLabel',
                          style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: headerColor)),
                      pw.SizedBox(height: 2),
                      pw.Text(
                          'Working Days Recorded: '
                              '$_totalWorkingDays',
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColor.fromHex(
                                  '5A5A7A'))),
                    ],
                  ),
                  pw.Text(
                    'Total Employees: ${_summaries.length}',
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: headerColor),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── Grand summary cards ────────
            pw.Row(children: [
              _pdfSummaryCard(
                  '${_summaries.length}',
                  'Employees',
                  headerColor),
              pw.SizedBox(width: 8),
              _pdfSummaryCard(
                  '$_grandPresent',
                  'Total Present',
                  presentColor),
              pw.SizedBox(width: 8),
              _pdfSummaryCard(
                  '$_grandAbsent',
                  'Total Absent',
                  absentColor),
              pw.SizedBox(width: 8),
              _pdfSummaryCard(
                  '$_grandLeave',
                  'Total Leave',
                  leaveColor),
              pw.SizedBox(width: 8),
              _pdfSummaryCard(
                  '$_totalWorkingDays',
                  'Working Days',
                  PdfColor.fromHex('B47FFF')),
            ]),
            pw.SizedBox(height: 18),

            // ── Table heading ──────────────
            pw.Text('Employee Attendance Summary',
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('1A1A2E'))),
            pw.SizedBox(height: 8),

            // ── Main table ────────────────
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('E0E0F0'),
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FixedColumnWidth(28),  // #
                1: const pw.FlexColumnWidth(2.8),  // Name
                2: const pw.FlexColumnWidth(1.6),  // ID
                3: const pw.FixedColumnWidth(52),  // Present
                4: const pw.FixedColumnWidth(48),  // Absent
                5: const pw.FixedColumnWidth(44),  // Leave
                6: const pw.FixedColumnWidth(44),  // Total
                7: const pw.FixedColumnWidth(54),  // Rate
              },
              children: [
                // Header
                pw.TableRow(
                  decoration:
                  pw.BoxDecoration(color: headerColor),
                  children: [
                    _th('#'),
                    _th('Employee Name'),
                    _th('ID'),
                    _th('Present'),
                    _th('Absent'),
                    _th('Leave'),
                    _th('Total'),
                    _th('Rate %'),
                  ],
                ),
                // Data rows
                ..._summaries.asMap().entries.map((e) {
                  final i   = e.key;
                  final emp = e.value;
                  final isEven = i % 2 == 0;
                  final rate =
                  emp.attendanceRate.toStringAsFixed(1);

                  // Rate color
                  PdfColor rateColor;
                  if (emp.attendanceRate >= 80) {
                    rateColor = presentColor;
                  } else if (emp.attendanceRate >= 50) {
                    rateColor = leaveColor;
                  } else {
                    rateColor = absentColor;
                  }

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven
                          ? PdfColors.white
                          : rowAlt,
                    ),
                    children: [
                      _td('${i + 1}',
                          center: true,
                          color: PdfColor.fromHex('9898B0')),
                      _td(emp.name, bold: true),
                      _td(emp.employeeId,
                          color: headerColor, bold: true),
                      _tdColored(
                          '${emp.present}', presentColor),
                      _tdColored('${emp.absent}', absentColor),
                      _tdColored('${emp.leave}', leaveColor),
                      _td('${emp.total}',
                          center: true,
                          bold: true,
                          color: PdfColor.fromHex('1A1A2E')),
                      _tdRate('$rate%', rateColor),
                    ],
                  );
                }),

                // ── Grand total row ──────
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('1A2A50'),
                  ),
                  children: [
                    _th(''),
                    _th('TOTAL'),
                    _th(''),
                    _thColored(
                        '$_grandPresent', presentColor),
                    _thColored(
                        '$_grandAbsent', absentColor),
                    _thColored(
                        '$_grandLeave', leaveColor),
                    _th('${_grandPresent + _grandAbsent + _grandLeave}'),
                    _th(''),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // ── Legend ────────────────────
            pw.Row(
              children: [
                pw.Text('Legend:  ',
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('5A5A7A'))),
                _legendDot(presentColor, 'Present'),
                pw.SizedBox(width: 10),
                _legendDot(absentColor, 'Absent'),
                pw.SizedBox(width: 10),
                _legendDot(leaveColor, 'Leave'),
                pw.SizedBox(width: 10),
                _legendDot(
                    PdfColor.fromHex('2DD4A0'), ">80% Good"),
                pw.SizedBox(width: 10),
                _legendDot(
                    PdfColor.fromHex('FFB347'), '50 79% Average'),
                pw.SizedBox(width: 10),
                _legendDot(
                    PdfColor.fromHex('FF5A5A'), '<50% Poor'),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── Footer note ───────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(

                color: PdfColor.fromHex('F4F6FB'),
                borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6)),
              ),
              child: pw.Text(
                'This monthly report was auto-generated from '
                    'the AttendyPro Attendance System. '
                    'Rate % = (Present / Total Days Recorded) × 100.',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromHex('9898B0'),
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );

      setState(() => _generating = false);

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: 'Monthly_Attendance_${_months[_selectedMonth - 1]}_$_selectedYear.pdf',
      );
    } catch (e) {
      setState(() => _generating = false);
      _showSnack('PDF generation failed: $e', isError: true);
    }
  }

  // ── PDF widgets ──────────────────────────
  pw.Widget _pdfHeader(PdfColor hColor) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(
              bottom:
              pw.BorderSide(color: hColor, width: 2)),
        ),
        child: pw.Row(
          mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Attendance-Monthly Report by AttendyPro',
                    style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: hColor)),
                pw.SizedBox(height: 2),
                pw.Text(
                  _monthLabel,
                  style: pw.TextStyle(
                      fontSize: 10,
                      color:
                      PdfColor.fromHex('9898B0')),
                ),
              ],
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                color: hColor,
                borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(6)),
              ),
              child: pw.Text('MONTHLY SUMMARY',
                  style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 0.8)),
            ),
          ],
        ),
      );

  pw.Widget _pdfFooter(pw.Context ctx) =>
      pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              top: pw.BorderSide(
                  color: PdfColors.grey300, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment:
          pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(' Attendance System — AttendyPro',
                style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex('9898B0'))),
            pw.Text(
                'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
                style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColor.fromHex('9898B0'))),
          ],
        ),
      );

  pw.Widget _pdfSummaryCard(
      String val, String label, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(
              vertical: 8, horizontal: 6),
          decoration: pw.BoxDecoration(
            color: PdfColor(color.red, color.green,
                color.blue, 0.1),
            borderRadius: const pw.BorderRadius.all(
                pw.Radius.circular(6)),
            border: pw.Border.all(
                color: PdfColor(color.red, color.green,
                    color.blue, 0.25),
                width: 0.5),
          ),
          child: pw.Column(
            children: [
              pw.Text(val,
                  style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: color)),
              pw.SizedBox(height: 2),
              pw.Text(label,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                      fontSize: 8,
                      color:
                      PdfColor.fromHex('5A5A7A'))),
            ],
          ),
        ),
      );

  // Table helpers
  pw.Widget _th(String t) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(
        horizontal: 5, vertical: 7),
    child: pw.Text(t,
        style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white),
        textAlign: pw.TextAlign.center),
  );

  pw.Widget _thColored(String t, PdfColor c) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
            horizontal: 5, vertical: 7),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: c),
            textAlign: pw.TextAlign.center),
      );

  pw.Widget _td(String t,
      {bool center = false,
        PdfColor? color,
        bool bold = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
            horizontal: 5, vertical: 6),
        child: pw.Text(t,
            style: pw.TextStyle(
                fontSize: 9,
                color: color ??
                    PdfColor.fromHex('1A1A2E'),
                fontWeight: bold
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal),
            textAlign: center
                ? pw.TextAlign.center
                : pw.TextAlign.left),
      );

  pw.Widget _tdColored(String t, PdfColor c) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
            horizontal: 4, vertical: 5),
        child: pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 4, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColor(
                c.red, c.green, c.blue, 0.15),
            borderRadius: const pw.BorderRadius.all(
                pw.Radius.circular(3)),
          ),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: c),
              textAlign: pw.TextAlign.center),
        ),
      );

  pw.Widget _tdRate(String t, PdfColor c) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(
            horizontal: 4, vertical: 5),
        child: pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(
              horizontal: 4, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColor(
                c.red, c.green, c.blue, 0.15),
            borderRadius: const pw.BorderRadius.all(
                pw.Radius.circular(3)),
          ),
          child: pw.Text(t,
              style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: c),
              textAlign: pw.TextAlign.center),
        ),
      );

  pw.Widget _legendDot(PdfColor c, String label) =>
      pw.Row(
        children: [
          pw.Container(
            width: 8, height: 8,
            decoration: pw.BoxDecoration(
              color: c,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 3),
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 8,
                  color:
                  PdfColor.fromHex('5A5A7A'))),
        ],
      );

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? C.red : C.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: C.ts,
              size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Monthly Report',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: C.tp)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: C.ts, size: 22),
            onPressed: _fetchMonthlyData,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Month selector ───────────────
          GestureDetector(
            onTap: _showMonthPicker,
            child: Container(
              margin:
              const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: C.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: C.accent.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: C.accent.withOpacity(0.12),
                      borderRadius:
                      BorderRadius.circular(8),
                    ),
                    child: const Icon(
                        Icons.calendar_month_rounded,
                        color: C.accent,
                        size: 16),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(_monthLabel,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: C.tp)),
                      const SizedBox(height: 2),
                      const Text('Tap to change month',
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
                      borderRadius:
                      BorderRadius.circular(20),
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
                                fontWeight:
                                FontWeight.w700)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Grand stats ──────────────────
          if (!_loading && _summaries.isNotEmpty) ...[
            Padding(
              padding:
              const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  _chip('${_summaries.length}',
                      'Employees', C.accent),
                  const SizedBox(width: 8),
                  _chip('$_grandPresent', 'Present',
                      C.green),
                  const SizedBox(width: 8),
                  _chip('$_grandAbsent', 'Absent', C.red),
                  const SizedBox(width: 8),
                  _chip('$_grandLeave', 'Leave', C.amber),
                ],
              ),
            ),
            Padding(
              padding:
              const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: C.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: C.divider),
                ),
                child: Row(
                  children: [
                    const Icon(
                        Icons.work_history_rounded,
                        color: C.ts,
                        size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Working days recorded: $_totalWorkingDays',
                      style: const TextStyle(
                          fontSize: 12,
                          color: C.ts,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // ── Table / Loading / Empty ───────
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(
                    color: C.accent))
                : _summaries.isEmpty
                ? _buildEmpty()
                : _buildPreviewTable(),
          ),
        ],
      ),

      // ── Generate PDF button ──────────────
      bottomNavigationBar: Container(
        padding:
        const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: C.card,
          border:
          Border(top: BorderSide(color: C.divider)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: GestureDetector(
            onTap: _generating || _summaries.isEmpty
                ? null
                : _generatePdf,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                gradient: _summaries.isEmpty
                    ? null
                    : const LinearGradient(
                  colors: [
                    Color(0xFF3D7BFF),
                    Color(0xFF1A4FCC)
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                color: _summaries.isEmpty
                    ? C.divider
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _summaries.isEmpty
                    ? null
                    : [
                  BoxShadow(
                    color: C.accent.withOpacity(0.4),
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
                      color: _summaries.isEmpty
                          ? C.tm
                          : Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _summaries.isEmpty
                          ? 'No Data Available'
                          : 'Generate Monthly PDF',
                      style: TextStyle(
                        color: _summaries.isEmpty
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

  // ── Stat chip ────────────────────────────
  Widget _chip(String val, String label, Color color) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border:
            Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Text(val,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
              Text(label,
                  style: const TextStyle(
                      fontSize: 9, color: C.ts)),
            ],
          ),
        ),
      );

  // ── Flutter preview table ─────────────────
  Widget _buildPreviewTable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: C.accent,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 28,
                    child: Text('#',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center)),
                Expanded(flex: 3,
                    child: Text('Employee Name',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                SizedBox(width: 60,
                    child: Text('Present',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center)),
                SizedBox(width: 54,
                    child: Text('Absent',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center)),
                SizedBox(width: 48,
                    child: Text('Leave',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center)),
                SizedBox(width: 52,
                    child: Text('Rate',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center)),
              ],
            ),
          ),

          // Table rows
          ..._summaries.asMap().entries.map((e) {
            final i   = e.key;
            final emp = e.value;
            final isEven = i % 2 == 0;

            Color rateColor;
            if (emp.attendanceRate >= 80) {
              rateColor = C.green;
            } else if (emp.attendanceRate >= 50) {
              rateColor = C.amber;
            } else {
              rateColor = C.red;
            }

            return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                decoration: BoxDecoration(
                  color: isEven
                      ? C.card
                      : const Color(0xFF232340),
                  border: Border(
                      bottom: BorderSide(
                          color: C.divider, width: 0.5)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              color: C.ts, fontSize: 11),
                          textAlign: TextAlign.center),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(emp.name,
                              style: const TextStyle(
                                  color: C.tp,
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w700)),
                          Text(emp.employeeId,
                              style: const TextStyle(
                                  color: C.accent,
                                  fontSize: 10,
                                  fontWeight:
                                  FontWeight.w600)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: _statusBadge(
                          '${emp.present}', C.green),
                    ),
                    SizedBox(
                      width: 54,
                      child: _statusBadge(
                          '${emp.absent}', C.red),
                    ),
                    SizedBox(
                      width: 48,
                      child: _statusBadge(
                          '${emp.leave}', C.amber),
                    ),
                    SizedBox(
                      width: 52,
                      child: _statusBadge(
                          '${emp.attendanceRate.toStringAsFixed(0)}%',
                          rateColor),
                    ),
                  ],
                ),);
            }),

          // Grand total row
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: C.accent.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14)),
              border:
              Border.all(color: C.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 28),
                const Expanded(
                  flex: 3,
                  child: Text('GRAND TOTAL',
                      style: TextStyle(
                          color: C.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
                SizedBox(
                  width: 60,
                  child: Text('$_grandPresent',
                      style: const TextStyle(
                          color: C.green,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 54,
                  child: Text('$_grandAbsent',
                      style: const TextStyle(
                          color: C.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                ),
                SizedBox(
                  width: 48,
                  child: Text('$_grandLeave',
                      style: const TextStyle(
                          color: C.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.w800),
                      textAlign: TextAlign.center),
                ),
                const SizedBox(width: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String val, Color color) =>
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border:
            Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(val,
              style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.w700)),
        ),
      );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.bar_chart_rounded,
            color: C.tm, size: 56),
        const SizedBox(height: 14),
        const Text(
          'No attendance records found\nfor this month.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: C.ts, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _showMonthPicker,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: C.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: C.accent.withOpacity(0.3)),
            ),
            child: const Text('Choose Another Month',
                style: TextStyle(
                    color: C.accent,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ),
  );
}