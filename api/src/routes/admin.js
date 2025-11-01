// api/src/routes/admin.js

import express from 'express';
import jwt from 'jsonwebtoken';
const router = express.Router();

// Import middleware (phải dùng .js)
import auth from '../middlewares/auth.js';

// Import các Models (dùng import)
import Activity from '../models/Activity.js';
import Registration from '../models/Registration.js';
import User from '../models/User.js';

/**
 * =================================================================
 * Middleware kiểm tra quyền Admin
 * =================================================================
 */
const adminMiddleware = (req, res, next) => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      return res.status(403).json({ msg: 'Truy cập bị từ chối. Yêu cầu quyền Admin.' });
    }
    next();
  } catch (err) {
    // Trả về JSON khi lỗi
    res.status(401).json({ msg: 'Token không hợp lệ hoặc đã xảy ra lỗi quyền' });
  }
};

/**
 * =================================================================
 * API CHO ADMIN (CRUD HOẠT ĐỘNG, TẠO QR, XEM SV)
 * =================================================================
 */

// @route   POST api/admin/activities
// @desc    Admin tạo hoạt động mới
// @access  Private (Admin)
router.post(
  '/activities',
  [auth, adminMiddleware],
  async (req, res) => {
    const { title, description, location, date } = req.body;
    
    try {
      const newActivity = new Activity({
        title,
        description,
        location,
        date, // Dữ liệu date từ form Flutter đã là ISO string
      });
      const activity = await newActivity.save();
      res.status(201).json(activity);
    } catch (err) {
      console.error('Lỗi POST /admin/activities:', err.message);
      // Trả về JSON khi lỗi
      res.status(500).json({ msg: 'Server Error - Không thể tạo hoạt động' });
    }
  }
);

// @route   GET api/admin/activities
// @desc    Admin LẤY TẤT CẢ hoạt động
// @access  Private (Admin)
router.get(
  '/activities',
  [auth, adminMiddleware],
  async (req, res) => {
    try {
      const activities = await Activity.find().sort({ createdAt: -1 }); // Sắp xếp mới nhất
      res.json(activities);
    } catch (err) {
      console.error('Lỗi GET /admin/activities:', err.message);
      res.status(500).json({ msg: 'Server Error - Không thể tải hoạt động' });
    }
  }
);


// @route   PUT api/admin/activities/:id
// @desc    Admin cập nhật (sửa) hoạt động
// @access  Private (Admin)
router.put(
  '/activities/:id',
  [auth, adminMiddleware],
  async (req, res) => {
    try {
      let activity = await Activity.findById(req.params.id);
      if (!activity) {
        return res.status(404).json({ msg: 'Hoạt động không tìm thấy' });
      }
      
      activity = await Activity.findByIdAndUpdate(
        req.params.id,
        { $set: req.body }, // Lấy dữ liệu mới từ body
        { new: true } // Trả về bản ghi đã cập nhật
      );
      res.json(activity);
    } catch (err) {
      console.error('Lỗi PUT /admin/activities/:id:', err.message);
      res.status(500).json({ msg: 'Server Error - Không thể cập nhật' });
    }
  }
);

// @route   DELETE api/admin/activities/:id
// @desc    Admin xóa hoạt động
// @access  Private (Admin)
router.delete(
  '/activities/:id',
  [auth, adminMiddleware],
  async (req, res) => {
    try {
      const activity = await Activity.findById(req.params.id);
      if (!activity) {
        return res.status(404).json({ msg: 'Hoạt động không tìm thấy' });
      }
      
      // Xóa các lượt đăng ký liên quan
      await Registration.deleteMany({ activity: req.params.id });
      
      // Xóa hoạt động
      await Activity.findByIdAndDelete(req.params.id);
      
      res.json({ msg: 'Hoạt động đã được xóa' });
    } catch (err) {
      console.error('Lỗi DELETE /admin/activities/:id:', err.message);
      res.status(500).json({ msg: 'Server Error - Không thể xóa' });
    }
  }
);

// @route   POST api/admin/activities/:id/generate-qr
// @desc    Admin tạo token điểm danh
// @access  Private (Admin)
router.post(
  '/activities/:id/generate-qr',
  [auth, adminMiddleware],
  async (req, res) => {
    try {
      const activity = await Activity.findById(req.params.id);
      if (!activity) {
        return res.status(404).json({ msg: 'Hoạt động không tìm thấy' });
      }

      const attendanceToken = jwt.sign(
        { activityId: activity._id },
        process.env.JWT_SECRET, 
        { expiresIn: '5m' } 
      );

      res.json({ attendanceToken });
      
    } catch (err) {
      console.error('Lỗi POST /admin/.../generate-qr:', err.message);
      res.status(500).json({ msg: 'Server Error' });
    }
  }
);

// @route   GET api/admin/activities/:id/registrations
// @desc    Admin xem danh sách SV đã đăng ký
// @access  Private (Admin)
router.get(
  '/activities/:id/registrations',
  [auth, adminMiddleware],
  async (req, res) => {
    try {
      const registrations = await Registration.find({ activity: req.params.id })
        .populate('student', 'fullName email') 
        .select('-activity');
        
      res.json(registrations);
    } catch (err) {
      console.error('Lỗi GET /admin/.../registrations:', err.message);
      res.status(500).json({ msg: 'Server Error' });
    }
  }
);

// ====== ROUTE MỚI: BÁO CÁO TỔNG HỢP ======
/**
 * @route   GET /api/admin/report
 * @desc    Lấy báo cáo tổng hợp tất cả sinh viên đã tham gia hoạt động
 * @access  Private (Admin)
 */
router.get('/report', [auth, adminMiddleware], async (req, res) => {
  try {
    // Lấy tất cả registrations đã điểm danh
    const registrations = await Registration.find({ attended: true })
      .populate('student', 'fullName email studentId')
      .populate('activity', 'name')
      .sort({ createdAt: -1 });

    // Format dữ liệu
    const report = registrations.map(reg => {
      if (!reg.student || !reg.activity) return null;
      
      return {
        studentId: reg.student.studentId || 'N/A',
        fullName: reg.student.fullName,
        email: reg.student.email,
        activityName: reg.activity.name,
      };
    }).filter(Boolean);

    res.json(report);
  } catch (err) {
    console.error('Lỗi GET /admin/report:', err.message);
    res.status(500).json({ msg: 'Lỗi máy chủ khi tạo báo cáo' });
  }
});

/**
 * @route   GET /api/admin/statistics
 * @desc    Lấy thống kê tổng quan cho trang admin
 * @access  Private (Admin)
 */
router.get('/statistics', [auth, adminMiddleware], async (req, res) => {
  try {
    const totalActivities = await Activity.countDocuments();
    const totalStudents = await User.countDocuments({ role: 'student' });
    const totalRegistrations = await Registration.countDocuments();
    const attendedCount = await Registration.countDocuments({ attended: true });

    res.json({
      totalActivities,
      totalStudents,
      totalRegistrations,
      attendedCount,
      notAttendedCount: totalRegistrations - attendedCount,
    });
  } catch (err) {
    console.error('Lỗi GET /admin/statistics:', err.message);
    res.status(500).json({ msg: 'Lỗi máy chủ khi lấy thống kê' });
  }
});
export default router;