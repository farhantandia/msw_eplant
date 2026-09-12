import 'package:flutter_test/flutter_test.dart';
import 'package:msw_eplant/models/plant_overview_models.dart';

void main() {
  group('PlantOverviewSnapshot parsing tests', () {
    test('Correctly parses all 14 columns from overview table and sets properties', () {
      final overviewData = [
        [
          'DATETIME',
          'UNIT 1 TMGCR',
          'UNIT 2 TMGCR',
          'UNIT 1 BMCR',
          'UNIT 2 BMCR',
          'UNIT 1 BOILER EFFICIENCY',
          'UNIT 1 EAF',
          'UNIT 1 CAPACITY FACTOR',
          'UNIT 2 BOILER EFFICIENCY',
          'UNIT 2 EAF',
          'UNIT 2 CAPACITY FACTOR',
          'LOAD TO PLN',
          'LOAD TO AI',
          'TOTAL LOAD',
          'TOTAL HOUSE LOAD',
        ],
        [
          '2026-09-11 12:00:00',
          '65.0',
          '65.0',
          '280.0',
          '280.0',
          '88.5',
          '95.2',
          '82.1',
          '87.9',
          '94.0',
          '80.5',
          '42.5',
          '10.2',
          '58.2',
          '5.5',
        ],
      ];

      final table1Data = [
        ['DATETIME', 'UNIT 1 LOAD'],
        ['2026-09-11 12:00:00', '29.1'],
      ];

      final table2Data = [
        ['DATETIME', 'UNIT 2 LOAD'],
        ['2026-09-11 12:00:00', '29.1'],
      ];

      final nphrData = [
        ['DATETIME', 'NPHR UNIT 1', 'NPHR UNIT 2'],
        ['2026-09-11 12:00:00', '2450.0', '2480.0'],
      ];

      final cems1Data = [
        ['DATETIME', 'SO2', 'NOX', 'PARTICULATE', 'HG CORRECTION'],
        ['2026-09-11 12:00:00', '210.5', '320.1', '25.0', '0.015'],
      ];

      final cems2Data = [
        ['DATETIME', 'SO2', 'NOX', 'PARTICULATE', 'HG CORRECTION'],
        ['2026-09-11 12:00:00', '225.0', '340.5', '28.4', '0.020'],
      ];

      final snapshot = PlantOverviewSnapshot.fromFirebase(
        overviewData: overviewData,
        table1Data: table1Data,
        table2Data: table2Data,
        cems1Data: cems1Data,
        cems2Data: cems2Data,
        nphrData: nphrData,
      );

      expect(snapshot.hasData, isTrue);
      expect(snapshot.totalLoad, 58.2);
      expect(snapshot.loadToPln, 42.5);
      expect(snapshot.loadToAi, 10.2);
      expect(snapshot.totalHouseLoad, 5.5);
      expect(snapshot.totalNetExport, 52.7);
      expect(snapshot.houseLoadPct, closeTo(9.45, 0.1));
      expect(snapshot.formattedTimestamp, '11 Sep 2026, 12:00');

      // Unit 1
      expect(snapshot.unit1.grossLoad, 29.1);
      expect(snapshot.unit1.tmgcr, 65.0);
      expect(snapshot.unit1.bmcr, 280.0);
      expect(snapshot.unit1.boilerEfficiency, 88.5);
      expect(snapshot.unit1.eaf, 95.2);
      expect(snapshot.unit1.capacityFactor, 82.1);
      expect(snapshot.unit1.nphr, 2450.0);
      expect(snapshot.unit1.condition, UnitOperatingCondition.normal);
      expect(snapshot.unit1.loadingRatio, closeTo(44.76, 0.1));

      // Unit 2
      expect(snapshot.unit2.grossLoad, 29.1);
      expect(snapshot.unit2.tmgcr, 65.0);
      expect(snapshot.unit2.bmcr, 280.0);
      expect(snapshot.unit2.boilerEfficiency, 87.9);
      expect(snapshot.unit2.eaf, 94.0);
      expect(snapshot.unit2.capacityFactor, 80.5);
      expect(snapshot.unit2.nphr, 2480.0);
      expect(snapshot.unit2.condition, UnitOperatingCondition.normal);

      // CEMS
      expect(snapshot.cemsParams.length, 4);
      final so2 = snapshot.cemsParams.firstWhere((c) => c.paramKey == 'SO2');
      expect(so2.unit1Value, 210.5);
      expect(so2.unit2Value, 225.0);
      expect(so2.isUnit1Compliant, isTrue);
      expect(so2.isUnit2Compliant, isTrue);

      final nox = snapshot.cemsParams.firstWhere((c) => c.paramKey == 'NOX');
      expect(nox.unit1Value, 320.1);
      expect(nox.unit2Value, 340.5);
      expect(nox.isUnit1Compliant, isTrue);

      final pm = snapshot.cemsParams.firstWhere((c) => c.paramKey == 'PARTICULATE');
      expect(pm.unit1Value, 25.0);
      expect(pm.threshold, 50.0);
      expect(pm.isUnit1Compliant, isTrue);

      final hg = snapshot.cemsParams.firstWhere((c) => c.paramKey == 'HG');
      expect(hg.displayName, 'Hg Correction');
      expect(hg.threshold, 0.03);
      expect(hg.unit1Value, 0.015);
      expect(hg.unit2Value, 0.020);
      expect(hg.isUnit1Compliant, isTrue);
      expect(hg.isUnit2Compliant, isTrue);
    });

    test('Parses 2-column NPHR telemetry without date column', () {
      final nphr2Col = [
        ['NPHR1', 'NPHR2'],
        ['2410.0', '2390.0'],
      ];

      final snapshot = PlantOverviewSnapshot.fromFirebase(
        nphrData: nphr2Col,
      );

      expect(snapshot.unit1.nphr, 2410.0);
      expect(snapshot.unit2.nphr, 2390.0);
    });

    test('Zero hardcoded data: When data is missing, values remain null and format to dash', () {
      final snapshot = PlantOverviewSnapshot.fromFirebase(
        overviewData: [],
        table1Data: [],
        table2Data: [],
      );

      expect(snapshot.hasData, isFalse);
      expect(snapshot.totalLoad, isNull);
      expect(snapshot.loadToPln, isNull);
      expect(snapshot.loadToAi, isNull);
      expect(snapshot.totalHouseLoad, isNull);
      expect(snapshot.unit1.grossLoad, isNull);
      expect(snapshot.unit1.tmgcr, isNull);
      expect(snapshot.unit1.boilerEfficiency, isNull);
      expect(snapshot.unit1.condition, UnitOperatingCondition.shutdown);

      expect(PlantOverviewSnapshot.formatVal(snapshot.totalLoad), '—');
      expect(PlantOverviewSnapshot.formatVal(snapshot.unit1.boilerEfficiency, suffix: '%'), '—');
    });

    test('UnitOperatingCondition classifies loads correctly', () {
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: 25.0).condition, UnitOperatingCondition.normal);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: 12.0).condition, UnitOperatingCondition.normal);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: 11.9).condition, UnitOperatingCondition.lowLoad);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: 4.0).condition, UnitOperatingCondition.lowLoad);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: 3.9).condition, UnitOperatingCondition.houseLoad);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: 0.5).condition, UnitOperatingCondition.houseLoad);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: 0.0).condition, UnitOperatingCondition.shutdown);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: -1.0).condition, UnitOperatingCondition.shutdown);
      expect(const UnitOverviewData(unitIndex: 0, grossLoad: null).condition, UnitOperatingCondition.shutdown);
    });

    test('Fallback to table1 if overview is not yet updated', () {
      final table1Data = [
        ['DATETIME', 'UNIT 1 LOAD', 'LOAD TO PLN', 'LOAD TO AI', 'TOTAL HOUSE LOAD'],
        ['2026-09-11 10:00:00', '28.0', '40.0', '12.0', '4.0'],
      ];

      final snapshot = PlantOverviewSnapshot.fromFirebase(
        overviewData: [],
        table1Data: table1Data,
      );

      expect(snapshot.unit1.grossLoad, 28.0);
      expect(snapshot.loadToPln, 40.0);
      expect(snapshot.loadToAi, 12.0);
      expect(snapshot.totalHouseLoad, 4.0);
      expect(snapshot.formattedTimestamp, '11 Sep 2026, 10:00');
    });
  });
}
