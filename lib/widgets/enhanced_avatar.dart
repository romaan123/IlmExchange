import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/profile_photo_service.dart';
import '../theme/app_theme.dart';

class EnhancedAvatar extends StatelessWidget {
  final String userId;
  final String name;
  final double radius;
  final bool showOnlineStatus;
  final bool isOnline;
  final VoidCallback? onTap;
  final String? photoUrl;

  const EnhancedAvatar({
    super.key,
    required this.userId,
    required this.name,
    this.radius = 24,
    this.showOnlineStatus = false,
    this.isOnline = false,
    this.onTap,
    this.photoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Main avatar
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderColor, width: 2),
            ),
            child: ClipOval(
              child:
                  photoUrl != null && photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildLoadingAvatar(),
                        errorWidget: (context, url, error) => _buildFallbackAvatar(),
                      )
                      : _buildFallbackAvatar(),
            ),
          ),

          // Online status indicator
          if (showOnlineStatus)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: radius * 0.6,
                height: radius * 0.6,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: Color(ProfilePhotoService.getAvatarColor(name)), shape: BoxShape.circle),
      child: Center(
        child: Text(
          ProfilePhotoService.getInitials(name),
          style: TextStyle(color: Colors.white, fontSize: radius * 0.8, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(color: AppTheme.backgroundColor, shape: BoxShape.circle),
      child: Center(
        child: SizedBox(
          width: radius,
          height: radius,
          child: const CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGreen),
        ),
      ),
    );
  }
}

class ProfilePhotoUploader extends StatefulWidget {
  final double radius;
  final String name;
  final String? currentPhotoUrl;
  final Function(String?)? onPhotoUpdated;

  const ProfilePhotoUploader({
    super.key,
    this.radius = 50,
    required this.name,
    this.currentPhotoUrl,
    this.onPhotoUpdated,
  });

  @override
  State<ProfilePhotoUploader> createState() => _ProfilePhotoUploaderState();
}

class _ProfilePhotoUploaderState extends State<ProfilePhotoUploader> {
  bool _isUploading = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _photoUrl = widget.currentPhotoUrl;
  }

  Future<void> _uploadPhoto() async {
    setState(() => _isUploading = true);

    try {
      debugPrint('🔄 Starting profile photo upload...');
      final url = await ProfilePhotoService.uploadProfilePhoto();
      if (url != null) {
        debugPrint('✅ Profile photo uploaded successfully: $url');
        setState(() => _photoUrl = url);
        widget.onPhotoUpdated?.call(url);

        // Force a refresh of the current user to get updated photo URL
        await FirebaseAuth.instance.currentUser?.reload();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } else {
        debugPrint('❌ Profile photo upload returned null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload photo. Please try again.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error uploading profile photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to upload photo: $e'), backgroundColor: AppTheme.errorRed));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deletePhoto() async {
    setState(() => _isUploading = true);

    try {
      final success = await ProfilePhotoService.deleteProfilePhoto();
      if (success) {
        setState(() => _photoUrl = null);
        widget.onPhotoUpdated?.call(null);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo removed successfully!'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to remove photo: $e'), backgroundColor: AppTheme.errorRed));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        EnhancedAvatar(userId: '', name: widget.name, radius: widget.radius, photoUrl: _photoUrl),

        if (_isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
              child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)),
            ),
          ),

        Positioned(
          bottom: 0,
          right: 0,
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: AppTheme.primaryGreen, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'upload',
                    child: Row(children: [Icon(Icons.upload), SizedBox(width: 8), Text('Upload Photo')]),
                  ),
                  if (_photoUrl != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: AppTheme.errorRed),
                          SizedBox(width: 8),
                          Text('Remove Photo'),
                        ],
                      ),
                    ),
                ],
            onSelected: (value) {
              if (value == 'upload') {
                _uploadPhoto();
              } else if (value == 'delete') {
                _deletePhoto();
              }
            },
          ),
        ),
      ],
    );
  }
}
