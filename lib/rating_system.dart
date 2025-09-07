import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/notification_service.dart';

class RatingSystem {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Show rating dialog
  static Future<void> showRatingDialog({
    required BuildContext context,
    required String userId,
    required String userName,
    required String skillTitle,
    String? sessionId,
  }) async {
    double rating = 0;
    String review = '';
    
    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Rate $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How was your experience with $skillTitle?'),
              const SizedBox(height: 16),
              
              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => rating = index + 1.0),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              
              const SizedBox(height: 16),
              
              // Review text
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Write a review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => review = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: rating > 0 ? () async {
                Navigator.pop(context);
                await submitRating(
                  userId: userId,
                  rating: rating,
                  review: review,
                  skillTitle: skillTitle,
                  sessionId: sessionId,
                );
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Rating submitted successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } : null,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // Submit rating to Firestore
  static Future<void> submitRating({
    required String userId,
    required double rating,
    required String review,
    required String skillTitle,
    String? sessionId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Check if user already rated this session/skill
      if (sessionId != null) {
        final existingRating = await _firestore
            .collection('reviews')
            .doc(userId)
            .collection('items')
            .where('sessionId', isEqualTo: sessionId)
            .where('reviewerId', isEqualTo: currentUser.uid)
            .get();
            
        if (existingRating.docs.isNotEmpty) {
          throw Exception('You have already rated this session');
        }
      }

      // Add review
      final reviewData = {
        'reviewerId': currentUser.uid,
        'reviewerName': currentUser.displayName ?? 'Anonymous',
        'rating': rating,
        'review': review,
        'skillTitle': skillTitle,
        'sessionId': sessionId,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('reviews')
          .doc(userId)
          .collection('items')
          .add(reviewData);

      // Update user's average rating
      await _updateUserAverageRating(userId);

      // Send notification
      await NotificationService.sendRatingNotification(
        receiverId: userId,
        raterName: currentUser.displayName ?? 'Someone',
        rating: rating,
        reviewId: userId, // This would be the actual review ID in production
      );

    } catch (e) {
      debugPrint('❌ Error submitting rating: $e');
      rethrow;
    }
  }

  // Update user's average rating
  static Future<void> _updateUserAverageRating(String userId) async {
    try {
      final reviews = await _firestore
          .collection('reviews')
          .doc(userId)
          .collection('items')
          .get();

      if (reviews.docs.isEmpty) return;

      double totalRating = 0;
      int count = 0;

      for (final doc in reviews.docs) {
        final data = doc.data();
        final rating = (data['rating'] ?? 0).toDouble();
        totalRating += rating;
        count++;
      }

      final averageRating = totalRating / count;

      await _firestore.collection('users').doc(userId).update({
        'averageRating': averageRating,
        'totalReviews': count,
      });

    } catch (e) {
      debugPrint('❌ Error updating average rating: $e');
    }
  }

  // Get user reviews
  static Stream<QuerySnapshot> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .doc(userId)
        .collection('items')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Build rating display widget
  static Widget buildRatingDisplay({
    required double rating,
    required int reviewCount,
    double size = 16,
    bool showCount = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (index) {
          return Icon(
            index < rating.floor() ? Icons.star :
            index < rating ? Icons.star_half : Icons.star_border,
            color: Colors.amber,
            size: size,
          );
        }),
        if (showCount) ...[
          const SizedBox(width: 4),
          Text(
            '${rating.toStringAsFixed(1)} ($reviewCount)',
            style: TextStyle(
              fontSize: size * 0.8,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ],
    );
  }

  // Build reviews list widget
  static Widget buildReviewsList({
    required String userId,
    required bool isDarkMode,
  }) {
    return StreamBuilder<QuerySnapshot>(
      stream: getUserReviews(userId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading reviews',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reviews = snapshot.data?.docs ?? [];

        if (reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_outline,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reviews yet',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final review = reviews[index].data() as Map<String, dynamic>;
            return _buildReviewCard(review, isDarkMode);
          },
        );
      },
    );
  }

  static Widget _buildReviewCard(Map<String, dynamic> review, bool isDarkMode) {
    final rating = (review['rating'] ?? 0).toDouble();
    final reviewText = review['review'] ?? '';
    final reviewerName = review['reviewerName'] ?? 'Anonymous';
    final skillTitle = review['skillTitle'] ?? '';
    final timestamp = review['timestamp'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reviewerName,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                buildRatingDisplay(
                  rating: rating,
                  reviewCount: 0,
                  showCount: false,
                ),
              ],
            ),
            if (skillTitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'For: $skillTitle',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (reviewText.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                reviewText,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ],
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(timestamp),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
