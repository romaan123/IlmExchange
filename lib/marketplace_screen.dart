import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  bool showOffers = false; // false means show 'requests'
  String searchQuery = '';
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  Stream<List<Map<String, dynamic>>> getSkillPostsStream() {
    return FirebaseFirestore.instance
        .collection('skills')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => doc.data()..['id'] = doc.id)
                  .where((data) => data['userId'] != currentUserId)
                  .where((data) => data['type'] == (showOffers ? 'offer' : 'request'))
                  .where(
                    (data) =>
                        data['title']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
                        data['exchangeSkill']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true ||
                        data['userEmail']?.toString().toLowerCase().contains(searchQuery.toLowerCase()) == true,
                  )
                  .toList(),
        );
  }

  Widget _buildSkillCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.person)),
        title: Text(data['userEmail'] ?? 'Unknown'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Title: ${data['title'] ?? 'N/A'}"),
            Text("Can Offer: ${data['description'] ?? ''}"),
            const SizedBox(height: 6),
            Text("Wants in Return: ${data['exchangeSkill'] ?? ''}"),
            Text("Exchange Description: ${data['exchangeDescription'] ?? ''}"),
            const SizedBox(height: 4),
            Text("Experience: ${data['experienceLevel'] ?? ''}, Duration: ${data['duration'] ?? ''}"),
            Text("Mode: ${data['mode'] ?? ''}, Location: ${data['location'] ?? ''}"),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Feature Coming Soon!")));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
          child: Text(showOffers ? "Request" : "Offer"),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search skill or user...",
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (val) => setState(() => searchQuery = val),
      ),
    );
  }

  Widget _buildToggleBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("Requests"),
          selected: !showOffers,
          onSelected: (val) => setState(() => showOffers = false),
          selectedColor: Colors.deepPurple.shade200,
        ),
        const SizedBox(width: 10),
        ChoiceChip(
          label: const Text("Offers"),
          selected: showOffers,
          onSelected: (val) => setState(() => showOffers = true),
          selectedColor: Colors.deepPurple.shade200,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skill Marketplace"), backgroundColor: Colors.deepPurple),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildToggleBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: getSkillPostsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading posts"));
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text("No results found."));
                }

                return ListView(children: data.map(_buildSkillCard).toList());
              },
            ),
          ),
        ],
      ),
    );
  }
}
