
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MedicineApp());
}

class Medicine {
  String name;
  String dosage;
  TimeOfDay time;
  DateTime startDate;
  DateTime endDate;
  bool taken;
  String lastAlert;

  Medicine({
    required this.name,
    required this.dosage,
    required this.time,
    required this.startDate,
    required this.endDate,
    this.taken = false,
    this.lastAlert = '',
  });
}

class MedicineApp extends StatelessWidget {
  const MedicineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Medicine Reminder',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
        home: const Dashboard(),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  List<Medicine> medicines = [];

  Timer? reminderTimer;

  @override
  void initState() {
    super.initState();

    reminderTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        checkMedicineTime();
      },
    );
   }

  @override
  void dispose() {
    reminderTimer?.cancel();
    super.dispose();
  }

  void checkMedicineTime() {
    final now = DateTime.now();

    for (var medicine in medicines) {
      final today = DateTime(now.year, now.month, now.day);

      final start = DateTime(
        medicine.startDate.year,
        medicine.startDate.month,
        medicine.startDate.day,
      );

      final end = DateTime(
        medicine.endDate.year,
        medicine.endDate.month,
        medicine.endDate.day,
      );

      if (today.isBefore(start) || today.isAfter(end)) {
        continue;
      }

      if (now.hour == medicine.time.hour &&
          now.minute == medicine.time.minute) {
        String todayKey =
            '${now.year}-${now.month}-${now.day}';

        if (medicine.lastAlert != todayKey &&
            !medicine.taken) {
          medicine.lastAlert = todayKey;

          SystemSound.play(SystemSoundType.alert);

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('🔔 Medicine Reminder'),
                content: Text(
                  'Time to take ${medicine.name}\n'
                  'Dosage: ${medicine.dosage}',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }
      }
    }
  }

  String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Future<DateTime?> pickDate(
    BuildContext context, {
    required DateTime firstDate,
    required DateTime initialDate,
  }) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime(2035),
    );
  }

  void addMedicine() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();

    TimeOfDay? selectedTime;
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Medicine'),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Medicine Name',
                          prefixIcon: Icon(Icons.medication),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosage',
                          hintText: 'Example: 1 Tablet',
                          prefixIcon: Icon(Icons.local_pharmacy),
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.now(),
                            );

                            if (time != null) {
                              setDialogState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            selectedTime == null
                                ? 'Select Medicine Time'
                                : 'Time: ${selectedTime!.format(context)}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await pickDate(
                              context,
                              firstDate: DateTime.now(),
                              initialDate: DateTime.now(),
                            );

                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                                if (endDate != null &&
                                    endDate!.isBefore(date)) {
                                  endDate = null;
                                }
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            startDate == null
                                ? 'Select Start Date'
                                : 'Start: ${formatDate(startDate!)}',
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await pickDate(
                              context,
                              firstDate: startDate ?? DateTime.now(),
                              initialDate: endDate ?? startDate ?? DateTime.now(),
                            );

                            if (date != null) {
                              setDialogState(() {
                                endDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.event),
                          label: Text(
                            endDate == null
                                ? 'Select End Date'
                                : 'End: ${formatDate(endDate!)}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty ||
                        dosageController.text.trim().isEmpty ||
                        selectedTime == null ||
                        startDate == null ||
                        endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill all details!'),
                        ),
                      );
                      return;
                    }

                    if (endDate!.isBefore(startDate!)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'End date cannot be before start date!',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      medicines.add(
                        Medicine(
                          name: nameController.text.trim(),
                          dosage: dosageController.text.trim(),
                          time: selectedTime!,
                          startDate: startDate!,
                          endDate: endDate!,
                        ),
                      );
                    });

                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Save Medicine'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      dosageController.dispose();
    });
  }

  void deleteMedicine(int index) {
    setState(() {
      medicines.removeAt(index);
    });
  }

  Widget sidebarItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
    );
  }

  Widget summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, color: Colors.teal, size: 38),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 230,
            color: const Color(0xFF00695C),
            child: Column(
              children: [
                const SizedBox(height: 35),

                const Icon(
                  Icons.medical_services,
                  color: Colors.white,
                  size: 55,
                ),

                const SizedBox(height: 12),

                const Text(
                  'MEDI REMINDER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 50),

                sidebarItem(Icons.dashboard, 'Dashboard'),
                sidebarItem(Icons.medication, 'My Medicines'),
                sidebarItem(Icons.notifications, 'Reminders'),

                const Spacer(),

                sidebarItem(Icons.settings, 'Settings'),

                const SizedBox(height: 25),
              ],
            ),
          ),

          // Dashboard content
          Expanded(
            child: Container(
              color: const Color(0xFFF3F7F7),
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medicine Reminder Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Manage your medicine schedule and dates',
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  // Summary cards
                  Row(
                    children: [
                      summaryCard(
                        'Total Medicines',
                        medicines.length.toString(),
                        Icons.medication,
                      ),

                      const SizedBox(width: 20),

                      summaryCard(
                        'Taken',
                        medicines
                            .where((m) => m.taken)
                            .length
                            .toString(),
                        Icons.check_circle,
                      ),

                      const SizedBox(width: 20),

                      summaryCard(
                        'Pending',
                        medicines
                            .where((m) => !m.taken)
                            .length
                            .toString(),
                        Icons.alarm,
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Medicine heading
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Medicines',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      ElevatedButton.icon(
                        onPressed: addMedicine,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Medicine'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Medicine table
                  Expanded(
                    child: Card(
                      elevation: 2,
                      child: medicines.isEmpty
                          ? const Center(
                              child: Text(
                                'No Medicines Added Yet!',
                                style: TextStyle(fontSize: 18),
                              ),
                            )
                          : SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(
                                      label: Text('Medicine Name'),
                                    ),
                                    DataColumn(
                                      label: Text('Dosage'),
                                    ),
                                    DataColumn(
                                      label: Text('Time'),
                                    ),
                                    DataColumn(
                                      label: Text('Start Date'),
                                    ),
                                    DataColumn(
                                      label: Text('End Date'),
                                    ),
                                    DataColumn(
                                      label: Text('Taken'),
                                    ),
                                    DataColumn(
                                      label: Text('Delete'),
                                    ),
                                  ],

                                  rows: List.generate(
                                    medicines.length,
                                    (index) {
                                      final m = medicines[index];

                                      return DataRow(
                                        cells: [
                                          DataCell(Text(m.name)),
                                          DataCell(Text(m.dosage)),
                                          DataCell(
                                            Text(m.time.format(context)),
                                          ),
                                          DataCell(
                                            Text(formatDate(m.startDate)),
                                          ),
                                          DataCell(
                                            Text(formatDate(m.endDate)),
                                          ),
                                          DataCell(
                                            Checkbox(
                                              value: m.taken,
                                              onChanged: (value) {
                                                setState(() {
                                                  m.taken = value ?? false;
                                                });
                                              },
                                            ),
                                          ),
                                          DataCell(
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                deleteMedicine(index);
                                              },
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
