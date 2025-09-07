import 'package:flutter/material.dart';

class PostOfferScreen extends StatefulWidget {
  const PostOfferScreen({super.key});

  @override
  State<PostOfferScreen> createState() => _PostOfferScreenState();
}

class _PostOfferScreenState extends State<PostOfferScreen> {
  bool isOffer = true;
  final TextEditingController _skillController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  void _submitPost() {
    final skill = _skillController.text.trim();
    final desc = _descController.text.trim();

    if (skill.isEmpty || desc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please fill in all fields.")));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(isOffer ? "Skill offer posted successfully!" : "Skill request submitted!")));

    _skillController.clear();
    _descController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Post Offer / Request"), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            ToggleButtons(
              isSelected: [isOffer, !isOffer],
              onPressed: (index) => setState(() => isOffer = index == 0),
              selectedColor: Colors.white,
              color: Colors.deepPurple,
              fillColor: Colors.deepPurple,
              borderRadius: BorderRadius.circular(8),
              children: [
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Offer")),
                Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text("Request")),
              ],
            ),
            SizedBox(height: 20),
            TextField(
              controller: _skillController,
              decoration: InputDecoration(
                labelText: "Skill",
                hintText: "e.g. Guitar, Web Design",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "Describe what you can teach or want to learn...",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: _submitPost,
              icon: Icon(Icons.check_circle_outline),
              label: Text("Submit"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
