// lib/screens/activity_detail_screen.dart - ĐÃ THIẾT KẾ LẠI
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'qr_scanner_screen.dart';

class ActivityDetailScreen extends StatelessWidget {
  final Activity activity;
  final bool isFromHistory;

  const ActivityDetailScreen({
    Key? key,
    required this.activity,
    this.isFromHistory = false,
  }) : super(key: key);

  void _showQrDialog(
      BuildContext context, String activityId, String activityName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'QR Điểm danh',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activityName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: QrImageView(
                    data: activityId,
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Đóng',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleToggleRegistration(BuildContext context,
      ActivityProvider provider, Activity activity) async {
    try {
      await provider.toggleRegistration(activity);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final DateFormat dayFormat = DateFormat('dd/MM/yyyy');
    final DateFormat timeFormat = DateFormat('HH:mm');
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${dayFormat.format(start.toLocal())} (${timeFormat.format(start.toLocal())} - ${timeFormat.format(end.toLocal())})';
    } else {
      return '${dayFormat.format(start.toLocal())} ${timeFormat.format(start.toLocal())} - ${dayFormat.format(end.toLocal())} ${timeFormat.format(end.toLocal())}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole =
        Provider.of<AuthService>(context, listen: false).currentUser?.role;

    return Consumer<ActivityProvider>(
      builder: (context, provider, child) {
        final List<Activity> sourceList =
            isFromHistory ? provider.history : provider.activities;
        final liveActivity = sourceList.firstWhere(
          (a) => a.id == activity.id,
          orElse: () => activity,
        );

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: Column(
            children: [
              _buildHeader(context, liveActivity),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(context, liveActivity, userRole),
                      _buildDescriptionCard(context, liveActivity),
                      _buildActionSection(
                          context, liveActivity, provider, userRole),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, Activity activity) {
    return Container(
      padding: const EdgeInsets.only(top: 48, left: 16, right: 16, bottom: 24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isFromHistory ? 'Chi tiết Lịch sử' : 'Chi tiết Hoạt động',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            activity.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      BuildContext context, Activity activity, String? userRole) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildInfoRow(
            Icons.calendar_today_outlined,
            'Thời gian',
            _formatDateRange(activity.startDate, activity.endDate),
            AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.timer_off_outlined,
            'Hạn chót ĐK',
            DateFormat('dd/MM/yyyy HH:mm')
                .format(activity.registrationDeadline.toLocal()),
            AppTheme.accentColor,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            Icons.location_on_outlined,
            'Địa điểm',
            activity.location,
            AppTheme.secondaryColor,
          ),
          if (userRole == 'admin' || activity.maxParticipants > 0) ...[
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.people_outline,
              'Số lượng',
              '${activity.participantCount} / ${activity.maxParticipants > 0 ? activity.maxParticipants : 'Không giới hạn'}',
              const Color(0xFFFF7675),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, Activity activity) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mô tả hoạt động',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            activity.description,
            style: const TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, Activity activity,
      ActivityProvider provider, String? userRole) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: userRole == 'admin'
          ? _buildAdminActions(context, activity)
          : _buildStudentActions(context, activity, provider, isFromHistory),
    );
  }

  Widget _buildAdminActions(BuildContext context, Activity activity) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showQrDialog(context, activity.id, activity.name),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.qr_code_2_sharp,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hiện QR Điểm danh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cho sinh viên quét để điểm danh',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentActions(BuildContext context, Activity activity,
      ActivityProvider provider, bool isFromHistory) {
    final now = DateTime.now();
    final bool isRegistrationClosed =
        now.isAfter(activity.registrationDeadline);
    final bool isActivityFinished = now.isAfter(activity.endDate);
    final bool isFull = activity.maxParticipants > 0 &&
        activity.participantCount >= activity.maxParticipants;
    final bool isLoading = provider.isActivityLoading(activity.id);

    // XEM TỪ LỊCH SỬ
    if (isFromHistory) {
      if (activity.attended) {
        return _buildStatusContainer(
          icon: Icons.check_circle,
          text: 'ĐÃ ĐIỂM DANH',
          subtitle: 'Bạn đã hoàn thành hoạt động này',
          gradient: AppTheme.successGradient,
        );
      } else if (isActivityFinished) {
        return _buildStatusContainer(
          icon: Icons.cancel_outlined,
          text: 'CHƯA ĐIỂM DANH',
          subtitle: 'Hoạt động đã kết thúc',
          gradient: const LinearGradient(
            colors: [Color(0xFF636E72), Color(0xFF95A5A6)],
          ),
        );
      } else {
        return Column(
          children: [
            _buildStatusContainer(
              icon: Icons.schedule,
              text: 'CHƯA ĐIỂM DANH',
              subtitle: 'Hãy quét QR để điểm danh',
              gradient: const LinearGradient(
                colors: [Color(0xFFFF7675), Color(0xFFFF6B81)],
              ),
            ),
            const SizedBox(height: 16),
            _buildQrScanButton(context),
          ],
        );
      }
    }

    // XEM TỪ DANH SÁCH CHÍNH
    final bool showUnregisterButton = activity.isRegistered;
    final String buttonText = showUnregisterButton ? 'HỦY ĐĂNG KÝ' : 'ĐĂNG KÝ';

    bool isDisabled = isLoading;
    String? disabledReason;

    if (!showUnregisterButton) {
      if (isRegistrationClosed) {
        isDisabled = true;
        disabledReason = 'Đã quá hạn đăng ký';
      } else if (isFull) {
        isDisabled = true;
        disabledReason = 'Đã đủ số lượng';
      }
    } else {
      if (isRegistrationClosed) {
        isDisabled = true;
        disabledReason = 'Đã quá hạn hủy đăng ký';
      }
    }
    if (isActivityFinished) {
      isDisabled = true;
      disabledReason = 'Hoạt động đã kết thúc';
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? null
                : (showUnregisterButton
                    ? const LinearGradient(
                        colors: [Color(0xFFD63031), Color(0xFFFF7675)])
                    : AppTheme.successGradient),
            color: isDisabled ? Colors.grey.shade400 : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: (showUnregisterButton
                              ? const Color(0xFFD63031)
                              : AppTheme.secondaryColor)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled
                  ? null
                  : () =>
                      _handleToggleRegistration(context, provider, activity),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          buttonText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDisabled ? Colors.white70 : Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        if (isDisabled && disabledReason != null && !isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: AppTheme.errorColor),
                const SizedBox(width: 8),
                Text(
                  disabledReason,
                  style: const TextStyle(
                    color: AppTheme.errorColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        if (activity.isRegistered && !isActivityFinished) ...[
          const SizedBox(height: 16),
          _buildQrScanButton(context),
        ],
      ],
    );
  }

  Widget _buildStatusContainer({
    required IconData icon,
    required String text,
    required String subtitle,
    required Gradient gradient,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrScanButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0984E3), Color(0xFF74B9FF)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0984E3).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const QrScannerScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Text(
                  'QUÉT QR ĐIỂM DANH',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
