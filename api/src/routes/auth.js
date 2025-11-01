// api/src/routes/auth.js - THÊM ROUTE CẬP NHẬT THÔNG TIN

import express from 'express';
import User from '../models/User.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import authMiddleware from '../middlewares/auth.js';

const router = express.Router();

/* ------------------ ĐĂNG KÝ (GIỮ NGUYÊN) ------------------ */
router.post('/register', async (req, res) => {
  try {
    const { fullName, email, password } = req.body;
    if (!fullName || !email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập đủ thông tin' });
    }

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(409).json({ message: 'Email này đã được sử dụng' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const newUser = new User({
      fullName,
      email,
      password: hashedPassword,
      role: 'student',
    });
    await newUser.save();

    const token = jwt.sign(
      { userId: newUser._id, role: newUser.role },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(201).json({
      token,
      user: {
        id: newUser._id,
        fullName: newUser.fullName,
        email: newUser.email,
        role: newUser.role,
        studentId: newUser.studentId,
        class: newUser.class,
      },
    });
  } catch (error) {
    console.error('Lỗi đăng ký:', error);
    res.status(500).json({ message: 'Lỗi máy chủ nội bộ' });
  }
});

/* ------------------ ĐĂNG NHẬP (CẬP NHẬT ĐỂ TRẢ THÊM THÔNG TIN) ------------------ */
router.post('/login', async (req, res) => {
  console.log('---------------------------------');
  console.log('ĐÃ NHẬN ĐƯỢC REQUEST LOGIN');

  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu' });
    }

    const user = await User.findOne({ email });
    if (!user) {
      return res.status(401).json({ message: 'Sai email hoặc mật khẩu' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Sai email hoặc mật khẩu' });
    }

    const token = jwt.sign(
      { userId: user._id, role: user.role },
      process.env.JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.status(200).json({
      token,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        studentId: user.studentId,
        class: user.class,
      },
    });
  } catch (error) {
    console.error('LỖI SERVER 500:', error);
    res.status(500).json({ message: 'Lỗi máy chủ nội bộ' });
  }
});

/* ------------------ LẤY THÔNG TIN NGƯỜI DÙNG (CẬP NHẬT) ------------------ */
router.get('/me', authMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.user.userId).select('-password');
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }
    res.status(200).json(user);
  } catch (error) {
    console.error('Lỗi /api/auth/me:', error);
    res.status(500).json({ message: 'Lỗi máy chủ nội bộ' });
  }
});

/* ------------------ ĐỔI MẬT KHẨU (GIỮ NGUYÊN) ------------------ */
router.post('/change-password', authMiddleware, async (req, res) => {
  try {
    const { oldPassword, newPassword, confirmPassword } = req.body;

    if (!oldPassword || !newPassword || !confirmPassword) {
      return res.status(400).json({ message: 'Vui lòng nhập đủ thông tin' });
    }

    if (newPassword !== confirmPassword) {
      return res.status(400).json({ message: 'Mật khẩu xác nhận không khớp' });
    }

    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Mật khẩu cũ không đúng' });
    }

    const salt = await bcrypt.genSalt(10);
    const hashedNewPassword = await bcrypt.hash(newPassword, salt);

    user.password = hashedNewPassword;
    await user.save();

    res.status(200).json({ message: 'Đổi mật khẩu thành công!' });
  } catch (error) {
    console.error('Lỗi đổi mật khẩu:', error);
    res.status(500).json({ message: 'Lỗi máy chủ nội bộ' });
  }
});

/* ================== ROUTE MỚI: CẬP NHẬT THÔNG TIN SINH VIÊN ================== */
router.put('/update-info', authMiddleware, async (req, res) => {
  try {
    const { fullName, studentId, class: studentClass } = req.body;

    // Kiểm tra nếu studentId đã tồn tại (trừ user hiện tại)
    if (studentId) {
      const existing = await User.findOne({
        studentId,
        _id: { $ne: req.user.userId },
      });

      if (existing) {
        return res.status(409).json({ message: 'MSSV này đã được sử dụng' });
      }
    }

    const updateData = {};
    if (fullName) updateData.fullName = fullName;
    if (studentId) updateData.studentId = studentId;
    if (studentClass) updateData.class = studentClass;

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { $set: updateData },
      { new: true, select: '-password' }
    );

    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }

    res.status(200).json({
      message: 'Cập nhật thông tin thành công',
      user,
    });
  } catch (error) {
    console.error('Lỗi cập nhật thông tin:', error);
    res.status(500).json({ message: 'Lỗi máy chủ nội bộ' });
  }
});
/* ============================================================================= */

export default router;