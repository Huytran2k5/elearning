import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../auth/data/user_model.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../student/data/student_stats_service.dart';
import 'student_home.dart';
import '../../../core/widgets/offline_indicator.dart'; // Import offline indicator

class StudentDashboardScreen extends StatefulWidget {
  final UserModel user;
  const StudentDashboardScreen({super.key, required this.user});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  int _currentIndex = 0;
  final _statsService = StudentStatsService();

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

  // Hàm để reload lại Future (Kéo để làm mới)
  Future<void> _refreshData() async {
    setState(() {
      // Gọi setState rỗng để trigger build lại => FutureBuilder sẽ chạy lại
    });
  }

  @override
  Widget build(BuildContext context) {
    // Danh sách các màn hình con
    final List<Widget> pages = [
      _buildOverviewTab(), // Tab 0: Dashboard
      StudentHome(
          user: widget.user,
          isEmbedded: true), // Tab 1: Danh sách khóa học (nhúng)
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue[800],
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: "Tổng quan"),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: "Khóa học"),
        ],
      ),
    );
  }

  // --- TAB 1: TỔNG QUAN ---
  Widget _buildOverviewTab() {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bảng điều khiển",
                style: TextStyle(fontSize: 14, color: Colors.white70)),
            Text(widget.user.displayName ?? "Sinh viên",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _handleLogout, icon: const Icon(Icons.logout))
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // 🌐 Offline Indicator
          const OfflineIndicator(),

          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: FutureBuilder<StudentStats>(
                future: _statsService.getStats(widget.user.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());

                  // Xử lý dữ liệu an toàn
                  final stats = snapshot.data ??
                      StudentStats(
                          assignmentsPending: 0,
                          assignmentsLate: 0,
                          assignmentsDone: 0,
                          avgQuizScore: 0,
                          upcomingDeadlines: []);

                  // 2. Sử dụng SingleChildScrollView với physics để luôn kéo được
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Thống kê nhanh ---
                        Row(
                          children: [
                            _buildStatCard(
                                "Chờ nộp",
                                "${stats.assignmentsPending}",
                                Colors.orange,
                                Icons.access_time),
                            const SizedBox(width: 10),
                            _buildStatCard(
                                "Trễ hạn",
                                "${stats.assignmentsLate}",
                                Colors.red,
                                Icons.warning_amber),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildStatCard("Đã nộp", "${stats.assignmentsDone}",
                                Colors.green, Icons.check_circle_outline),
                            const SizedBox(width: 10),
                            _buildStatCard(
                                "Điểm Quiz",
                                stats.avgQuizScore.toStringAsFixed(1),
                                Colors.purple,
                                Icons.quiz),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- Timeline ---
                        const Text("Sắp đến hạn (Timeline)",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),

                        if (stats.upcomingDeadlines.isEmpty)
                          Card(
                              elevation: 0,
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.event_available,
                                          size: 40, color: Colors.green[200]),
                                      const SizedBox(height: 10),
                                      const Text(
                                          "Tuyệt vời! Không có bài tập nào sắp tới."),
                                    ],
                                  ),
                                ),
                              ))
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stats.upcomingDeadlines.length,
                            itemBuilder: (context, index) {
                              final item = stats.upcomingDeadlines[index];
                              final daysLeft =
                                  item.date.difference(DateTime.now()).inDays;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 1,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                child: Padding(
                                  // Dùng Padding thay vì ListTile
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      // 1. Ô Ngày Tháng (Tùy chỉnh gọn gàng)
                                      Container(
                                        width: 50, // Cố định chiều rộng
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(8)),
                                        child: Column(
                                          children: [
                                            Text(
                                                DateFormat('dd')
                                                    .format(item.date),
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.blue[900])),
                                            Text(
                                                DateFormat('MMM')
                                                    .format(item.date),
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      // 2. Nội dung chính
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(item.title,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15)),
                                            const SizedBox(height: 4),
                                            Text(
                                                "${DateFormat('HH:mm').format(item.date)} • ${item.type}",
                                                style: TextStyle(
                                                    color: item.date
                                                                .difference(
                                                                    DateTime
                                                                        .now())
                                                                .inDays <
                                                            1
                                                        ? Colors.red
                                                        : Colors.grey,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),

                                      // 3. Trailing (Ngày còn lại)
                                      if (daysLeft < 1)
                                        const Chip(
                                            label: Text("Gấp",
                                                style: TextStyle(fontSize: 10)),
                                            backgroundColor: Colors.red,
                                            labelStyle:
                                                TextStyle(color: Colors.white),
                                            padding: EdgeInsets.zero,
                                            visualDensity:
                                                VisualDensity.compact)
                                      else
                                        Text("$daysLeft ngày",
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2))
          ],
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color),
                Text(count,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(title,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
