import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

//user page connected to backend
class _UsersPageState extends State<UsersPage> {
  List<Map<String, dynamic>> allUsers = [];
  List<String> userDocIds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users =
          snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
      final ids = snapshot.docs.map((doc) => doc.id).toList();
      setState(() {
        allUsers = users;
        userDocIds = ids;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching users: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> deleteUser(int index) async {
    try {
      final docId = userDocIds[index];
      await FirebaseFirestore.instance.collection('users').doc(docId).delete();
      setState(() {
        allUsers.removeAt(index);
        userDocIds.removeAt(index);
      });
    } catch (e) {
      debugPrint('Error deleting user: $e');
    }
  } //added delete

  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.teal,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          user['username'] ?? 'No Username',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(user['email'] ?? 'No Email')],
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () async {
            await deleteUser(index);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registered Users'),
        backgroundColor: Colors.teal,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : allUsers.isEmpty
              ? const Center(child: Text('No users found.'))
              : ListView.builder(
                itemCount: allUsers.length,
                itemBuilder:
                    (context, index) => _buildUserCard(allUsers[index], index),
              ),
    );
  }
}
