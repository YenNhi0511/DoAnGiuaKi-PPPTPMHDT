// lib/screens/activity_detail_screen.dart - ĐÃ SỬA
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../services/auth_service.dart';
import 'qr_scanner_screen.dart'; // ✅ THÊM IMPORT

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
        return AlertDialog(
          title: Text('QR Điểm danh: $activityName'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: QrImageView(
              data: activityId,
              version: QrVersions.auto,
              size: 300.0,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
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
            backgroundColor: Colors.red,
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
          appBar: AppBar(
            title: Text(isFromHistory ? 'Chi tiết Lịch sử' : liveActivity.name),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  liveActivity.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  text:
                      'Thời gian: ${_formatDateRange(liveActivity.startDate, liveActivity.endDate)}',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.timer_off_outlined,
                  text:
                      'Hạn chót ĐK: ${DateFormat('dd/MM/yyyy HH:mm').format(liveActivity.registrationDeadline.toLocal())}',
                ),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: 'Địa điểm: ${liveActivity.location}',
                ),
                if (userRole == 'admin' ||
                    liveActivity.maxParticipants > 0) ...[
                  const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.people_outline,
                    text:
                        'Số lượng: ${liveActivity.participantCount} / ${liveActivity.maxParticipants > 0 ? liveActivity.maxParticipants : 'Không giới hạn'}',
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Mô tả hoạt động:',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      liveActivity.description,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // HÀNH ĐỘNG
                if (userRole == 'admin')
                  _buildAdminActions(context, liveActivity)
                else if (userRole == 'student')
                  _buildStudentActions(
                      context, liveActivity, provider, isFromHistory)
                else
                  Container(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAdminActions(BuildContext context, Activity activity) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.qr_code_2_sharp),
        label: const Text(
          'HIỆN QR ĐIỂM DANH',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          _showQrDialog(context, activity.id, activity.name);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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

    // ✅ LOGIC 1: XEM TỪ LỊCH SỬ
    if (isFromHistory) {
      if (activity.attended) {
        return _buildStatusChip(
          text: 'TRẠNG THÁI: ĐÃ ĐIỂM DANH',
          color: Colors.green,
        );
      } else if (isActivityFinished) {
        return _buildStatusChip(
          text: 'TRẠNG THÁI: CHƯA ĐIỂM DANH (ĐÃ KẾT THÚC)',
          color: Colors.grey.shade600,
        );
      } else {
        // ✅ THÊM: Nút quét QR nếu đã đăng ký nhưng chưa điểm danh
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusChip(
              text: 'TRẠNG THÁI: CHƯA ĐIỂM DANH',
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const QrScannerScreen()),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('QUÉT QR ĐIỂM DANH',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      }
    }

    // ✅ LOGIC 2: XEM TỪ DANH SÁCH CHÍNH
    final bool showUnregisterButton = activity.isRegistered;
    final String buttonText = showUnregisterButton ? 'HỦY ĐĂNG KÝ' : 'ĐĂNG KÝ';
    final Color buttonColor =
        showUnregisterButton ? Colors.red.shade600 : Colors.green.shade600;

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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: isDisabled
              ? null
              : () => _handleToggleRegistration(context, provider, activity),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
              : Text(buttonText,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDisabled ? Colors.grey.shade500 : buttonColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            disabledBackgroundColor: Colors.grey.shade500,
            disabledForegroundColor: Colors.white70,
          ),
        ),
        if (isDisabled && disabledReason != null && !isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(disabledReason,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700)),
          ),

        // ✅ THÊM: Nút quét QR nếu đã đăng ký
        if (activity.isRegistered && !isActivityFinished) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const QrScannerScreen()),
              );
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('QUÉT QR ĐIỂM DANH',
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip({required String text, required Color color}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration:
          BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({Key? key, required this.icon, required this.text})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2.0),
          child: Icon(icon, color: Colors.grey.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(text, style: Theme.of(context).textTheme.titleMedium)),
      ],
    );
  }
}
