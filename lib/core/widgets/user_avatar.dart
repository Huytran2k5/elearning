import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? userName;
  final double radius;
  final Color? backgroundColor;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    this.userName,
    this.radius = 20,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to check if there's a valid image
    final bool hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;

    // Get first letter (If no name, use "U" - User)
    final String initial = (userName != null && userName!.isNotEmpty)
        ? userName![0].toUpperCase()
        : "U";

    return CircleAvatar(
      radius: radius,
      backgroundColor: hasImage ? Colors.transparent : (backgroundColor ?? Colors.blue),
      backgroundImage: hasImage ? NetworkImage(avatarUrl!) : null,
      child: hasImage
          ? null // If there's an image, don't show text
          : Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius, // Font size proportional to radius
        ),
      ),
    );
  }
}