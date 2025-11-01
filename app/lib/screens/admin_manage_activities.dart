// lib/screens/admin_manage_activities.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import 'activity_form.dart';
import 'activity_detail_screen.dart';

class AdminManageActivitiesScreen extends StatefulWidget {
  const AdminManageActivitiesScreen({Key? key}) : super(key: key);

  @override
  State<AdminManageActivitiesScreen> createState() =>
      _AdminManageActivitiesScreenState();
}

// đặt class State công khai luôn, đừng dùng _
class _AdminManageActivitiesScreenState
    extends State<AdminManageActivitiesScreen> {
  @override
  void initState() {
    super.initState();
    // Gọi fetch sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // chỗ này không có await nên KHÔNG bị use_build_context_synchronously
      Provider.of<ActivityProvider>(context, listen: false)
          .fetchActivitiesAdmin();
    });
  }

  // Hàm xử lý xóa
  Future<void> _deleteActivity(String id) async {
    try {
      await Provider.of<ActivityProvider>(context, listen: false)
          .deleteActivity(id);

      // ✨ sau await phải check mounted rồi mới dùng context
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Xóa hoạt động thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Hoạt động'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ActivityFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ActivityProvider>(
        builder: (context, activityProvider, child) {
          if (activityProvider.isLoadingActivities) {
            return const Center(child: CircularProgressIndicator());
          }

          if (activityProvider.activitiesError != null) {
            return Center(
              child: Text('Lỗi: ${activityProvider.activitiesError}'),
            );
          }

          if (activityProvider.activities.isEmpty) {
            return const Center(child: Text('Không có hoạt động nào.'));
          }

          return ListView.builder(
            itemCount: activityProvider.activities.length,
            itemBuilder: (context, index) {
              final activity = activityProvider.activities[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(activity.name),
                  subtitle: Text(activity.location),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nút Sửa
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ActivityFormScreen(activity: activity),
                            ),
                          );
                        },
                      ),
                      // Nút Xóa
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Xác nhận xóa'),
                              content: Text(
                                'Bạn có chắc muốn xóa hoạt động "${activity.name}"?',
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Hủy'),
                                  onPressed: () => Navigator.of(ctx).pop(),
                                ),
                                TextButton(
                                  child: const Text(
                                    'Xóa',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _deleteActivity(activity.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ActivityDetailScreen(activity: activity),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
