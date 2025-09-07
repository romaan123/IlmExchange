import 'package:flutter/material.dart';

class RatingsReviewsScreen extends StatefulWidget {
  final String sessionWith;

  const RatingsReviewsScreen({super.key, required this.sessionWith});

  @override
  State<RatingsReviewsScreen> createState() => _RatingsReviewsScreenState();
}

class _RatingsReviewsScreenState extends State<RatingsReviewsScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  void _submitReview() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Please select a rating")));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Thank you for rating your session with ${widget.sessionWith}!")));

    setState(() {
      _rating = 0;
      _reviewController.clear();
    });
  }

  Widget _buildStar(int index) {
    return IconButton(
      icon: Icon(index <= _rating ? Icons.star : Icons.star_border, color: Colors.amber, size: 36),
      onPressed: () {
        setState(() {
          _rating = index;
        });
      },
      splashRadius: 24,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rate & Review"), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Rate your session with ${widget.sessionWith}:", style: TextStyle(fontSize: 18)),
            SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: List.generate(5, (i) => _buildStar(i + 1))),
            SizedBox(height: 24),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                labelText: "Write a review (optional)",
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text("Submit"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
