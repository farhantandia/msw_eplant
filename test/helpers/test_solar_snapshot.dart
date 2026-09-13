import 'dart:math';
import 'package:msw_eplant/models/solar_models.dart';
import 'package:msw_eplant/services/fusion_solar_api_client.dart';

/// Test helper to generate a realistic mock [SolarSnapshot] for tests.
SolarSnapshot generateTestSolarSnapshot({DateTime? date}) {
  final now = date ?? DateTime.now();
  final hour = now.hour;
  final isNight = hour < 6 || hour >= 18;

  double sunFactor = 0.0;
  if (hour >= 6 && hour <= 18) {
    sunFactor = sin((hour - 6) / 12 * pi);
  }

  const peakSystemPower = 640.0;
  final currentPower = isNight ? 0.0 : peakSystemPower * sunFactor * (0.85 + 0.15 * 0.5);

  double cumulativeYield = 0.0;
  final hourlyPoints = <SolarHourlyPoint>[];
  final maxHour = hour.clamp(4, 20);

  for (int h = 4; h <= maxHour; h++) {
    double hFactor = 0.0;
    if (h >= 6 && h <= 18) {
      hFactor = sin((h - 6) / 12 * pi);
    }
    final hPower = (peakSystemPower * hFactor * 0.90).clamp(0.0, 680.0);
    cumulativeYield += hPower * 0.85;

    final mswPower = double.parse((hPower * 0.46).toStringAsFixed(1));
    final kelPower = double.parse((hPower * 0.54).toStringAsFixed(1));
    final mswIrr = double.parse((hFactor * 5.35).toStringAsFixed(2));
    final kelIrr = double.parse((hFactor * 4.92).toStringAsFixed(2));

    hourlyPoints.add(SolarHourlyPoint(
      hour: h,
      timeStr: '${h.toString().padLeft(2, '0')}:00',
      powerKw: double.parse(hPower.toStringAsFixed(1)),
      irradiance: double.parse((hFactor * 5.2).toStringAsFixed(2)),
      pr: hFactor > 0.1 ? 81.4 : 0.0,
      plantData: {
        'msw': {'power': mswPower, 'irradiance': mswIrr, 'pr': 82.6},
        'kelanis': {'power': kelPower, 'irradiance': kelIrr, 'pr': 79.8},
      },
    ));
  }

  final inverters = <SolarInverter>[
    // 165 kWp Array (4 units @ 41.25 kWp each = 165 kWp, MSW)
    SolarInverter(
      id: 'inv_165_1',
      name: 'INV PLTS 165 kWp 1',
      clusterId: '165kwp',
      plantId: 'msw',
      capacityKwp: 41.25,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.047).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.048).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
    SolarInverter(
      id: 'inv_165_2',
      name: 'INV PLTS 165 kWp 2',
      clusterId: '165kwp',
      plantId: 'msw',
      capacityKwp: 41.25,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.048).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.048).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
    SolarInverter(
      id: 'inv_165_3',
      name: 'INV PLTS 165 kWp 3',
      clusterId: '165kwp',
      plantId: 'msw',
      capacityKwp: 41.25,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.049).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.049).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
    SolarInverter(
      id: 'inv_165_4',
      name: 'INV PLTS 165 kWp 4',
      clusterId: '165kwp',
      plantId: 'msw',
      capacityKwp: 41.25,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.046).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.047).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),

    // 200 kWp Array (2 units @ 100 kWp each = 200 kWp, MSW)
    SolarInverter(
      id: 'inv_200_1',
      name: 'INV_PLTS_200_KWP_1',
      clusterId: '200kwp',
      plantId: 'msw',
      capacityKwp: 100.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.115).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.115).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
    SolarInverter(
      id: 'inv_200_2',
      name: 'INV_PLTS_200_KWP_2',
      clusterId: '200kwp',
      plantId: 'msw',
      capacityKwp: 100.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.114).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.114).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),

    // 468 kWp Array (4 units @ 117 kWp each = 468 kWp, Kelanis with Specific Energy)
    SolarInverter(
      id: 'inv_468_1',
      name: 'Inverter(COM1-1)',
      clusterId: '468kwp',
      plantId: 'kelanis',
      capacityKwp: 117.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.134).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.134).toStringAsFixed(1)),
      specificEnergy: 3.42,
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
    SolarInverter(
      id: 'inv_468_2',
      name: 'Inverter(COM1-2)',
      clusterId: '468kwp',
      plantId: 'kelanis',
      capacityKwp: 117.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.136).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.135).toStringAsFixed(1)),
      specificEnergy: 3.45,
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
      temperature: 48.5,
      gridFrequency: 50.02,
      lineVoltageAb: 399.5,
      lineVoltageBc: 400.1,
      lineVoltageCa: 399.8,
      efficiency: 98.6,
      powerFactor: 0.999,
      activeAlarms: [
        SolarAlarm(
          alarmId: 'ALM-2001-01',
          alarmName: 'High Temperature Derating Warning',
          devName: 'Inverter(COM1-2)',
          devId: 'inv_468_2',
          esn: '6T2469039092',
          severity: AlarmSeverity.warning,
          raiseTime: DateTime(now.year, now.month, now.day, 13, 15),
          cause: 'Inverter internal temperature reached 48.5°C approaching ventilation warning threshold.',
          repairSuggestion: '1. Inspect ventilation grilles.\n2. Verify external cooling fans.\n3. Check ambient temperature.',
          status: 'Active',
          alarmCode: 2001,
        ),
      ],
    ),
    SolarInverter(
      id: 'inv_468_3',
      name: 'Inverter(COM1-3)',
      clusterId: '468kwp',
      plantId: 'kelanis',
      capacityKwp: 117.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.133).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.133).toStringAsFixed(1)),
      specificEnergy: 3.40,
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
    SolarInverter(
      id: 'inv_468_4',
      name: 'Inverter(COM1-5)',
      clusterId: '468kwp',
      plantId: 'kelanis',
      capacityKwp: 117.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.135).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.135).toStringAsFixed(1)),
      specificEnergy: 3.43,
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),

    // 15 & 20 kWp Array (2 units = 35 kWp, MSW)
    SolarInverter(
      id: 'inv_15',
      name: 'INV PLTS 15 kWp',
      clusterId: '15_20kwp',
      plantId: 'msw',
      capacityKwp: 15.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.017).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.017).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
    SolarInverter(
      id: 'inv_20',
      name: 'INV PLTS 20 kWp',
      clusterId: '15_20kwp',
      plantId: 'msw',
      capacityKwp: 20.0,
      powerKw: isNight ? 0.0 : double.parse((currentPower * 0.023).toStringAsFixed(1)),
      yieldTodayKwh: double.parse((cumulativeYield * 0.023).toStringAsFixed(1)),
      status: isNight ? InverterStatus.standby : InverterStatus.normal,
      isNightStandby: isNight,
    ),
  ];

  final activeCount = isNight ? 0 : inverters.where((i) => i.status == InverterStatus.normal).length;
  final irradiance = isNight ? 0.0 : double.parse((sunFactor * 5.2).toStringAsFixed(2));
  final mswIrr = isNight ? 0.0 : double.parse((sunFactor * 5.35).toStringAsFixed(2));
  final kelanisIrr = isNight ? 0.0 : double.parse((sunFactor * 4.92).toStringAsFixed(2));
  final plantIrrMap = {'msw': mswIrr, 'kelanis': kelanisIrr};
  final plantPrMap = {'msw': 82.6, 'kelanis': 79.8};
  final bucketTime = FusionSolarApiClient.roundToNearestHalfHour(now);

  return SolarSnapshot(
    timestamp: bucketTime,
    isLive: true,
    totalPowerKw: double.parse(currentPower.toStringAsFixed(1)),
    peakPowerKw: peakSystemPower,
    totalYieldTodayKwh: double.parse(cumulativeYield.toStringAsFixed(1)),
    yieldYesterdayKwh: 2600.0,
    irradiance: irradiance,
    performanceRatio: 81.4,
    plantIrradiance: plantIrrMap,
    plantPr: plantPrMap,
    plantYieldYesterday: const {'msw': 1720.0, 'kelanis': 880.0},
    irradianceYesterday: 5.10,
    performanceRatioYesterday: 81.2,
    peakPowerYesterday: 620.0,
    plantIrradianceYesterday: const {'msw': 5.25, 'kelanis': 4.95},
    plantPrYesterday: const {'msw': 82.1, 'kelanis': 80.3},
    plantPeakPowerYesterday: const {'msw': 380.0, 'kelanis': 440.0},
    gridExportKw: double.parse((currentPower * 0.98).toStringAsFixed(1)),
    onlineInverterCount: isNight ? 12 : activeCount,
    totalInverterCount: 12,
    totalCapacityKwp: 868.0,
    inverters: inverters,
    hourlyPoints: hourlyPoints,
  );
}
