import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:msw_eplant/widgets/widgets.dart';

class CemsPage extends StatefulWidget {
  const CemsPage({super.key});

  @override
  State<CemsPage> createState() => _CemsPageState();
}

class _CemsPageState extends State<CemsPage> {
  int _selectedIndex = 0;

  final DatabaseReference _cems1Ref = FirebaseDatabase.instance.ref("excel_data/cems1");
  final DatabaseReference _cems2Ref = FirebaseDatabase.instance.ref("excel_data/cems2");

  final DatabaseReference _boiler1Ref = FirebaseDatabase.instance.ref("excel_data/table1");

  @override
  Widget build(BuildContext context) {
    return Container( decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('asset/msw.png'),
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.7),
            BlendMode.darken,
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text("CEMS Monitoring"), centerTitle: true),
        body: _selectedIndex == 0
            ? buildCombinedStream(_cems1Ref, _boiler1Ref, 1)
            : buildCombinedStream(_cems2Ref, _boiler1Ref, 2),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.air), label: "CEMS 1"),
            BottomNavigationBarItem(icon: Icon(Icons.air), label: "CEMS 2"),
          ],
        ),
      ),
    );
  }

  Widget buildCombinedStream(DatabaseReference cemsRef, DatabaseReference boilerRef, int unit) {
    return StreamBuilder(
      stream: cemsRef.onValue,
      builder: (context, cemsSnapshot) {
        if (!cemsSnapshot.hasData || (cemsSnapshot.data!).snapshot.value == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final cemsData = (cemsSnapshot.data!).snapshot.value;

        return StreamBuilder(
          stream: boilerRef.onValue,
          builder: (context, boilerSnapshot) {
            if (!boilerSnapshot.hasData || (boilerSnapshot.data!).snapshot.value == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final boilerData = (boilerSnapshot.data!).snapshot.value;

            List<List> valuesCems = [];
            List<List> valuesBoiler = [];

            if (cemsData is List) {
              valuesCems = List<List>.from(cemsData.map((e) => List.from(e)));
            } else if (cemsData is Map) {
              valuesCems = List<List>.from(cemsData.values.map((e) => List.from(e)));
            }

            if (boilerData is List) {
              valuesBoiler = List<List>.from(boilerData.map((e) => List.from(e)));
            } else if (boilerData is Map) {
              valuesBoiler = List<List>.from(boilerData.values.map((e) => List.from(e)));
            }

            if (valuesBoiler.isNotEmpty && valuesCems.isNotEmpty) {
              if (!valuesCems[0].contains("DATETIME")) {
                valuesCems[0].insert(0, "DATETIME");
              }
              for (int i = 1; i < valuesCems.length && i < valuesBoiler.length; i++) {
                valuesCems[i].insert(0, valuesBoiler[i][0]);
              }
            }

            if (valuesCems.length > 1) {
              final header = valuesCems.first.cast<String>();
              final lastRecord = valuesCems.last;
              String formattedDate = formatDateTime(valuesCems.last[0].toString());
              return buildDataView(
                context,
                header,
                lastRecord,
                valuesCems,
                _selectedIndex,
                formattedDate,
              );
            }

            return const Center(child: Text("No CEMS data available"));
          },
        );
      },
    );
  }
}
