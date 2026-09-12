import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LogsheetField {
  final String id;
  final String label;
  final String unit;
  final double? minNormal;
  final double? maxNormal;
  final bool isStatus;

  const LogsheetField({
    required this.id,
    required this.label,
    required this.unit,
    this.minNormal,
    this.maxNormal,
    this.isStatus = false,
  });

  String validate(String? value) {
    if (value == null || value.isEmpty) return "";
    double? num = double.tryParse(value);
    if (num == null) return "Invalid number";
    if (minNormal != null && num < minNormal!) return "Low";
    if (maxNormal != null && num > maxNormal!) return "High";
    return "";
  }

  Color indicatorColor(String value) {
    if (value.isEmpty) return Colors.grey.withOpacity(0.3);
    double? num = double.tryParse(value);
    if (num == null) return Colors.orangeAccent;
    bool nearMin = minNormal != null && num >= minNormal! && num < minNormal! + (minNormal! * 0.1);
    bool nearMax = maxNormal != null && num <= maxNormal! && num > maxNormal! - (maxNormal! * 0.1);
    if (nearMin || nearMax) return Colors.amberAccent;
    if (minNormal != null && num < minNormal!) return Colors.redAccent;
    if (maxNormal != null && num > maxNormal!) return Colors.redAccent;
    if (minNormal == null && maxNormal == null) return Colors.blueAccent;
    return Colors.greenAccent;
  }
}

class FieldGroup {
  final String name;
  final List<LogsheetField> fields;

  const FieldGroup({required this.name, required this.fields});
}

class LogsheetConfig {
  final String area;
  final int unitIndex;
  final int shift;
  final String operatorName;
  final String supervisor;
  final Map<String, String> timeSlots;

  LogsheetConfig({
    required this.area,
    required this.unitIndex,
    required this.shift,
    required this.operatorName,
    required this.supervisor,
    required this.timeSlots,
  });
}

