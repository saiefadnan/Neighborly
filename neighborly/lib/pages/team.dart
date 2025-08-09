import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

//Backend Provided
class TeamPage extends StatefulWidget {
  const TeamPage({super.key});

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController postController = TextEditingController();

  Future<void> addTeamMember() async {
    final name = nameController.text.trim();
    final age = int.tryParse(ageController.text.trim());
    final post = postController.text.trim();

    if (name.isEmpty || age == null || post.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly.")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("team_members").add({
      "name": name,
      "age": age,
      "post": post,
      "timestamp": FieldValue.serverTimestamp(),
    });

    nameController.clear();
    ageController.clear();
    postController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Team member added.")),
    );
    setState(() {});
  }

  Widget buildTeamList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('team_members')
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error loading team.');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [Colors.teal.shade300, Colors.green.shade300],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    member['name'][0].toUpperCase(),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                title: Text(
                  member['name'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Post: ${member['post']}",
                        style: const TextStyle(color: Colors.white70)),
                    Text("Age: ${member['age']}",
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add Team Member",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: "Name",
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Age",
              prefixIcon: const Icon(Icons.cake),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: postController,
            decoration: InputDecoration(
              labelText: "Post",
              prefixIcon: const Icon(Icons.work_outline),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: addTeamMember,
              icon: const Icon(Icons.add),
              label: const Text("Add Member"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        title: const Text("Team Management"),
        backgroundColor: Colors.teal,
      ),
      body: PageView(
        scrollDirection: Axis.horizontal,
        children: [
          // Page 1: Add Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SizedBox(
                width: 500,
                child: buildForm(),
              ),
            ),
          ),
          // Page 2: Team List
          Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 24, bottom: 12),
                child: Text(
                  "Your Team",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              Expanded(child: buildTeamList()),
            ],
          ),
        ],
      ),
    );
  }
}
