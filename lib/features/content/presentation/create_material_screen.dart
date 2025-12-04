import 'package:flutter/material.dart';
import '../data/material_model.dart';
import '../data/content_service.dart';

class CreateMaterialScreen extends StatefulWidget {
  final String courseId;
  const CreateMaterialScreen({super.key, required this.courseId});

  @override
  State<CreateMaterialScreen> createState() => _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends State<CreateMaterialScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _linkCtrl = TextEditingController(); // Nhập 1 link (demo), có thể nâng cấp thành list
  bool _isLoading = false;

  void _submit() async {
    if (_titleCtrl.text.isEmpty) return;

    setState(() => _isLoading = true);

    final material = MaterialModel(
      id: '',
      courseId: widget.courseId,
      title: _titleCtrl.text,
      description: _descCtrl.text,
      fileUrls: _linkCtrl.text.isNotEmpty ? [_linkCtrl.text] : [],
      createdAt: DateTime.now(),
    );

    await ContentService().createMaterial(material);

    if(mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đăng tài liệu!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng Tài Liệu Mới")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Tiêu đề", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Mô tả", border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _linkCtrl, decoration: const InputDecoration(labelText: "Link tài liệu (Drive/Web)", prefixIcon: Icon(Icons.link), border: OutlineInputBorder())),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                child: _isLoading ? const CircularProgressIndicator() : const Text("ĐĂNG TÀI LIỆU"),
              ),
            )
          ],
        ),
      ),
    );
  }
}