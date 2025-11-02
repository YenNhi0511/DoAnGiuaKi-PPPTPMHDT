// lib/screens/activity_list_screen.dart - ĐÃ CẢI THIỆN
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';
import 'activity_detail_screen.dart';

class ActivityListScreen extends StatefulWidget {
  const ActivityListScreen({Key? key}) : super(key: key);

  @override
  State<ActivityListScreen> createState() => _ActivityListScreenState();
}

class _ActivityListScreenState extends State<ActivityListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // ✅ THÊM: Filter state
  String _filterStatus = 'all'; // all, upcoming, ongoing, past

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActivities();
    });
  }

  // ✅ THÊM: Load with error handling
  Future<void> _loadActivities() async {
    final provider = Provider.of<ActivityProvider>(context, listen: false);
    try {
      await provider.fetchActivities();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _loadActivities,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }

  String _formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date.toLocal());
  }

  // ✅ THÊM: Filter logic
  List<dynamic> _filterActivities(List<dynamic> activities) {
    final now = DateTime.now();

    switch (_filterStatus) {
      case 'upcoming':
        return activities.where((a) => now.isBefore(a.startDate)).toList();
      case 'ongoing':
        return activities
            .where((a) => now.isAfter(a.startDate) && now.isBefore(a.endDate))
            .toList();
      case 'past':
        return activities.where((a) => now.isAfter(a.endDate)).toList();
      default:
        return activities;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            _buildFilterChips(), // ✅ THÊM
            Expanded(
              child: Consumer<ActivityProvider>(
                builder: (context, provider, child) {
                  // ✅ CẢI THIỆN: Loading state
                  if (provider.isLoadingActivities) {
                    return _buildLoadingState();
                  }

                  // ✅ CẢI THIỆN: Error state with retry
                  if (provider.activitiesError != null) {
                    return _buildErrorState(
                      provider.activitiesError!,
                      onRetry: _loadActivities,
                    );
                  }

                  // ✅ THÊM: Filter activities
                  final filteredActivities =
                      _filterActivities(provider.activities);

                  // ✅ CẢI THIỆN: Empty state
                  if (filteredActivities.isEmpty) {
                    return _buildEmptyState();
                  }

                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: RefreshIndicator(
                        onRefresh: _loadActivities, // ✅ SỬA: Dùng method mới
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          physics:
                              const AlwaysScrollableScrollPhysics(), // ✅ THÊM
                          itemCount: filteredActivities.length,
                          itemBuilder: (context, index) {
                            final activity = filteredActivities[index];
                            return _buildActivityCard(context, activity, index);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ THÊM: Filter chips
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Tất cả', 'all', Icons.list),
            const SizedBox(width: 8),
            _buildFilterChip('Sắp diễn ra', 'upcoming', Icons.upcoming),
            const SizedBox(width: 8),
            _buildFilterChip('Đang diễn ra', 'ongoing', Icons.play_circle),
            const SizedBox(width: 8),
            _buildFilterChip('Đã kết thúc', 'past', Icons.history),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = value;
        });
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Danh sách Hoạt động',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CẢI THIỆN: Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Đang tải hoạt động...',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, activity, int index) {
    final now = DateTime.now();
    final isUpcoming = now.isBefore(activity.startDate);
    final isOngoing =
        now.isAfter(activity.startDate) && now.isBefore(activity.endDate);
    final isPast = now.isAfter(activity.endDate);

    Color statusColor = isPast
        ? Colors.grey
        : (isOngoing ? AppTheme.secondaryColor : AppTheme.primaryColor);

    String statusText =
        isPast ? 'Đã kết thúc' : (isOngoing ? 'Đang diễn ra' : 'Sắp diễn ra');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 100)),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ActivityDetailScreen(activity: activity),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          activity.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on_outlined,
                    activity.location,
                    AppTheme.accentColor,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    '${_formatDate(activity.startDate)} • ${_formatTime(activity.startDate)}',
                    AppTheme.primaryColor,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.timer_outlined,
                    'Hạn ĐK: ${_formatDate(activity.registrationDeadline)}',
                    AppTheme.secondaryColor,
                  ),
                  if (activity.isRegistered) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.successGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Đã đăng ký',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // ✅ CẢI THIỆN: Empty state
  Widget _buildEmptyState() {
    String message = 'Chưa có hoạt động nào';
    IconData icon = Icons.event_busy;

    if (_filterStatus == 'upcoming') {
      message = 'Không có hoạt động sắp diễn ra';
      icon = Icons.upcoming;
    } else if (_filterStatus == 'ongoing') {
      message = 'Không có hoạt động đang diễn ra';
      icon = Icons.play_circle_outline;
    } else if (_filterStatus == 'past') {
      message = 'Không có hoạt động đã kết thúc';
      icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vui lòng quay lại sau',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ CẢI THIỆN: Error state with retry
  Widget _buildErrorState(String error, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: 16),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
