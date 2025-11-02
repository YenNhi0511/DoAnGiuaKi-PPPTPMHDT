// lib/screens/activity_form.dart - ĐÃ CẢI THIỆN
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../providers/activity_provider.dart';
import '../theme/app_theme.dart';

class ActivityFormScreen extends StatefulWidget {
  final Activity? activity;

  const ActivityFormScreen({Key? key, this.activity}) : super(key: key);

  @override
  _ActivityFormScreenState createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxParticipantsController;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  DateTime? _selectedRegistrationDeadline;

  bool _isLoading = false;
  bool _isEditMode = false;

  // ✅ THÊM: Track nếu form đã thay đổi
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.activity != null;

    _nameController =
        TextEditingController(text: _isEditMode ? widget.activity!.name : '');
    _descriptionController = TextEditingController(
        text: _isEditMode ? widget.activity!.description : '');
    _locationController = TextEditingController(
        text: _isEditMode ? widget.activity!.location : '');
    _maxParticipantsController = TextEditingController(
        text: _isEditMode && widget.activity!.maxParticipants > 0
            ? widget.activity!.maxParticipants.toString()
            : '0');

    if (_isEditMode) {
      _selectedStartDate = widget.activity!.startDate;
      _selectedEndDate = widget.activity!.endDate;
      _selectedRegistrationDeadline = widget.activity!.registrationDeadline;
    }

