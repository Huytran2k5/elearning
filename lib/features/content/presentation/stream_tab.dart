import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

// --- IMPORT SERVICES AND MODELS ---
import '../../../core/constants/app_constants.dart';
import '../../../core/services/cloudinary_service.dart'; // Upload Service
import '../../auth/data/auth_service.dart';
import '../../course/data/group_model.dart';
import '../data/announcement_model.dart';
import '../data/comment_model.dart';
import '../data/content_service.dart';

class StreamTab extends StatefulWidget {
  final String courseId;
  final String userRole;

  const StreamTab({super.key, required this.courseId, required this.userRole});

  @override
  State<StreamTab> createState() => _StreamTabState();
}

class _StreamTabState extends State<StreamTab> {
  final _contentService = ContentService();
  final _currentUser = AuthService().currentUser;
  final _cloudinaryService = CloudinaryService(); // Image/File Upload Service

  // Post Form State
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();

  List<GroupModel> _availableGroups = [];
  List<String> _selectedGroupIds = []; // Empty = Send to all
  bool _isPosting = false;

  // File Upload State
  String? _uploadedFileUrl;
  String _uploadedFileName = "";
  bool _isUploadingFile = false;

  // Student post filter state
  String? _studentGroupId;
  bool get isInstructor => widget.userRole == AppConstants.roleInstructor;

  @override
  void initState() {
    super.initState();
    if (isInstructor) {
      _loadGroups();
    } else {
      _fetchStudentGroupId();
    }
  }

  // Get list of groups for instructor to select when posting
  void _loadGroups() async {
    final groups = await _contentService.getCourseGroups(widget.courseId);
    if(mounted) setState(() => _availableGroups = groups);
  }

  // Find which group the student belongs to for filtering posts
  void _fetchStudentGroupId() async {
    if (_currentUser == null) return;
    try {
      final enrollQuery = await FirebaseFirestore.instance
          .collection(AppConstants.collEnrollments)
          .where('courseId', isEqualTo: widget.courseId)
          .where('userId', isEqualTo: _currentUser!.uid)
          .limit(1)
          .get();

      if (enrollQuery.docs.isNotEmpty && mounted) {
        setState(() => _studentGroupId = enrollQuery.docs.first['groupId']);
      }
    } catch (_) {}
  }

  // --- LOGIC 1: SELECT AND UPLOAD FILE (CLOUDINARY) ---
  void _pickAndUploadFile() async {
    // Select any file (PDF, Doc, Image...)
    final file = await _cloudinaryService.pickFile(type: FileType.any);

    if (file != null) {
      setState(() {
        _isUploadingFile = true;
        _uploadedFileName = file.name;
      });

      // Upload to Cloudinary
      final url = await _cloudinaryService.uploadFile(file);

      setState(() {
        _isUploadingFile = false;
        if (url != null) {
          _uploadedFileUrl = url;
        } else {
          _uploadedFileName = ""; // Reset on error
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload failed. Check connection.")));
        }
      });
    }
  }

