import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const schedule2 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|A|A, B||
11:30 ~ 13:00||||B
13:00 ~ 14:00|A|||
14:00 ~ 15:00|B|||
15:00 ~ 16:00|A|||
16:00 ~ 17:00|B|||''';

const schedule3 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|C|A, B||
11:30 ~ 13:00||||B
13:00 ~ 14:30|C|||
14:30 ~ 16:00|B||A, C|
15:30 ~ 17:00|A|||''';

const schedule4 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|C|A, B||
11:30 ~ 13:00||||D
13:00 ~ 14:00|C|A, B||
14:00 ~ 15:00|D|||
15:00 ~ 16:00|A||C,D|
16:00 ~ 17:00|B|||''';

const schedule5 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|E|A, B|C, D|
11:30 ~ 13:00||||D
13:00 ~ 14:00|A||C, E|
14:00 ~ 14:30|A|||
14:30 ~ 15:00|E|A, B||
15:00 ~ 15:30|D|||
15:30 ~ 16:00|B|||
16:00 ~ 17:00|B|||''';

const schedule6 = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|A|B, C|D, E|
11:30 ~ 13:00||||F
13:00 ~ 15:00|D|B, C||
15:00 ~ 17:00|E||A, F|''';

const schedule3Heating = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|A|B, C||
11:30 ~ 13:00||||A
13:00 ~ 15:00|B|||
15:00 ~ 17:00|C|||''';

const schedule4Heating = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
09:30 ~ 10:30|C||A, B|
10:30 ~ 11:30|A|C, D||
11:30 ~ 13:00||||B
13:00 ~ 15:00|C|||
15:00 ~ 17:00|D|||''';

const schedule5Heating = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|A|B, C|D, E|
11:30 ~ 13:00||||A
13:00 ~ 14:00|B|||
14:00 ~ 15:00|C|||
15:00 ~ 16:00|D|||
16:00 ~ 17:00|E|||''';

const schedule6Heating = '''|커뮤니티|대흥 순찰|새창 순찰|점심 교대
10:00 ~ 11:30|A|B, C|D, E|
11:30 ~ 13:00||||F
13:00 ~ 14:00|A|||
14:00 ~ 15:00|F|||
15:00 ~ 15:30|B|||
15:30 ~ 16:00|C|||
16:00 ~ 16:30|D|||
16:30 ~ 17:00|E|||''';

const List<String> schedules = [
  '',
  '',
  schedule2,
  schedule3,
  schedule4,
  schedule5,
  schedule6,
  '',
  ''
];

const List<String> schedulesHeating = [
  '',
  '',
  schedule2,
  schedule3Heating,
  schedule4Heating,
  schedule5Heating,
  schedule6Heating,
  '',
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

String abcToName(int n, List<String> order, bool isHeatingMode) {
  final abc = ["A", "B", "C", "D", "E", "F"];
  var s = isHeatingMode ? schedulesHeating[n] : schedules[n];
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

Future<Map<String, dynamic>> fetchNames() async {
  final response = await http.get(Uri.parse(
      'https://script.google.com/macros/s/AKfycbxaDh5OP-BGydVSiD1MvExE6KaB5Dup81MjhgTxw3nlfi_DxhJwC8gM8y0REY6_udoFgg/exec'));

  if (response.statusCode == 200) {
    Map<String, dynamic> l = jsonDecode(response.body);
    List<String> members = List<String>.from(l['data']);
    final checkedMember = List<bool>.generate(members.length, (index) => false);
    return {'members': members, 'checkedMember': checkedMember};
  } else {
    throw Exception('Failed to load names');
  }
}

void main() async {
  runApp(const MyApp());
}

Random R = Random();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uri url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/1U6hrcWxLr6UZVhYD7zQNm19nGDRZHFpg4JB-GQtvTEo/edit?usp=sharing');
  List<String> members = [];
  List<bool> checkedMember = [];
  int workingMembers = 0;
  bool isHeatingMode = false;

  @override
  void initState() {
    super.initState();
    fetchNames().then((data) {
      setState(() {
        members = data['members'];
        checkedMember = data['checkedMember'];
      });
    });
  }

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
    const Color lightSeedColor = Colors.cyan;
    const Color darkSeedColor = Colors.deepOrange;
    final ThemeData lightTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: lightSeedColor, brightness: Brightness.light),
      useMaterial3: true,
    );
    final ThemeData darkTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: darkSeedColor, brightness: Brightness.dark),
      useMaterial3: true,
    );
    return MaterialApp(
      theme: isHeatingMode ? darkTheme : lightTheme,
      home: members.isEmpty
          ? Scaffold(
              appBar: AppBar(
                title: const Text("사회복무요원 근무표"),
                actions: [
                  Switch(
                    value: isHeatingMode,
                    onChanged: (value) {
                      setState(() {
                        isHeatingMode = value;
                      });
                    },
                  ),
                ],
              ),
              body: const Center(child: CircularProgressIndicator()),
              floatingActionButton: Builder(
                builder: (context) {
                  return FloatingActionButton(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () async {
                      if (!await launchUrl(url)) {
                        throw Exception('Could not launch $url');
                      }
                    },
                  );
                }
              ),
            )
          : Scaffold(
              appBar: AppBar(
                title: const Text("사회복무요원 근무표"),
                actions: [
                  Switch(
                    value: isHeatingMode,
                    onChanged: (value) {
                      setState(() {
                        isHeatingMode = value;
                      });
                    },
                  ),
                ],
              ),
              floatingActionButton: Builder(
                builder: (context) {
                  return FloatingActionButton(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () async {
                      if (!await launchUrl(url)) {
                        throw Exception('Could not launch $url');
                      }
                    },
                  );
                }
              ),
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
                            isHeatingMode: isHeatingMode,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: workingMembers >= 3
                        ? FittedBox(
                            child: stringToDataTable(
                                abcToName(workingMembers, mixUpOrder(), isHeatingMode)))
                        : const SizedBox(
                            width: 0,
                            height: 0,
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

class Member extends StatefulWidget {
  const Member(
      {super.key,
      required this.checkMember,
      required this.checked,
      required this.name,
      required this.isHeatingMode});
  final String name;
  final bool checked;
  final Function() checkMember;
  final bool isHeatingMode;

  @override
  State<Member> createState() => _MemberState();
}

class _MemberState extends State<Member> {
  @override
  Widget build(BuildContext context) {
    final checked = widget.checked;
    final name = widget.name;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color backgroundColor = checked ? colorScheme.tertiary : colorScheme.primary;
    final Color textColor = checked ? colorScheme.onTertiary : colorScheme.onPrimary;
    
    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(begin: colorScheme.primary, end: backgroundColor),
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
                      Icon(Icons.check, color: textColor),
                      const SizedBox(
                        width: 5,
                        height: 5,
                      ),
                      Text(name, style: TextStyle(color: textColor))
                    ],
                  ),
                )
              : Text(name, style: TextStyle(color: textColor)),
        );
      },
    );
  }
}
