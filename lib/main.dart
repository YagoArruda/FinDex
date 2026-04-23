import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class Expense {
  String title;
  String type;
  double value;
  DateTime date;

  Expense({
    required this.title,
    required this.type,
    required this.value,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        "title": title,
        "type": type,
        "value": value,
        "date": date.toIso8601String(),
      };

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      title: json["title"],
      type: json["type"],
      value: json["value"],
      date: DateTime.parse(json["date"]),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: ExpensePage());
  }
}

class ExpensePage extends StatefulWidget {
  const ExpensePage({super.key});

  @override
  State<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends State<ExpensePage> {
  Map<String, double> expenses = {
    "Comida": 0,
    "Transporte": 0,
    "Lazer": 0,
  };

  List<Expense> expenseList = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  // ==========================
  // SALVAR / CARREGAR
  // ==========================

  Future<void> saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> data =
        expenseList.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList("expenses", data);
  }

  Future<void> loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? data = prefs.getStringList("expenses");

    if (data != null) {
      expenseList = data
          .map((e) => Expense.fromJson(jsonDecode(e)))
          .toList();

      rebuildMap();
    }
  }

  void rebuildMap() {
    expenses = {
      "Comida": 0,
      "Transporte": 0,
      "Lazer": 0,
    };

    for (var e in expenseList) {
      expenses[e.type] = expenses[e.type]! + e.value;
    }

    setState(() {});
  }

  // ==========================
  // MODAL
  // ==========================

  void openAddModal() {
    TextEditingController titleController = TextEditingController();
    TextEditingController valueController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    String selectedType = "Comida";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Novo Gasto",
                      style: TextStyle(fontSize: 18)),

                  const SizedBox(height: 10),

                  TextField(
                    controller: titleController,
                    decoration:
                        const InputDecoration(labelText: "Nome"),
                  ),

                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: "Valor"),
                  ),

                  const SizedBox(height: 10),

                  DropdownButton<String>(
                    value: selectedType,
                    items: ["Comida", "Transporte", "Lazer"]
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setModalState(() {
                        selectedType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}"),
                      TextButton(
                        onPressed: () async {
                          DateTime? picked =
                              await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );

                          if (picked != null) {
                            setModalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: const Text("Selecionar data"),
                      )
                    ],
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () async {
                      double value =
                          double.tryParse(valueController.text) ??
                              0;

                      if (value > 0) {
                        expenseList.add(Expense(
                          title: titleController.text,
                          type: selectedType,
                          value: value,
                          date: selectedDate,
                        ));

                        rebuildMap();
                        await saveExpenses();

                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Adicionar"),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================
  // GRÁFICO
  // ==========================

  List<PieChartSectionData> getSections() {
    double total = expenses.values.fold(0, (a, b) => a + b);

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade300,
          title: "",
          radius: 55,
        ),
      ];
    }

    return expenses.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        color: getColor(e.key),
        title: "",
        radius: 55,
        borderSide: const BorderSide(
          color: Colors.white,
          width: 5,
        ),
      );
    }).toList();
  }

  Color getColor(String type) {
    switch (type) {
      case "Comida":
        return const Color(0xFF9C27B0);
      case "Transporte":
        return const Color(0xFFFF9800);
      case "Lazer":
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  Widget buildLegend() {
    double total = expenses.values.fold(0, (a, b) => a + b);

    return Column(
      children: expenses.entries.map((e) {
        double percent =
            total == 0 ? 0 : (e.value / total) * 100;

        return Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: getColor(e.key),
                  borderRadius:
                      BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${e.key} - ${percent.toStringAsFixed(1)}%",
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ==========================
  // UI
  // ==========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text("Controle de Gastos")),

      floatingActionButton: FloatingActionButton(
        onPressed: openAddModal,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          const SizedBox(height: 20),

          SizedBox(
            height: 250,
            child: PieChart(
              PieChartData(
                sections: getSections(),
                centerSpaceRadius: 65,
                sectionsSpace: 6,
                borderData:
                    FlBorderData(show: false),
              ),
            ),
          ),

          const SizedBox(height: 10),

          buildLegend(),
        ],
      ),
    );
  }
}