const List<FieldGroup> boilerGroups = [
  FieldGroup(name: "PAF Lube Oil Pressure", fields: [
    LogsheetField(id: "paf_lube_oil_press_1", label: "No.1 PAF Lube Oil Pressure", unit: "Bar", minNormal: 1.0, maxNormal: 1.2),
    LogsheetField(id: "paf_lube_oil_press_2", label: "No.2 PAF Lube Oil Pressure", unit: "Bar", minNormal: 1.0, maxNormal: 1.2),
  ]),
  FieldGroup(name: "PAF Bearing Motor Temperature", fields: [
    LogsheetField(id: "paf1_motor_temp_de", label: "No.1 PAF Motor Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 80),
    LogsheetField(id: "paf1_motor_temp_nde", label: "No.1 PAF Motor Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 80),
    LogsheetField(id: "paf2_motor_temp_de", label: "No.2 PAF Motor Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 80),
    LogsheetField(id: "paf2_motor_temp_nde", label: "No.2 PAF Motor Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 80),
  ]),
  FieldGroup(name: "PAF Fan Bearing Temperature", fields: [
    LogsheetField(id: "paf1_fan_bearing_temp_de", label: "No.1 PAF Fan Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 77),
    LogsheetField(id: "paf1_fan_bearing_temp_nde", label: "No.1 PAF Fan Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 77),
    LogsheetField(id: "paf2_fan_bearing_temp_de", label: "No.2 PAF Fan Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 77),
    LogsheetField(id: "paf2_fan_bearing_temp_nde", label: "No.2 PAF Fan Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 77),
  ]),
  FieldGroup(name: "PAF Oil Cooler Temperature", fields: [
    LogsheetField(id: "paf1_oil_cooler_temp_inlet", label: "No.1 PAF Oil Cooler Temp — Inlet", unit: "°C", minNormal: 25, maxNormal: 35),
    LogsheetField(id: "paf1_oil_cooler_temp_outlet", label: "No.1 PAF Oil Cooler Temp — Outlet", unit: "°C", minNormal: 25, maxNormal: 45),
    LogsheetField(id: "paf2_oil_cooler_temp_inlet", label: "No.2 PAF Oil Cooler Temp — Inlet", unit: "°C", minNormal: 25, maxNormal: 35),
    LogsheetField(id: "paf2_oil_cooler_temp_outlet", label: "No.2 PAF Oil Cooler Temp — Outlet", unit: "°C", minNormal: 25, maxNormal: 45),
  ]),
  FieldGroup(name: "PAF Oil Tank, IGV & Diff Pressure", fields: [
    LogsheetField(id: "paf1_oil_tank_level", label: "No.1 PAF Oil Tank Level", unit: "%", minNormal: 50, maxNormal: 100),
    LogsheetField(id: "paf2_oil_tank_level", label: "No.2 PAF Oil Tank Level", unit: "%", minNormal: 50, maxNormal: 100),
    LogsheetField(id: "paf1_igv_opening", label: "No.1 PAF IGV Opening", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "paf2_igv_opening", label: "No.2 PAF IGV Opening", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "paf1_diff_pressure", label: "No.1 PAF Differential Pressure", unit: "MBar", minNormal: 0, maxNormal: 0.5),
    LogsheetField(id: "paf2_diff_pressure", label: "No.2 PAF Differential Pressure", unit: "MBar", minNormal: 0, maxNormal: 0.5),
  ]),
  FieldGroup(name: "IDF Bearing Motor Temperature", fields: [
    LogsheetField(id: "idf1_motor_temp_de", label: "No.1 IDF Motor Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 65),
    LogsheetField(id: "idf1_motor_temp_nde", label: "No.1 IDF Motor Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 65),
    LogsheetField(id: "idf2_motor_temp_de", label: "No.2 IDF Motor Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 65),
    LogsheetField(id: "idf2_motor_temp_nde", label: "No.2 IDF Motor Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 65),
  ]),
  FieldGroup(name: "IDF Fan Bearing Temp, Oil Level & IGV", fields: [
    LogsheetField(id: "idf1_fan_bearing_temp_de", label: "No.1 IDF Fan Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 60),
    LogsheetField(id: "idf1_fan_bearing_temp_nde", label: "No.1 IDF Fan Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 60),
    LogsheetField(id: "idf2_fan_bearing_temp_de", label: "No.2 IDF Fan Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 60),
    LogsheetField(id: "idf2_fan_bearing_temp_nde", label: "No.2 IDF Fan Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 60),
    LogsheetField(id: "idf1_bearing_oil_level_de", label: "No.1 IDF Fan Bearing Oil Level — DE", unit: "%", minNormal: 40, maxNormal: 100),
    LogsheetField(id: "idf1_bearing_oil_level_nde", label: "No.1 IDF Fan Bearing Oil Level — NDE", unit: "%", minNormal: 40, maxNormal: 100),
    LogsheetField(id: "idf2_bearing_oil_level_de", label: "No.2 IDF Fan Bearing Oil Level — DE", unit: "%", minNormal: 40, maxNormal: 100),
    LogsheetField(id: "idf2_bearing_oil_level_nde", label: "No.2 IDF Fan Bearing Oil Level — NDE", unit: "%", minNormal: 40, maxNormal: 100),
    LogsheetField(id: "idf1_igv_opening", label: "No.1 IDF IGV Opening", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "idf2_igv_opening", label: "No.2 IDF IGV Opening", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "idf1_o2_excess", label: "No.1 IDF O2 Excess", unit: "%"),
    LogsheetField(id: "idf2_o2_excess", label: "No.2 IDF O2 Excess", unit: "%"),
  ]),
  FieldGroup(name: "SAF — Lube Oil, Bearing & Fan Temp", fields: [
    LogsheetField(id: "saf_lube_oil_press_1", label: "No.1 SAF Lube Oil Pressure", unit: "Bar", minNormal: 1.0, maxNormal: 1.2),
    LogsheetField(id: "saf_lube_oil_press_2", label: "No.2 SAF Lube Oil Pressure", unit: "Bar", minNormal: 1.0, maxNormal: 1.2),
    LogsheetField(id: "saf1_motor_temp_de", label: "No.1 SAF Motor Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 80),
    LogsheetField(id: "saf1_motor_temp_nde", label: "No.1 SAF Motor Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 80),
    LogsheetField(id: "saf2_motor_temp_de", label: "No.2 SAF Motor Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 80),
    LogsheetField(id: "saf2_motor_temp_nde", label: "No.2 SAF Motor Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 80),
    LogsheetField(id: "saf1_fan_bearing_temp_de", label: "No.1 SAF Fan Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 77),
    LogsheetField(id: "saf1_fan_bearing_temp_nde", label: "No.1 SAF Fan Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 77),
    LogsheetField(id: "saf2_fan_bearing_temp_de", label: "No.2 SAF Fan Bearing Temp — DE", unit: "°C", minNormal: 35, maxNormal: 77),
    LogsheetField(id: "saf2_fan_bearing_temp_nde", label: "No.2 SAF Fan Bearing Temp — NDE", unit: "°C", minNormal: 35, maxNormal: 77),
  ]),
  FieldGroup(name: "SAF — Oil Cooler, Tank & IGV", fields: [
    LogsheetField(id: "saf1_oil_cooler_temp_inlet", label: "No.1 SAF Oil Cooler Temp — Inlet", unit: "°C", minNormal: 25, maxNormal: 35),
    LogsheetField(id: "saf1_oil_cooler_temp_outlet", label: "No.1 SAF Oil Cooler Temp — Outlet", unit: "°C", minNormal: 25, maxNormal: 45),
    LogsheetField(id: "saf2_oil_cooler_temp_inlet", label: "No.2 SAF Oil Cooler Temp — Inlet", unit: "°C", minNormal: 25, maxNormal: 35),
    LogsheetField(id: "saf2_oil_cooler_temp_outlet", label: "No.2 SAF Oil Cooler Temp — Outlet", unit: "°C", minNormal: 25, maxNormal: 45),
    LogsheetField(id: "saf1_oil_tank_level", label: "No.1 SAF Oil Tank Level", unit: "%", minNormal: 50, maxNormal: 100),
    LogsheetField(id: "saf2_oil_tank_level", label: "No.2 SAF Oil Tank Level", unit: "%", minNormal: 50, maxNormal: 100),
    LogsheetField(id: "saf1_igv_opening", label: "No.1 SAF IGV Opening", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "saf2_igv_opening", label: "No.2 SAF IGV Opening", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "saf1_diff_pressure", label: "No.1 SAF Differential Pressure", unit: "MBar", minNormal: 0, maxNormal: 0.5),
    LogsheetField(id: "saf2_diff_pressure", label: "No.2 SAF Differential Pressure", unit: "MBar", minNormal: 0, maxNormal: 0.5),
  ]),
  FieldGroup(name: "P&S Blower & Seal Pot", fields: [
    LogsheetField(id: "ps_blower1_diff_press", label: "P&S Blower No.1 Diff Pressure", unit: "MBar", minNormal: 500, maxNormal: 1500),
    LogsheetField(id: "ps_blower2_diff_press", label: "P&S Blower No.2 Diff Pressure", unit: "MBar", minNormal: 500, maxNormal: 1500),
    LogsheetField(id: "ps_blower1_oil_level", label: "P&S Blower No.1 Oil Level", unit: "%", minNormal: 50),
    LogsheetField(id: "seal_pot_blower1_diff_press", label: "Seal Pot Blower No.1 Diff Pressure", unit: "MBar", minNormal: 0.2, maxNormal: 0.6),
    LogsheetField(id: "seal_pot_blower2_diff_press", label: "Seal Pot Blower No.2 Diff Pressure", unit: "MBar", minNormal: 0.2, maxNormal: 0.6),
    LogsheetField(id: "seal_pot_blower1_oil_level", label: "Seal Pot Blower No.1 Oil Level", unit: "%", minNormal: 50),
  ]),
  FieldGroup(name: "HP Dosing & Steam Drum", fields: [
    LogsheetField(id: "hp_dosing_stroke_pump_1", label: "HP Dosing Stroke Pump No.1", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "hp_dosing_stroke_pump_2", label: "HP Dosing Stroke Pump No.2", unit: "%", minNormal: 0, maxNormal: 100),
    LogsheetField(id: "hp_dosing_discharge_press_1", label: "HP Dosing Discharge Pressure No.1", unit: "MBar", maxNormal: 95),
    LogsheetField(id: "hp_dosing_discharge_press_2", label: "HP Dosing Discharge Pressure No.2", unit: "MBar", maxNormal: 95),
    LogsheetField(id: "hp_dosing_tank_level", label: "HP Dosing Tank Level", unit: "CM", minNormal: 30, maxNormal: 80),
    LogsheetField(id: "steam_drum_pressure", label: "Steam Drum Pressure", unit: "Bar", maxNormal: 100),
    LogsheetField(id: "steam_drum_level_left", label: "Steam Drum Level — Left", unit: "mm"),
    LogsheetField(id: "steam_drum_level_right", label: "Steam Drum Level — Right", unit: "mm"),
  ]),
];

const List<FieldGroup> steamTurbineGroups = [
  FieldGroup(name: "LP Heater", fields: [
    LogsheetField(id: "lp_heater1_pressure", label: "No.1 LP Heater Pressure", unit: "Bar", maxNormal: 1.2),
    LogsheetField(id: "lp_heater1_level", label: "No.1 LP Heater Level", unit: "mm", maxNormal: 350),
    LogsheetField(id: "lp_heater2_pressure", label: "No.2 LP Heater Pressure", unit: "Bar", maxNormal: 5.8),
    LogsheetField(id: "lp_heater2_level", label: "No.2 LP Heater Level", unit: "mm", maxNormal: 350),
  ]),
  FieldGroup(name: "Condenser Cooling Water", fields: [
    LogsheetField(id: "cond_cw_left_inlet_temp", label: "Condenser CW Left — Inlet Temp", unit: "°C", maxNormal: 33),
    LogsheetField(id: "cond_cw_left_outlet_temp", label: "Condenser CW Left — Outlet Temp", unit: "°C", maxNormal: 49),
    LogsheetField(id: "cond_cw_left_pressure", label: "Condenser CW Left — Pressure", unit: "Bar", maxNormal: 3),
    LogsheetField(id: "cond_cw_right_inlet_temp", label: "Condenser CW Right — Inlet Temp", unit: "°C", maxNormal: 33),
    LogsheetField(id: "cond_cw_right_outlet_temp", label: "Condenser CW Right — Outlet Temp", unit: "°C", maxNormal: 49),
    LogsheetField(id: "cond_cw_right_pressure", label: "Condenser CW Right — Pressure", unit: "Bar", maxNormal: 3),
  ]),
  FieldGroup(name: "Condenser & CEP", fields: [
    LogsheetField(id: "condenser_level", label: "Condenser Level (Hotwell)", unit: "mm"),
    LogsheetField(id: "cep1_inlet_pressure", label: "No.1 CEP Inlet Pressure", unit: "Bar"),
    LogsheetField(id: "cep1_outlet_pressure", label: "No.1 CEP Outlet Pressure", unit: "Bar", maxNormal: 15),
    LogsheetField(id: "cep2_inlet_pressure", label: "No.2 CEP Inlet Pressure", unit: "Bar"),
    LogsheetField(id: "cep2_outlet_pressure", label: "No.2 CEP Outlet Pressure", unit: "Bar", maxNormal: 15),
  ]),
  FieldGroup(name: "Condensate Temp & Gland Steam", fields: [
    LogsheetField(id: "condensate_temp_inlet", label: "Condensate Temp — Inlet", unit: "°C", maxNormal: 45),
    LogsheetField(id: "condensate_temp_outlet", label: "Condensate Temp — Outlet", unit: "°C", maxNormal: 50),
    LogsheetField(id: "gland_steam_press_inlet", label: "Gland Steam Condenser — Seal Steam Press Inlet", unit: "Bar", maxNormal: 0.03),
    LogsheetField(id: "gland_steam_cond_inlet_temp", label: "GSC Condensate Inlet Temp", unit: "°C", maxNormal: 45),
    LogsheetField(id: "gland_steam_cond_outlet_temp", label: "GSC Condensate Outlet Temp", unit: "°C", maxNormal: 50),
  ]),
  FieldGroup(name: "Air Removal Cooling System", fields: [
    LogsheetField(id: "air_removal1_cw_inlet_temp", label: "No.1 Air Removal CW Inlet Temp", unit: "°C", maxNormal: 33),
    LogsheetField(id: "air_removal1_pressure", label: "No.1 Air Removal Pressure", unit: "Bar", maxNormal: 3),
    LogsheetField(id: "air_removal1_cw_outlet_temp", label: "No.1 Air Removal CW Outlet Temp", unit: "°C", maxNormal: 50),
    LogsheetField(id: "air_removal1_outlet_cooler_temp", label: "No.1 Air Removal Outlet Cooler Temp", unit: "°C", maxNormal: 50),
    LogsheetField(id: "air_removal2_cw_inlet_temp", label: "No.2 Air Removal CW Inlet Temp", unit: "°C", maxNormal: 33),
    LogsheetField(id: "air_removal2_pressure", label: "No.2 Air Removal Pressure", unit: "Bar", maxNormal: 3),
    LogsheetField(id: "air_removal2_cw_outlet_temp", label: "No.2 Air Removal CW Outlet Temp", unit: "°C", maxNormal: 50),
    LogsheetField(id: "air_removal2_outlet_cooler_temp", label: "No.2 Air Removal Outlet Cooler Temp", unit: "°C", maxNormal: 50),
    LogsheetField(id: "air_removal_pressure", label: "Air Removal Pressure", unit: "Bar"),
  ]),
  FieldGroup(name: "Generator Cooling System", fields: [
    LogsheetField(id: "gen_cooling_cw_inlet_temp", label: "Generator Cooling Water Inlet Temp", unit: "°C", maxNormal: 33),
    LogsheetField(id: "gen_cooling_cw_outlet_temp", label: "Generator Cooling Water Outlet Temp", unit: "°C", maxNormal: 55),
    LogsheetField(id: "gen_cooling_cw_pressure", label: "Generator Cooling Water Pressure", unit: "Bar", maxNormal: 3),
  ]),
  FieldGroup(name: "Deaerator", fields: [
    LogsheetField(id: "deaerator_inlet_steam_press", label: "Deaerator Inlet Steam Pressure", unit: "Bar", maxNormal: 7),
    LogsheetField(id: "deaerator_inlet_steam_temp", label: "Deaerator Inlet Steam Temp", unit: "°C", maxNormal: 155),
    LogsheetField(id: "deaerator_lp_heater2_steam_press", label: "Deaerator from LP Heater No.2 Steam Press", unit: "Bar", maxNormal: 1.2),
    LogsheetField(id: "deaerator_lp_heater2_steam_temp", label: "Deaerator from LP Heater No.2 Steam Temp", unit: "°C", maxNormal: 150),
    LogsheetField(id: "deaerator_cycle_makeup_press", label: "Deaerator Cycle Makeup Pump Inlet Press", unit: "Bar", maxNormal: 15),
    LogsheetField(id: "deaerator_cycle_makeup_temp", label: "Deaerator Cycle Makeup Pump Inlet Temp", unit: "°C", maxNormal: 36),
    LogsheetField(id: "deaerator_cycle_makeup_flow", label: "Deaerator Cycle Makeup Pump Inlet Flow", unit: "M³", maxNormal: 15),
  ]),
  FieldGroup(name: "Feed Water Storage & Inlet Steam", fields: [
    LogsheetField(id: "fw_storage_pressure", label: "Feed Water Storage Pressure", unit: "Bar", maxNormal: 7),
    LogsheetField(id: "fw_storage_temp", label: "Feed Water Storage Temp", unit: "°C", maxNormal: 155),
    LogsheetField(id: "fw_storage_level", label: "Feed Water Storage Level", unit: "mm", maxNormal: 1400),
    LogsheetField(id: "inlet_steam_to_turbine_press", label: "Inlet Steam to Turbine Pressure", unit: "Bar", minNormal: 78, maxNormal: 84),
    LogsheetField(id: "inlet_steam_to_turbine_temp", label: "Inlet Steam to Turbine Temp", unit: "°C", minNormal: 510, maxNormal: 528),
  ]),
  FieldGroup(name: "Steam Turbine Extraction", fields: [
    LogsheetField(id: "extraction_to_lp_heater1_press", label: "Extraction to LP Heater No.1 Press", unit: "Bar", maxNormal: 5.8),
    LogsheetField(id: "extraction_to_lp_heater1_temp", label: "Extraction to LP Heater No.1 Temp", unit: "°C", maxNormal: 150),
    LogsheetField(id: "extraction_to_lp_heater2_press", label: "Extraction to LP Heater No.2 Press", unit: "Bar", maxNormal: 1.2),
    LogsheetField(id: "extraction_to_lp_heater2_temp", label: "Extraction to LP Heater No.2 Temp", unit: "°C", maxNormal: 150),
    LogsheetField(id: "extraction_to_deaerator_press", label: "Extraction to Deaerator Press", unit: "Bar", maxNormal: 7),
    LogsheetField(id: "extraction_to_deaerator_temp", label: "Extraction to Deaerator Temp", unit: "°C", maxNormal: 160),
  ]),
  FieldGroup(name: "LP Dosing System", fields: [
    LogsheetField(id: "lp_dosing_stroke_pump_1", label: "LP Dosing Stroke Pump No.1", unit: "%", minNormal: 20),
    LogsheetField(id: "lp_dosing_stroke_pump_2", label: "LP Dosing Stroke Pump No.2", unit: "%", minNormal: 20),
    LogsheetField(id: "lp_dosing_tank_level", label: "LP Dosing Tank Level", unit: "%", minNormal: 20),
  ]),
  FieldGroup(name: "Lube Oil System & Jacking Oil", fields: [
    LogsheetField(id: "lube_oil_temp_before_cooler", label: "Lube Oil Temp Before Cooler", unit: "°C", maxNormal: 65),
    LogsheetField(id: "lube_oil_temp_after_cooler", label: "Lube Oil Temp After Cooler", unit: "°C", maxNormal: 65),
    LogsheetField(id: "turbine_bearing_press_de", label: "Turbine Bearing Press — DE", unit: "Bar", minNormal: 1),
    LogsheetField(id: "turbine_bearing_press_nde", label: "Turbine Bearing Press — NDE", unit: "Bar", minNormal: 1),
    LogsheetField(id: "gen_bearing_press_de", label: "Generator Bearing Press — DE", unit: "Bar", minNormal: 1),
    LogsheetField(id: "gen_bearing_press_nde", label: "Generator Bearing Press — NDE", unit: "Bar", minNormal: 1),
    LogsheetField(id: "gearbox_pressure", label: "Gearbox Pressure", unit: "Bar", minNormal: 1),
    LogsheetField(id: "jacking_oil_pump_pressure", label: "Jacking Oil Pump Pressure", unit: "Bar"),
    LogsheetField(id: "jacking_oil_gen_bearing_de", label: "Jacking Oil — DE Gen Bearing Press", unit: "Bar"),
    LogsheetField(id: "jacking_oil_gen_bearing_nde", label: "Jacking Oil — NDE Gen Bearing Press", unit: "Bar"),
    LogsheetField(id: "lube_oil_cooler_in_service", label: "Lube Oil Cooler In Service", unit: "", isStatus: true),
    LogsheetField(id: "lube_oil_filter_in_service", label: "Lube Oil Filter In Service", unit: "", isStatus: true),
  ]),
];

int getShiftFromHour(int hour) {
  if (hour >= 7 && hour < 15) return 1;
  if (hour >= 15 && hour < 23) return 2;
  return 3;
}

String getShiftLabel(int shift) {
  switch (shift) {
    case 1: return "Shift I (07:00-15:00)";
    case 2: return "Shift II (15:00-23:00)";
    case 3: return "Shift III (23:00-07:00)";
    default: return "";
  }
}

String formatSlot(int hour) {
  return '${hour.toString().padLeft(2, '0')}:00';
}

List<String> getAvailableSlots(DateTime now) {
  int currentHour = now.hour;
  int prevHour = currentHour == 0 ? 23 : currentHour - 1;
  Set<String> slots = {};
  if (prevHour >= 10 || prevHour < 10 && prevHour >= 0) {
    slots.add(formatSlot(prevHour));
  }
  slots.add(formatSlot(currentHour));
  return slots.toList()..sort();
}

String getSpreadsheetName(String area, int unitIndex, DateTime date) {
  String areaName = area == "boiler" ? "Boiler" : "SteamTurbine";
  String unit = "Unit${unitIndex + 1}";
  String month = DateFormat("yyyy-MM").format(date);
  return "${areaName}_${unit}_$month";
}

String getSheetName(DateTime date) {
  return DateFormat("yyyy_MM_dd").format(date);
}

String getHeaderLabel(LogsheetField field) {
  return field.id.toUpperCase().replaceAll('_', ' ');
}

List<String> getBoundaryRow(List<FieldGroup> groups) {
  List<String> row = ["", "", "", "", ""];
  for (var group in groups) {
    for (var field in group.fields) {
      String boundary = "";
      if (field.minNormal != null && field.maxNormal != null) {
        boundary =
            "${field.minNormal!.toStringAsFixed(1)} – ${field.maxNormal!.toStringAsFixed(1)} ${field.unit}";
      } else if (field.minNormal != null) {
        boundary = "Min ${field.minNormal!.toStringAsFixed(1)} ${field.unit}";
      } else if (field.maxNormal != null) {
        boundary = "Max ${field.maxNormal!.toStringAsFixed(1)} ${field.unit}";
      } else if (field.unit.isNotEmpty) {
        boundary = "${field.unit}";
      }
      row.add(boundary);
    }
  }
  return row;
}

List<String> getHeaderRow(List<FieldGroup> groups) {
  List<String> headers = ["Time", "Operator", "Shift", "Supervisor", "Remark"];
  for (var group in groups) {
    for (var field in group.fields) {
      headers.add(getHeaderLabel(field));
    }
  }
  return headers;
}
