import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SelectDoctorScreen extends StatefulWidget {
  const SelectDoctorScreen({super.key});

  @override
  State<SelectDoctorScreen> createState() => _SelectDoctorScreenState();
}

class _SelectDoctorScreenState extends State<SelectDoctorScreen> {
  List<dynamic> doctors = [];
  List<dynamic> filtered = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadDoctors();
  }

  Future<void> loadDoctors() async {
    final all = await ApiService.getAllUsers();
    final list = all.where((u) => u['role'] == 'doctor').toList();

    setState(() {
      doctors = list;
      filtered = list;
      loading = false;
    });
  }

  void search(String q) {
    q = q.toLowerCase();
    setState(() {
      filtered = doctors.where((d) {
        return d["full_name"].toLowerCase().contains(q) ||
            d["email"].toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Select Doctor",
          style: TextStyle(
            fontFamily: "Baloo",
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF7B1FA2),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Color(0xFF7B1FA2)),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFDF7FF), Color(0xFFF3E8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 110,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                  )
                ],
              ),
              child: TextField(
                onChanged: search,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: Colors.deepPurple),
                  hintText: "Search doctors...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Doctors List
          Positioned.fill(
            top: 170,
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor:
                                  Colors.deepPurple.withOpacity(.2),
                              child: Text(
                                doc['full_name'][0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.deepPurple,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            const SizedBox(width: 15),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    doc["full_name"],
                                    style: const TextStyle(
                                      fontFamily: "Baloo",
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(doc["email"]),
                                ],
                              ),
                            ),

                            // Buttons
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.group,
                                      color: Colors.deepPurple),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/doctorStudents",
                                      arguments: {
                                        "doctorId": doc["id"],
                                        "doctorName": doc["full_name"],
                                      },
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.link,
                                      color: Colors.teal),
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/assignStudent",
                                      arguments: {
                                        "doctorId": doc["id"],
                                        "doctorName": doc["full_name"],
                                      },
                                    );
                                  },
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
