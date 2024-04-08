import 'dart:math';

import 'package:flutter/material.dart';

const schedule3 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|A|B, C||
11:30 ~ 13:00||||A
13:00 ~ 14:30|B|||
14:30 ~ 15:30|A|B, C||
15:30 ~ 17:00|C|||''';

const schedule4 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|C|A, B||
11:30 ~ 13:00||||D
13:00 ~ 14:00|C|A, B||
14:00 ~ 15:00|D|||
15:00 ~ 16:00|A||C,D|
16:00 ~ 17:00|B|||''';

const schedule5 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|E|A, B||
11:30 ~ 13:00||||E
13:00 ~ 14:30|C|A, B||
14:30 ~ 15:00|A||C, D|
15:00 ~ 15:30|B|||
15:30 ~ 17:00|D|||''';

const schedule6 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|A|B, C|D, E|
11:30 ~ 13:00||||F
13:00 ~ 15:00|D|B, C||
15:00 ~ 17:00|E||A, F|''';

const List<String> schedules = [
  '',
  '',
  '',
  schedule3,
  schedule4,
  schedule5,
  schedule6,
  ''
];

class Pair {
  int? value;
  String? key;
  Pair(int v, String k) {
    value = v;
    key = k;
  }
}

String abcToName(int n, List<String> order) {
  final abc = ["A", "B", "C", "D", "E", "F"];
  var s = schedules[n];
  for (int i = 0; i < n; ++i) {
    s = s.replaceAll(abc[i], order[i]);
  }
  return s;
}

DataTable stringToDataTable(String input) {
  List<DataColumn> makeColumn(String input) {
    return input.split('|').map((e) => DataColumn(label: Text(e))).toList();
  }

  DataRow makeRow(String input) {
    return DataRow(
        cells: input.split('|').map((e) => DataCell(Text(e))).toList());
  }

  final temps = input.split('\n');
  final col = makeColumn(temps[0]);
  temps.removeAt(0);
  return DataTable(columns: col, rows: temps.map((e) => makeRow(e)).toList());
}

void main() {
  runApp(MaterialApp(
    home: const MyApp(),
    theme: ThemeData(useMaterial3: false),
  ));
}

Random R = Random();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final members = ['두원', '정빈', '형주', '성민', '재겸', '근호', '형준'];
  List<bool> checkedMember = [false, false, false, false, false, false, false];
  int workingMembers = 0;

  void Function() checkingMember(int n) {
    return () => setState(() {
          checkedMember[n] = !checkedMember[n];
          checkedMember[n] ? ++workingMembers : --workingMembers;
        });
  }

  List<String> mixUpOrder() {
    List<Pair> memberWithOrder = [];
    List<String> result = [];
    for (int i = 0; i < members.length; ++i) {
      if (checkedMember[i]) {
        memberWithOrder.add(Pair(R.nextInt(1000), members[i]));
      }
    }
    memberWithOrder.sort((a, b) => a.value! - b.value!);
    for (Pair member in memberWithOrder) {
      result.add(member.key!);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("사회복무요원 근무표")),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
              child: Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                members.length,
                (n) => Member(
                  checkMember: checkingMember(n),
                  checked: checkedMember[n],
                  name: members[n],
                ),
              ),
            ),
          )),
          SliverToBoxAdapter(
              child: workingMembers >= 3
                  ? FittedBox(
                      child: stringToDataTable(
                          abcToName(workingMembers, mixUpOrder())))
                  : const SizedBox(
                      width: 0,
                      height: 0,
                    )),
        ],
      ),
    );
  }
}

class Member extends StatefulWidget {
  const Member(
      {super.key,
      required this.checkMember,
      required this.checked,
      required this.name});
  final String name;
  final bool checked;
  final Function() checkMember;

  @override
  State<Member> createState() => _MemberState();
}

class _MemberState extends State<Member> {
  @override
  Widget build(BuildContext context) {
    final checked = widget.checked;
    final name = widget.name;
    Color newColor = checked ? Colors.red : Colors.blue;
    return TweenAnimationBuilder<Color?>(
        tween: ColorTween(begin: Colors.blue, end: newColor),
        duration: const Duration(milliseconds: 500),
        builder: (_, Color? color, __) {
          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
            ),
            onPressed: () {
              widget.checkMember();
            },
            child: checked
                ? FittedBox(
                    child: Row(
                      children: [
                        const Icon(Icons.check),
                        const SizedBox(
                          width: 5,
                          height: 5,
                        ),
                        Text(name)
                      ],
                    ),
                  )
                : Text(name),
          );
        });
  }
}
