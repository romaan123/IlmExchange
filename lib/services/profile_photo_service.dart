import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class ProfilePhotoService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();

  // Upload profile photo
  static Future<String?> uploadProfilePhoto() async {
    try {
      debugPrint('🔄 Starting profile photo upload...');
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ No authenticated user found');
        return null;
      }

      debugPrint('📱 Picking image from gallery...');
      // Pick image from gallery with optimized settings
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300, // Reduced size for faster upload
        maxHeight: 300, // Reduced size for faster upload
        imageQuality: 70, // Reduced quality for faster upload
      );

      if (image == null) {
        debugPrint('❌ No image selected');
        return null;
      }

      debugPrint('✅ Image selected: ${image.name}');

      // Create storage reference
      debugPrint('📁 Creating storage reference...');
      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');

      // Upload file with timeout
      debugPrint('⬆️ Starting file upload...');
      UploadTask uploadTask;
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        debugPrint('📊 Image size: ${bytes.length} bytes');
        uploadTask = ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg', cacheControl: 'max-age=3600'));
      } else {
        uploadTask = ref.putFile(
          File(image.path),
          SettableMetadata(contentType: 'image/jpeg', cacheControl: 'max-age=3600'),
        );
      }

      // Add timeout to prevent hanging
      final snapshot = await uploadTask.timeout(const Duration(seconds: 30));
      debugPrint('✅ Upload completed');

      final downloadUrl = await snapshot.ref.getDownloadURL();
      debugPrint('🔗 Download URL obtained: $downloadUrl');

      // Update user profile in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Update Firebase Auth profile
      await user.updatePhotoURL(downloadUrl);

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile photo: $e');
      return null;
    }
  }

  // Get profile photo URL
  static Future<String?> getProfilePhotoUrl(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['photoURL'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting profile photo: $e');
      return null;
    }
  }

  // Delete profile photo
  static Future<bool> deleteProfilePhoto() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Delete from storage
      final ref = _storage.ref().child('profile_photos/${user.uid}.jpg');
      await ref.delete();

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoURL': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Firebase Auth profile
      await user.updatePhotoURL(null);

      return true;
    } catch (e) {
      debugPrint('Error deleting profile photo: $e');
      return false;
    }
  }

  // Get initials for fallback avatar
  static String getInitials(String name) {
    if (name.isEmpty) return 'U';
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    }
    return '${words[0][0]}${words[words.length - 1][0]}'.toUpperCase();
  }

  // Generate avatar color based on name
  static int getAvatarColor(String name) {
    final colors = [
      0xFF1DBF73, // Primary green
      0xFF446EE7, // Blue
      0xFFFF7640, // Orange
      0xFF9C27B0, // Purple
      0xFFE91E63, // Pink
      0xFF00BCD4, // Cyan
      0xFF4CAF50, // Green
      0xFFFF9800, // Amber
    ];

    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}
