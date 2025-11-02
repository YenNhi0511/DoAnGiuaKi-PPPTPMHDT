// lib/screens/admin_home.dart - ĐÃ SỬA
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../providers/activity_provider.dart';
import '../models/activity.dart';
import 'setting_screen.dart';
import 'admin_manage_activities.dart';
import 'attendance_activity_list_screen.dart';
import 'admin_report_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  Activity? _selectedActivity;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityProvider>(context, listen: false)
          .fetchActivitiesAdmin();
    });
  }

  List<Activity> _getUpcomingActivities(List<Activity> activities) {
    final now = DateTime.now();
    return activities.where((a) => a.startDate.isAfter(now)).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  int _getTotalParticipants(List<Activity> activities) {
    return activities.fold(
        0, (sum, activity) => sum + activity.participantCount);
  }

  // ✅ SỬA: Tính số người chờ điểm danh (đã đăng ký nhưng chưa điểm danh)
  int _getWaitingAttendance(Activity? activity) {
    if (activity == null) return 0;
    final now = DateTime.now();

    // Chỉ tính nếu hoạt động đang diễn ra
    if (now.isAfter(activity.startDate) && now.isBefore(activity.endDate)) {
      // participantCount = tổng số đã đăng ký
      // Cần lấy số người đã điểm danh từ API (tạm thời trả về participantCount)
      // TODO: Gọi API để lấy số người đã điểm danh thực tế
      return activity.participantCount;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Consumer<ActivityProvider>(
        builder: (context, provider, child) {
          final upcomingActivities =
              _getUpcomingActivities(provider.activities);
          final totalActivities = provider.activities.length;

          // ✅ SỬA: Tính số liệu dựa trên hoạt động được chọn
          final displayParticipants = _selectedActivity != null
              ? _selectedActivity!.participantCount
              : _getTotalParticipants(provider.activities);
          final waitingCount = _getWaitingAttendance(_selectedActivity);

          return Column(
            children: [
              // HEADER GRADIENT
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                    top: 48, left: 20, right: 20, bottom: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // top bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trang quản trị',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingScreen()),
                            );
                          },
                          icon: const Icon(Icons.settings, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user != null
                          ? 'Xin chào, ${user.fullName ?? 'Quản trị viên'} 👋'
                          : 'Xin chào Admin 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Số liệu thống kê
                    Row(
                      children: [
                        Expanded(
                          child: _AdminStatCard(
                            title: 'Hoạt động',
                            value: totalActivities.toString(),
                            icon: Icons.event_note,
                            color: Colors.white.withOpacity(0.12),
                            subtitle:
                                _selectedActivity != null ? 'Đã chọn' : null,
                            onTap: () {
                              _showActivitySelector(
                                  context, upcomingActivities);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AdminStatCard(
                            title: 'SV tham gia',
                            value: displayParticipants.toString(),
                            icon: Icons.group,
                            color: Colors.white.withOpacity(0.12),
                            subtitle: _selectedActivity != null
                                ? _selectedActivity!.name.length > 10
                                    ? '${_selectedActivity!.name.substring(0, 10)}...'
                                    : _selectedActivity!.name
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AdminStatCard(
                            title: 'Chờ điểm danh',
                            value: waitingCount.toString(),
                            icon: Icons.qr_code_scanner,
                            color: Colors.white.withOpacity(0.12),
                            subtitle: _selectedActivity != null
                                ? 'Đang diễn ra'
                                : null,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),

              // BODY
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chức năng nhanh',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Grid chức năng
                      GridView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.35,
                        ),
                        children: [
                          _AdminFuncCard(
                            icon: Icons.event_available_outlined,
                            title: 'Quản lý hoạt động',
                            subtitle: 'Thêm / sửa / xóa',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AdminManageActivitiesScreen()),
                              );
                            },
                          ),
                          _AdminFuncCard(
                            icon: Icons.qr_code_2_outlined,
                            title: 'Điểm danh',
                            subtitle: 'Chọn hoạt động',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const AttendanceActivityListScreen()),
                              );
                            },
                          ),
                          _AdminFuncCard(
                            icon: Icons.insert_chart_outlined,
                            title: 'Báo cáo',
                            subtitle: 'Tổng hợp tham gia',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const AdminReportScreen()),
                              );
                            },
                          ),
                          _AdminFuncCard(
                            icon: Icons.settings_outlined,
                            title: 'Cài đặt',
                            subtitle: 'Tài khoản, theme',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SettingScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      _AdminFuncCard(
                        icon: Icons.class_outlined,
                        title: 'Quản lý Lớp',
                        subtitle: 'Danh sách lớp học',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const AdminClassManagementScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 24),
                      const Text(
                        'Hoạt động sắp diễn ra',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Hiển thị hoạt động sắp diễn ra
                      if (provider.isLoadingActivities)
                        const Center(child: CircularProgressIndicator())
                      else if (upcomingActivities.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'Không có hoạt động sắp diễn ra',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...upcomingActivities.take(3).map((activity) {
                          return _UpcomingItem(
                            title: activity.name,
                            time: DateFormat('HH:mm • dd/MM/yyyy')
                                .format(activity.startDate.toLocal()),
                            place: activity.location,
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showActivitySelector(BuildContext context, List<Activity> activities) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Chọn hoạt động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_selectedActivity != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedActivity = null;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Xóa chọn'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: Text('Không có hoạt động sắp diễn ra'),
                  ),
                )
              else
                ...activities.map((activity) {
                  return ListTile(
                    title: Text(activity.name),
                    subtitle: Text(DateFormat('dd/MM/yyyy HH:mm')
                        .format(activity.startDate.toLocal())),
                    trailing: Radio<Activity>(
                      value: activity,
                      groupValue: _selectedActivity,
                      onChanged: (value) {
                        setState(() {
                          _selectedActivity = value;
                        });
                        Navigator.pop(context);
                      },
                    ),
                    onTap: () {
                      setState(() {
                        _selectedActivity = activity;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final String? subtitle;

  const _AdminStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(color: Colors.white60, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }
}

class _AdminFuncCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _AdminFuncCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF4F46E5)),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpcomingItem extends StatelessWidget {
  final String title;
  final String time;
  final String place;

  const _UpcomingItem({
    required this.title,
    required this.time,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event, color: Color(0xFF4F46E5)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF111827),
                    )),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(time,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(place,
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