  // --- LOGIC 2: POST ANNOUNCEMENT ---
  void _postAnnouncement() async {
    if (_titleCtrl.text.isEmpty || _contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter title and content")));
      return;
    }

    setState(() => _isPosting = true);

    final newPost = AnnouncementModel(
      id: '',
      courseId: widget.courseId,
      authorName: _currentUser?.displayName ?? "Instructor",
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      attachmentUrl: _uploadedFileUrl, // Save Cloudinary file link
      targetGroupIds: _selectedGroupIds,
      createdAt: DateTime.now(),
      viewerIds: [],
      downloaderIds: [],
    );

    await _contentService.createAnnouncement(newPost);

    // Reset Form
    _titleCtrl.clear();
    _contentCtrl.clear();
    setState(() {
      _selectedGroupIds = [];
      _isPosting = false;
      _uploadedFileUrl = null;
      _uploadedFileName = "";
    });
    if(mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Input form (Instructor only)
        if (isInstructor) _buildPostInput(),

        // 2. Posts list
        Expanded(
          child: StreamBuilder<List<AnnouncementModel>>(
            // Call getAnnouncements with group filtering logic
            stream: _contentService.getAnnouncements(widget.courseId, _studentGroupId, isInstructor),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              final posts = snapshot.data ?? [];
              if (posts.isEmpty) return const Center(child: Text("No announcements yet."));

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];

                  // Tracking: If student hasn't viewed -> Mark as viewed
                  if (!isInstructor && _currentUser != null && !post.viewerIds.contains(_currentUser!.uid)) {
                    _contentService.markAsViewed(post.id, _currentUser!.uid);
                  }

                  return _buildPostCard(post);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // --- INPUT UI FOR INSTRUCTOR ---
  Widget _buildPostInput() {
    return ExpansionTile(
      title: const Text("Create new announcement", style: TextStyle(fontWeight: FontWeight.bold)),
      childrenPadding: const EdgeInsets.all(16),
      children: [
        TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Title", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: "Content", border: OutlineInputBorder())),
        const SizedBox(height: 10),

        // File selection button
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isUploadingFile ? null : _pickAndUploadFile,
              icon: _isUploadingFile
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.attach_file),
              label: Text(_isUploadingFile ? "Uploading..." : "Attach file"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _uploadedFileName.isNotEmpty ? _uploadedFileName : "No file selected",
                style: TextStyle(color: _uploadedFileName.isNotEmpty ? Colors.blue : Colors.grey, overflow: TextOverflow.ellipsis),
              ),
            ),
            if (_uploadedFileName.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => setState(() { _uploadedFileName = ""; _uploadedFileUrl = null; }),
              )
          ],
        ),

        const SizedBox(height: 10),
        // Select recipient groups
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text("All"),
              selected: _selectedGroupIds.isEmpty,
              onSelected: (val) => setState(() => _selectedGroupIds = []),
            ),
            ..._availableGroups.map((g) => FilterChip(
              label: Text(g.name),
              selected: _selectedGroupIds.contains(g.id),
              onSelected: (selected) {
                setState(() {
                  if (selected) { _selectedGroupIds.add(g.id); } else { _selectedGroupIds.remove(g.id); }
                });
              },
            )),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: (_isPosting || _isUploadingFile) ? null : _postAnnouncement,
            icon: const Icon(Icons.send),
            label: Text(_isPosting ? "Posting..." : "Post announcement"),
          ),
        )
      ],
    );
  }

  // --- POST DISPLAY UI ---
  Widget _buildPostCard(AnnouncementModel post) {
    bool isSeen = (_currentUser != null) && post.viewerIds.contains(_currentUser!.uid);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.campaign, color: Colors.white)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('dd/MM HH:mm').format(post.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const Spacer(),
                if (isInstructor)
                // Instructor clicks here to see who viewed/downloaded
                  InkWell(
                    onTap: () => _showTrackingDetails(context, post),
                    child: Chip(
                      label: Text("${post.viewerIds.length} views • ${post.downloaderIds.length} downloads"),
                      backgroundColor: Colors.blue[50],
                      labelStyle: TextStyle(color: Colors.blue[800], fontSize: 11),
                    ),
                  )
                else if (!isSeen)
                  const Chip(label: Text("NEW"), backgroundColor: Colors.red, labelStyle: TextStyle(color: Colors.white))
              ],
            ),
            const Divider(),

            // Content
            Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(post.content),

            // Attachment
            if (post.attachmentUrl != null && post.attachmentUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: InkWell(
                  onTap: () async {
                    // Track Download
                    if (!isInstructor && _currentUser != null) {
                      _contentService.markAsDownloaded(post.id, _currentUser!.uid);
                    }
                    launchUrl(Uri.parse(post.attachmentUrl!));
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Colors.blue),
                      Expanded(child: Text("Attachment (Click to open)", style: const TextStyle(color: Colors.blue, decoration: TextDecoration.underline), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),
            const Divider(),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isInstructor) Text(post.targetGroupIds.isEmpty ? "Sent to: All" : "Sent to: ${post.targetGroupIds.length} groups", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                TextButton.icon(onPressed: () => _showComments(context, post), icon: const Icon(Icons.comment), label: Text("${post.commentCount} Comments"))
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- TRACKING DETAILS MODAL ---
  void _showTrackingDetails(BuildContext context, AnnouncementModel post) {
    showModalBottomSheet(
      context: context,
      builder: (context) => DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(tabs: [Tab(text: "Viewed"), Tab(text: "Downloaded file")]),
            Expanded(
              child: TabBarView(
                children: [
                  _buildUserList(post.viewerIds, "No one has viewed yet."),
                  _buildUserList(post.downloaderIds, "No one has downloaded yet."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList(List<String> userIds, String emptyMsg) {
    if (userIds.isEmpty) return Center(child: Text(emptyMsg));
    return ListView.builder(
      itemCount: userIds.length,
      itemBuilder: (context, index) {
        // Get User name from ID
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection(AppConstants.collUsers).doc(userIds[index]).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const ListTile(title: Text("..."));
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            return ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: Text(data?['displayName'] ?? "Unknown"),
              subtitle: Text(data?['email'] ?? ""),
            );
          },
        );
      },
    );
  }

  void _showComments(BuildContext context, AnnouncementModel post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommentsSheet(postId: post.id),
    );
  }
}

// --- CHILD WIDGET: COMMENTS ---
class _CommentsSheet extends StatefulWidget {
  final String postId;
  const _CommentsSheet({required this.postId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentCtrl = TextEditingController();
  final _contentService = ContentService();
  final _currentUser = AuthService().currentUser!;

  // --- SEND COMMENT LOGIC (FIX USER NAME) ---
  void _sendComment() async {
    if (_commentCtrl.text.isEmpty) return;

    String finalName = "User";
    String finalUserId = _currentUser.uid;

    try {
      // Find real name in Firestore (prioritize Email)
      if (_currentUser.email != null) {
        final userQuery = await FirebaseFirestore.instance
            .collection(AppConstants.collUsers)
            .where('email', isEqualTo: _currentUser.email)
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          finalName = userQuery.docs.first.data()['displayName'] ?? "User";
          finalUserId = userQuery.docs.first.id;
        }
      }
    } catch (_) {}

    final comment = CommentModel(
      id: '',
      announcementId: widget.postId,
      userId: finalUserId,
      userName: finalName, // <-- Real name
      content: _commentCtrl.text.trim(),
      createdAt: DateTime.now(),
    );

    _contentService.addComment(comment);

    if (mounted) {
      _commentCtrl.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: _contentService.getComments(widget.postId),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!;
                  if (comments.isEmpty) return const Center(child: Text("No comments yet."));

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return ListTile(
                        leading: CircleAvatar(child: Text(c.userName.isNotEmpty ? c.userName[0] : "U")),
                        title: Text(c.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.content),
                            Text(DateFormat('dd/MM HH:mm').format(c.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Row(
              children: [
                Expanded(child: TextField(controller: _commentCtrl, decoration: const InputDecoration(hintText: "Write a comment..."))),
                IconButton(onPressed: _sendComment, icon: const Icon(Icons.send, color: Colors.blue)),
              ],
            )
          ],
        ),
      ),
    );
  }
}