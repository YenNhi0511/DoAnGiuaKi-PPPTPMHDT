// lib/screens/admin_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';

class AdminReportScreen extends StatefulWidget {
  const AdminReportScreen({Key? key}) : super(key: key);

  @override
  State<AdminReportScreen> createState() => _AdminReportScreenState();
}

class _AdminReportScreenState extends State<AdminReportScreen> {
  bool _isLoading = false;
  List<ReportRecord> _records = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = ApiClient();
      // Gọi API mới để lấy báo cáo tổng hợp
      final data = await apiClient.get('admin/report');

      setState(() {
        _records =
            (data as List).map((json) => ReportRecord.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
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
              const SizedBox(width: 6),
              const Text(
                'Báo cáo tổng hợp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Danh sách sinh viên đã tham gia hoạt động',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildError();
    }

    if (_records.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thống kê tổng quan
            _buildSummaryCard(),
            const SizedBox(height: 16),

            // Bảng dữ liệu
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text('STT',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('MSSV',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Họ và tên',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Email',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text('Hoạt động',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Rows
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _records.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text('${index + 1}'),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(record.studentId,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(record.fullName,
                                  style: const TextStyle(fontSize: 13)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(record.email,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(record.activityName,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalStudents = _records.map((r) => r.studentId).toSet().length;
    final totalActivities = _records.map((r) => r.activityName).toSet().length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.people, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  totalStudents.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Sinh viên',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.white30),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.event, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  totalActivities.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Hoạt động',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 60, color: Colors.white30),
          Expanded(
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 32),
                const SizedBox(height: 8),
                Text(
                  _records.length.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Lượt tham gia',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_chart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu báo cáo',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'Đã xảy ra lỗi'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReport,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}

class ReportRecord {
  final String studentId;
  final String fullName;
  final String email;
  final String activityName;

  ReportRecord({
    required this.studentId,
    required this.fullName,
    required this.email,
    required this.activityName,
  });

  factory ReportRecord.fromJson(Map<String, dynamic> json) {
    return ReportRecord(
      studentId: json['studentId'] ?? 'N/A',
      fullName: json['fullName'] ?? 'N/A',
      email: json['email'] ?? 'N/A',
      activityName: json['activityName'] ?? 'N/A',
    );
  }
}
