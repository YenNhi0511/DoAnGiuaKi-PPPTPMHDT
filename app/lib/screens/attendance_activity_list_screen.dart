import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/activity_provider.dart';
import 'attendance_detail_screen.dart';

class AttendanceActivityListScreen extends StatefulWidget {
  const AttendanceActivityListScreen({super.key});

  @override
  State<AttendanceActivityListScreen> createState() =>
      _AttendanceActivityListScreenState();
}

class _AttendanceActivityListScreenState
    extends State<AttendanceActivityListScreen> {
  // bộ lọc đơn giản: 0 = tất cả, 1 = hôm nay, 2 = sắp diễn ra
  int _selectedFilter = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ActivityProvider>(context, listen: false)
          .fetchActivitiesAdmin();
    });
  }

  String _formatSimpleDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    final d = date.toLocal();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  bool _isUpcoming(DateTime date) {
    final now = DateTime.now();
    return date.isAfter(now);
  }

  List _applyFilter(List activities) {
    if (_selectedFilter == 0) return activities;
    if (_selectedFilter == 1) {
      return activities.where((a) => _isToday(a.startDate)).toList();
    }
    // 2 = sắp diễn ra
    return activities.where((a) => _isUpcoming(a.startDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Chọn hoạt động để xem điểm danh'),
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

          // list này chắc chắn non-null, nên khỏi check != null
          final filtered =
              _applyFilter(activityProvider.activities); // áp dụng bộ lọc

          if (filtered.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => activityProvider.fetchActivitiesAdmin(),
              child: ListView(
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.event_busy, size: 64, color: Color(0xFF9CA3AF)),
                  SizedBox(height: 12),
                  Center(
                    child: Text(
                      'Không có hoạt động nào.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildFilterBar(context),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => activityProvider.fetchActivitiesAdmin(),
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final activity = filtered[index];
                      final isUpcoming = _isUpcoming(activity.startDate);
                      final isTodayFlag = _isToday(activity.startDate);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  activity.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isTodayFlag)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1D4ED8)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Hôm nay',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF1D4ED8),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else if (isUpcoming)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'Sắp diễn ra',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF047857),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatSimpleDate(activity.startDate),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.place,
                                        size: 14, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        activity.location,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Đã đăng ký: ${activity.participantCount} / ${activity.maxParticipants > 0 ? activity.maxParticipants : 'Không giới hạn'}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: Color(0xFF1D4ED8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              size: 18, color: theme.primaryColor),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AttendanceDetailScreen(
                                  activity: activity,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          _buildFilterChip('Tất cả', 0, Icons.list_alt),
          const SizedBox(width: 8),
          _buildFilterChip('Hôm nay', 1, Icons.today),
          const SizedBox(width: 8),
          _buildFilterChip('Sắp diễn ra', 2, Icons.upcoming),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1D4ED8).withValues(alpha: 0.08)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF1D4ED8) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? const Color(0xFF1D4ED8)
                    : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
