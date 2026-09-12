import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/chart_page.dart';
import 'package:msw_eplant/services/cems_threshold_service.dart';

Widget buildDataView(
  BuildContext context,
  List<String> header,
  List record,
  List<dynamic> fullData,
  int selectedIndex,
  String formattedDate,
) {
  String unitName = selectedIndex == 0 ? "Unit 1" : "Unit 2";
  bool isShutdown = false;
  // cek load
  double? loadValue;
  try {
    int loadIndex = header.indexOf("LOAD");
    if (loadIndex != -1) {
      loadValue = double.tryParse(record[loadIndex].toString());
    }
  } catch (_) {}
  try {
    // ambil index kolom datetime & load
    int dateIndex = header.indexOf("DATETIME");
    int loadIndex = header.indexOf("LOAD");

    if (dateIndex != -1 && loadIndex != -1 && fullData.isNotEmpty) {
      // ambil data pertama, tengah, dan terakhir
      var lastRecord = fullData.last;
      var middleRecord = fullData[fullData.length ~/ 1.2];

      // parse datetime
      DateTime? lastDate = DateTime.tryParse(lastRecord[dateIndex].toString());
      DateTime? middleDate = DateTime.tryParse(middleRecord[dateIndex].toString());

      // parse load
      double? lastLoad = double.tryParse(lastRecord[loadIndex].toString());
      double? middleLoad = double.tryParse(middleRecord[loadIndex].toString());

      // cek kondisi
      if (lastDate != null && middleDate != null && lastLoad != null && middleLoad != null) {
        // jika sama-sama < 1, berarti unit shutdown reserve
        if (lastLoad < 1 && middleLoad < 1) {
          isShutdown = true;
        }
      }
    }
  } catch (e) {
    debugPrint("Error cek shutdown: $e");
  }
  return Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (loadValue != null && loadValue < 2 && !isShutdown)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.text),
                const SizedBox(width: 8),
                Text(
                  "Alarm: $unitName Trip",
                  style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.bold, color: AppColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        if (isShutdown)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.text),
                const SizedBox(width: 8),
                Text(
                  "Info: $unitName Reserve Shutdown",
                  style: const TextStyle(fontSize: AppTheme.fs14, fontWeight: FontWeight.bold, color: AppColors.text),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Expanded(
        //       child: Text(
        //             unitName,
        //               maxLines: 2,
        //               overflow: TextOverflow.ellipsis,
        //               style: Theme.of(context).textTheme.headlineSmall,
        //       ),
        //     ),

        //   ],
        // ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSub),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "$formattedDate",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: AppTheme.fs13, fontWeight: FontWeight.w500, color: AppColors.text),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(
                "${header.length - 1} Parameters",
                style: const TextStyle(
                  fontSize: AppTheme.fs12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: header.length - 1,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              String colName = header[index + 1];
              String value = record[index + 1].toString();
              String unit = getUnit(colName);
              final threshold = CemsThresholdService.getThreshold(colName);

              String? rawDate;
              int dateIdx = header.indexOf("DATETIME");
              if (dateIdx != -1 && dateIdx < record.length) {
                rawDate = record[dateIdx].toString();
              }
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChartPage(
                          columnName: colName,
                          columnIndex: index + 1,
                          header: header,
                          fullData: fullData,
                          unit: unit,
                          date: formattedDate,
                          thresholdValue: threshold?.max,
                        ),
                      ),
                    );
                  },
                  child: buildDataCard(colName, value, unit, lastUpdate: rawDate),
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

class DataCardWidget extends StatefulWidget {
  final String title;
  final String value;
  final String unit;
  final String? lastUpdate;

  const DataCardWidget({super.key, required this.title, required this.value, required this.unit, this.lastUpdate});

  @override
  State<DataCardWidget> createState() => _DataCardWidgetState();
}

class _DataCardWidgetState extends State<DataCardWidget> {
  int _decimalPlaces = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int val = prefs.getInt('decimal_places') ?? 1;
      if (val != _decimalPlaces && mounted) {
        setState(() {
          _decimalPlaces = val;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    double? numValue = double.tryParse(widget.value);
    String displayValue = numValue != null ? numValue.toStringAsFixed(_decimalPlaces) : widget.value;
    final threshold = CemsThresholdService.getThreshold(widget.title);
    final bool isExceed =
        numValue != null && threshold != null && !CemsThresholdService.isCompliant(widget.title, numValue);
    final Color borderColor = isExceed ? AppColors.danger.withValues(alpha: 0.5) : AppColors.border;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isExceed ? 1.5 : 1),
      ),
      child: Row(
        children: [
          // Parameter Title + Limit info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTheme.fs13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                    height: 1.25,
                  ),
                ),
                if (threshold != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Limit: ${threshold.max.toStringAsFixed(0)} ${widget.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppTheme.fs11,
                      fontWeight: FontWeight.w500,
                      color: isExceed ? AppColors.danger : AppColors.textDim,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Reading Value + Unit + Optional EXCEED badge
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 125),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: AppTheme.fs20,
                          fontWeight: FontWeight.w800,
                          color: isExceed ? AppColors.danger : AppColors.text,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (widget.unit.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          widget.unit,
                          style: const TextStyle(
                            fontSize: AppTheme.fs13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSub,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isExceed) ...[
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'EXCEED',
                        style: TextStyle(
                          fontSize: AppTheme.fs11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.danger,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildDataCard(String title, String value, String unit, {String? lastUpdate}) {
  return DataCardWidget(title: title, value: value, unit: unit, lastUpdate: lastUpdate);
}

String formatDateTime(String raw) {
  try {
    DateTime dt = DateTime.parse(raw).toLocal();
    return DateFormat("dd MMM yyyy, HH:mm").format(dt);
  } catch (e) {
    return raw;
  }
}

String getUnit(String header) {
  String h = header.toUpperCase();
  if (h.contains("LOAD")) {
    return "MW";
  } else if (h.contains("TEMPERATURE")) {
    return "°C";
  } else if (h.contains("PRESSURE")) {
    return "Bar";
  } else if ((h.contains("FLOW")) || (h.contains("AIR"))) {
    return "T/h";
  } else if (h.contains("SO2")) {
    return "mg/Nm3";
  } else if (h.contains("NOX") || h.contains("HG") || h.contains("PARTICULATE")) {
    return "mg/Nm3";
  } else if (h.contains("CO")) {
    return "%";
  } else if (h.contains("O2")) {
    return "%";
  } else {
    return "";
  }
}