    // ✅ THÊM: Listen to changes
    _nameController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _locationController.addListener(_onFormChanged);
    _maxParticipantsController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(BuildContext context,
      {required DateTime initialDate, bool pickTime = false}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      // ✅ THÊM: Theme
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return null;
    if (!pickTime) return pickedDate;
    if (!context.mounted) return pickedDate;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      // ✅ THÊM: Theme
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return pickedDate;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  // ✅ CẢI THIỆN: Validation logic rõ ràng hơn
  String? _validateDates() {
    if (_selectedStartDate == null ||
        _selectedEndDate == null ||
        _selectedRegistrationDeadline == null) {
      return 'Vui lòng chọn đủ các ngày';
    }

    if (_selectedEndDate!.isBefore(_selectedStartDate!)) {
      return 'Ngày kết thúc phải sau Ngày bắt đầu';
    }

    if (_selectedRegistrationDeadline!.isAfter(_selectedStartDate!)) {
      return 'Hạn chót đăng ký phải trước Ngày bắt đầu';
    }

    // ✅ THÊM: Kiểm tra thời gian hợp lý
    final duration = _selectedEndDate!.difference(_selectedStartDate!);
    if (duration.inMinutes < 30) {
      return 'Hoạt động phải kéo dài ít nhất 30 phút';
    }

    return null;
  }

  Future<void> _submitForm() async {
    // ✅ THÊM: Dismiss keyboard
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      // ✅ THÊM: Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // ✅ CẢI THIỆN: Validate dates
    final dateError = _validateDates();
    if (dateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateError),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    // ✅ THÊM: Confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isEditMode ? 'Xác nhận cập nhật' : 'Xác nhận tạo mới'),
        content: Text(
          _isEditMode
              ? 'Bạn có chắc muốn cập nhật hoạt động "${_nameController.text}"?'
              : 'Bạn có chắc muốn tạo hoạt động "${_nameController.text}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isEditMode ? 'Cập nhật' : 'Tạo mới'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    final Map<String, dynamic> data = {
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'location': _locationController.text.trim(),
      'maxParticipants': int.tryParse(_maxParticipantsController.text) ?? 0,
      'startDate': _selectedStartDate!.toIso8601String(),
      'endDate': _selectedEndDate!.toIso8601String(),
      'registrationDeadline': _selectedRegistrationDeadline!.toIso8601String(),
    };

    try {
      final provider = Provider.of<ActivityProvider>(context, listen: false);
      if (_isEditMode) {
        await provider.updateActivity(widget.activity!.id, data);
      } else {
        await provider.createActivity(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isEditMode ? 'Cập nhật thành công' : 'Tạo mới thành công'),
            backgroundColor: AppTheme.secondaryColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDateTime(DateTime? dt, {bool showTime = false}) {
    if (dt == null) return 'Chưa chọn';
    final format =
        showTime ? DateFormat('dd/MM/yyyy HH:mm') : DateFormat('dd/MM/yyyy');
    return format.format(dt);
  }

  // ✅ THÊM: Handle back button
  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát?'),
        content:
            const Text('Bạn có các thay đổi chưa lưu. Bạn có chắc muốn thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Thoát',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // ✅ THÊM
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Sửa Hoạt động' : 'Tạo Hoạt động Mới'),
          elevation: 0,
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isEditMode ? 'Đang cập nhật...' : 'Đang tạo mới...',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ✅ THÊM: Info card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppTheme.primaryColor),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Điền đầy đủ thông tin để tạo hoạt động mới',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên Hoạt động *',
                            hintText: 'VD: Hội thảo công nghệ AI',
                            prefixIcon: Icon(Icons.event),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập tên hoạt động';
                            }
                            if (value.trim().length < 5) {
                              return 'Tên phải có ít nhất 5 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Mô tả *',
                            hintText: 'Mô tả chi tiết về hoạt động',
                            prefixIcon: Icon(Icons.description),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                          maxLength: 500, // ✅ THÊM
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập mô tả';
                            }
                            if (value.trim().length < 20) {
                              return 'Mô tả phải có ít nhất 20 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _locationController,
                          decoration: const InputDecoration(
                            labelText: 'Địa điểm *',
                            hintText: 'VD: Phòng A101',
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Vui lòng nhập địa điểm';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _maxParticipantsController,
                          decoration: const InputDecoration(
                            labelText: 'Số lượng tối đa',
                            hintText: '0 = không giới hạn',
                            prefixIcon: Icon(Icons.people),
                            helperText: 'Nhập 0 nếu không giới hạn số lượng',
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nhập 0 nếu không giới hạn';
                            }
                            final num = int.tryParse(value);
                            if (num == null || num < 0) {
                              return 'Vui lòng nhập số hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Thời gian',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 16),

                        _buildDateTimePicker(
                          context: context,
                          label: 'Ngày bắt đầu *',
                          selectedDate: _selectedStartDate,
                          pickTime: true,
                          icon: Icons.event_available,
                          onDateSelected: (picked) {
                            setState(() {
                              _selectedStartDate = picked;
                              _hasUnsavedChanges = true;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDateTimePicker(
                          context: context,
                          label: 'Ngày kết thúc *',
                          selectedDate: _selectedEndDate,
                          pickTime: true,
                          icon: Icons.event_busy,
                          onDateSelected: (picked) {
                            setState(() {
                              _selectedEndDate = picked;
                              _hasUnsavedChanges = true;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        _buildDateTimePicker(
                          context: context,
                          label: 'Hạn chót đăng ký *',
                          selectedDate: _selectedRegistrationDeadline,
                          pickTime: true,
                          icon: Icons.timer_off,
                          onDateSelected: (picked) {
                            setState(() {
                              _selectedRegistrationDeadline = picked;
                              _hasUnsavedChanges = true;
                            });
                          },
                        ),

                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _isEditMode ? 'CẬP NHẬT' : 'TẠO MỚI',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildDateTimePicker({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required bool pickTime,
    required IconData icon,
    required ValueChanged<DateTime?> onDateSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedDate == null
              ? AppTheme.errorColor.withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _formatDateTime(selectedDate, showTime: pickTime),
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedDate == null
                        ? AppTheme.textSecondary
                        : AppTheme.textPrimary,
                    fontWeight: selectedDate == null
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final picked = await _pickDateTime(
                    context,
                    initialDate: selectedDate ?? DateTime.now(),
                    pickTime: pickTime,
                  );
                  onDateSelected(picked);
                },
                icon: Icon(selectedDate == null ? Icons.add : Icons.edit,
                    size: 18),
                label: Text(selectedDate == null ? 'CHỌN' : 'SỬA'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
