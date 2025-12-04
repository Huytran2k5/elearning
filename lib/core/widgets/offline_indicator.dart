import 'package:flutter/material.dart';
import '../services/network_service.dart';
import '../services/sync_queue_service.dart';

/// Widget hiển thị trạng thái offline/online và pending sync
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({super.key});

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _updatePendingCount();

    // Update count when network status changes
    NetworkService().isOnline.addListener(_updatePendingCount);
  }

  @override
  void dispose() {
    NetworkService().isOnline.removeListener(_updatePendingCount);
    super.dispose();
  }

  void _updatePendingCount() async {
    final count = await SyncQueueService().getQueueCount();
    if (mounted) {
      setState(() => _pendingCount = count);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: NetworkService().isOnline,
      builder: (context, online, _) {
        // Show nothing if online and no pending actions
        if (online && _pendingCount == 0) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          color: online ? Colors.blue[700] : Colors.orange[700],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                online ? Icons.cloud_done : Icons.cloud_off,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  online
                      ? (_pendingCount > 0
                          ? 'Đang đồng bộ $_pendingCount thao tác...'
                          : 'Đã kết nối')
                      : 'Chế độ offline - Dữ liệu sẽ đồng bộ khi có mạng',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_pendingCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$_pendingCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
