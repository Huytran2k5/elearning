import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart'; // Chọn file
import '../../../core/services/cloudinary_service.dart'; // Upload file
import '../../../core/widgets/user_avatar.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/data/user_model.dart';
import '../../auth/presentation/login_screen.dart';
import '../data/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  final _cloudinaryService = CloudinaryService(); // Service mới
  late UserModel _currentUser;
  bool _isUploading = false; // Trạng thái đang upload

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
  }

  void _handleLogout() async {
    await AuthService().signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  // --- HÀM ĐỔI AVATAR MỚI ---
  void _changeAvatar() async {
    // 1. Chọn ảnh
    final file = await _cloudinaryService.pickFile(type: FileType.image);

    if (file != null) {
      setState(() => _isUploading = true);

      // 2. Upload lên Cloudinary
      final url = await _cloudinaryService.uploadFile(file);

      if (url != null) {
        // 3. Update Firestore
        await _profileService.updateAvatar(_currentUser.id, url);

        // 4. Update UI ngay lập tức
        setState(() {
          _currentUser = _currentUser.copyWith(avatarUrl: url);
          _isUploading = false;
        });

        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã cập nhật Avatar!")));
      } else {
        setState(() => _isUploading = false);
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi upload ảnh!")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // --- AVATAR ---
            Center(
              child: Stack(
                children: [
                  UserAvatar(
                    avatarUrl: _currentUser.avatarUrl,
                    userName: _currentUser.displayName,
                    radius: 60,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      radius: 20,
                      child: _isUploading
                          ? const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : IconButton(
                        icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        onPressed: _changeAvatar, // Gọi hàm upload
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- THÔNG TIN ---
            _buildInfoTile("Name", _currentUser.displayName ?? "No Name", Icons.person),
            _buildInfoTile("Email", _currentUser.email, Icons.email),
            _buildInfoTile("Role", _currentUser.role, Icons.security),
            if (_currentUser.studentCode != null)
              _buildInfoTile("Mã Sinh viên", _currentUser.studentCode!, Icons.badge),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: TextEditingController(text: value),
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
    );
  }
}