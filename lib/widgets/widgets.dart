import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:msw_eplant/constants/theme.dart';
import 'package:msw_eplant/pages/chart_page.dart';
import 'package:msw_eplant/pages/nphr_page.dart';
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
            child: Text(
              "⚠️ Alarm: $unitName Trip",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text),
              textAlign: TextAlign.center,
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
            child: Text(
              "ℹ️ Info: $unitName Reserve Shutdown",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text),
              textAlign: TextAlign.center,
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Last Update: $formattedDate",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSub),
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary, width: 2),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              ),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const NphrPage())),
              child: const Text("NPHR", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            itemCount: header.length - 1,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
            ),
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
              return GestureDetector(
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

  bool _isUpToDate() {
    if (widget.lastUpdate == null || widget.lastUpdate!.isEmpty) return false;
    try {
      DateTime dt = DateTime.parse(widget.lastUpdate!).toLocal();
      return DateTime.now().difference(dt).inMinutes < 10;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double? numValue = double.tryParse(widget.value);
    String displayValue = numValue != null ? numValue.toStringAsFixed(_decimalPlaces) : widget.value;
    bool upToDate = _isUpToDate();
    final threshold = CemsThresholdService.getThreshold(widget.title);
    final bool isExceed =
        numValue != null && threshold != null && !CemsThresholdService.isCompliant(widget.title, numValue);
    final Color borderColor = isExceed ? AppColors.danger.withOpacity(0.5) : AppColors.border;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: isExceed ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child:  Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140), // batasi biar title tidak "meledak" saat di-scaleDown
                  child: Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSub),
                  ),
                ),
                if (isExceed)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 14),
                  ),
                const SizedBox(width: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: upToDate ? AppColors.general : AppColors.textDim,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(  fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    displayValue,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                ),
                const SizedBox(width: 4),
                Text(widget.unit, style: TextStyle(fontSize: 14, color: AppColors.textSub)),
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
    ;
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
